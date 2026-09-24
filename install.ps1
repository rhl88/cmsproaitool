<#
.SYNOPSIS
    CMSPRO 规则技能包一键部署脚本（Windows PowerShell 版）。

.NOTES
    编码说明：本文件为 UTF-8 **带 BOM**——Windows PowerShell 5.1 对无 BOM 的 UTF-8 脚本
    会按 ANSI 误读中文字符串导致语法错误，微软官方要求含非 ASCII 字符的 .ps1 必须带 BOM。
    本脚本为部署工具，不参与 Web 输出，不受「UTF-8 无 BOM」Web 资源规范的约束。
    （PowerShell 7+ 对 BOM 与否均兼容。）

.DESCRIPTION
    将规则技能包的各工具入口文件部署到目标项目根目录，实现对 Claude Code、Codex、Cursor、
    Trae、Windsurf、Cline、GitHub Copilot、Gemini CLI、Aider、CodeBuddy、Kiro、Qoder 等
    AI 工具的规则自动加载。

    前提：本规则包整个目录已位于目标项目内（任意子目录位置均可，如 docs/规则技能包/ 或
    cmspro-rules/）。脚本会自动计算规则包相对项目根的路径，并写入各入口文件。

    行为说明：
    - 仅生成入口文件，不改动项目其他内容；
    - 目标位置已存在同名文件时默认跳过，加 -Force 覆盖；
    - 加 -Tools 可仅部署指定工具的入口（当前用什么工具就部署什么工具的入口，
      避免项目里出现一堆无关工具的规则目录）；不传则全量部署；
    - 所有产物以「UTF-8 无 BOM」保存；
    - 包根 AGENTS.md / CLAUDE.md / .cursorrules 部署时会将其中的 `rules/`、`skills/`
      相对路径改写为规则包在项目内的实际路径；adapters/ 模板中的 {{RULES_ROOT}}
      占位符同理替换。

    支持的工具标识（-Tools 取值，逗号分隔，大小写不敏感）：
      codex / claude / cursor / trae / windsurf / cline / github / gemini /
      aider / codebuddy / kiro / qoder
    依赖说明：claude（CLAUDE.md）与 gemini（GEMINI.md）入口通过 @ 导入 AGENTS.md，
      指定其一时会连带部署 AGENTS.md；cursor 同时部署新旧版入口。

.EXAMPLE
    .\install.ps1 -ProjectRoot E:\wwwroot\myproject

    首次部署到指定项目，已存在的入口文件跳过。

.EXAMPLE
    .\install.ps1 -ProjectRoot E:\wwwroot\myproject -Force

    覆盖部署全部入口文件（规则包升级后重新部署用）。

.EXAMPLE
    .\install.ps1 -ProjectRoot E:\wwwroot\myproject -Tools trae

    仅部署 Trae 入口（.trae/rules/cmspro.md）。

.EXAMPLE
    .\install.ps1 -ProjectRoot E:\wwwroot\myproject -Tools claude,cursor

    仅部署 Claude Code 与 Cursor 入口（CLAUDE.md 会连带部署其依赖的 AGENTS.md）。

.NOTES
    若执行策略受限，可用：powershell -ExecutionPolicy Bypass -File .\install.ps1 -ProjectRoot <路径>
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,
    # 可选：仅部署指定工具的入口，逗号分隔或数组传入，如 -Tools trae 或 -Tools trae,cursor
    [string[]]$Tools,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$pkgRoot = $PSScriptRoot

# --- 基础校验 ---
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    throw "目标项目根目录不存在：$ProjectRoot"
}

# 计算规则包相对项目根的路径（统一正斜杠，便于写入 Markdown 引用）
# 说明：不使用 [System.IO.Path]::GetRelativePath——Windows PowerShell 5.1（.NET Framework）无此 API
$projFull = $ProjectRoot.TrimEnd('\')
$pkgFull  = $pkgRoot.TrimEnd('\')
if ($pkgFull.ToLower() -eq $projFull.ToLower()) {
    $rulesRoot = '.'
} elseif ($pkgFull.ToLower().StartsWith($projFull.ToLower() + '\')) {
    $rulesRoot = $pkgFull.Substring($projFull.Length + 1).Replace('\', '/')
} else {
    throw "规则包必须位于目标项目内（当前位于项目外：$pkgRoot）。请先把整个规则包目录复制或克隆到项目内，再执行本脚本。"
}

# --- 工具函数 ---
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$deployed = [System.Collections.Generic.List[string]]::new()
$skipped  = [System.Collections.Generic.List[string]]::new()

# 内容改写：先替换 {{RULES_ROOT}} 占位符，再将包内相对路径 `rules/、`skills/ 前缀化
function Convert-PackageContent {
    param([string]$Raw)
    $c = $Raw.Replace('{{RULES_ROOT}}', $script:rulesRoot)
    $prefix = '`' + $script:rulesRoot + '/'
    $c = $c.Replace('`rules/',  $prefix + 'rules/')
    $c = $c.Replace('`skills/', $prefix + 'skills/')
    return $c
}

# 在首行标题后注入部署说明（仅 AGENTS.md 使用）
function Add-DeployNote {
    param([string]$Raw)
    $nl = if ($Raw -match "`r`n") { "`r`n" } else { "`n" }
    $note = '> **部署说明**：本文件由规则技能包部署脚本生成，规则包位于 `' + $script:rulesRoot +
            '/`；下文所述「本包」即该目录，文内 `rules/`、`skills/` 等相对路径已改写为项目内实际路径。'
    $idx = $Raw.IndexOf("`n")
    if ($idx -lt 0) { return $Raw + $nl + $nl + $note }
    return $Raw.Substring(0, $idx + 1) + $nl + $note + $nl + $Raw.Substring($idx + 1)
}

# 写入单个入口文件（已存在且未指定 -Force 时跳过）
function Write-Entry {
    param([string]$Content, [string]$RelativeTarget, [string]$Label)
    $target = Join-Path $script:ProjectRoot $RelativeTarget
    if ((Test-Path -LiteralPath $target) -and -not $Force) {
        $script:skipped.Add("[$Label] $RelativeTarget（已存在，跳过；-Force 可覆盖）")
        return
    }
    $dir = Split-Path -Parent $target
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($target, $Content, $script:utf8NoBom)
    $script:deployed.Add("[$Label] $RelativeTarget")
}

# 读取包内源文件
function Read-PackageFile {
    param([string]$RelativeSource)
    $src = Join-Path $script:pkgRoot $RelativeSource
    if (-not (Test-Path -LiteralPath $src)) { throw "规则包内缺少源文件：$RelativeSource" }
    return [System.IO.File]::ReadAllText($src)
}

# --- 部署清单 ---
# Tools：该入口归属的工具标识（-Tools 命中其一即部署）
# 依赖说明：AGENTS.md 同时是 claude（CLAUDE.md @导入）与 gemini（GEMINI.md @导入）的依赖入口，
#          故其 Tools 含 codex/claude/gemini；cursor 一个标识同时覆盖新旧版入口。
$entries = @(
    @{ Tools = @('codex','claude','gemini'); Src = 'AGENTS.md';                                Dst = 'AGENTS.md';                         Label = 'Codex/OpenCode/Zed 等'; Note = $true },
    @{ Tools = @('claude');                  Src = 'CLAUDE.md';                                Dst = 'CLAUDE.md';                         Label = 'Claude Code' },
    @{ Tools = @('cursor');                  Src = '.cursorrules';                             Dst = '.cursorrules';                      Label = 'Cursor 旧版' },
    @{ Tools = @('cursor');                  Src = 'adapters/cursor/cmspro.mdc';               Dst = '.cursor/rules/cmspro.mdc';          Label = 'Cursor 新版' },
    @{ Tools = @('trae');                    Src = 'adapters/trae/cmspro.md';                  Dst = '.trae/rules/cmspro.md';             Label = 'Trae' },
    @{ Tools = @('windsurf');                Src = 'adapters/windsurf/cmspro.md';              Dst = '.windsurf/rules/cmspro.md';         Label = 'Windsurf' },
    @{ Tools = @('cline');                   Src = 'adapters/cline/cmspro.md';                 Dst = '.clinerules/cmspro.md';             Label = 'Cline' },
    @{ Tools = @('github');                  Src = 'adapters/github/copilot-instructions.md';  Dst = '.github/copilot-instructions.md';   Label = 'GitHub Copilot' },
    @{ Tools = @('gemini');                  Src = 'adapters/gemini/GEMINI.md';                Dst = 'GEMINI.md';                         Label = 'Gemini CLI' },
    @{ Tools = @('aider');                   Src = 'adapters/aider/CONVENTIONS.md';            Dst = 'CONVENTIONS.md';                    Label = 'Aider' },
    @{ Tools = @('codebuddy');               Src = 'adapters/codebuddy/cmspro.md';             Dst = '.codebuddy/rules/cmspro.md';        Label = 'CodeBuddy' },
    @{ Tools = @('kiro');                    Src = 'adapters/kiro/cmspro.md';                  Dst = '.kiro/steering/cmspro.md';          Label = 'Kiro' },
    @{ Tools = @('qoder');                   Src = 'adapters/qoder/cmspro.md';                 Dst = '.qoder/rules/cmspro.md';            Label = 'Qoder' }
)

# --- 工具标识校验与清单过滤 ---
$validTools = $entries | ForEach-Object { $_.Tools } | Select-Object -Unique
if ($Tools) {
    # 逗号分隔/数组传入统一规整：去空白、转小写
    $Tools = @($Tools | ForEach-Object { $_.Split(',') } | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })
    $invalid = @($Tools | Where-Object { $validTools -notcontains $_ })
    if ($invalid.Count -gt 0) {
        throw "不支持的工具标识：$($invalid -join ', ')。支持：$((($validTools | Sort-Object) -join ', '))"
    }
}
$selected = if ($Tools) {
    @($entries | Where-Object { $owners = $_.Tools; @($owners | Where-Object { $Tools -contains $_ }).Count -gt 0 })
} else {
    $entries
}

# --- 开始部署 ---
Write-Host "== CMSPRO 规则技能包一键部署 ==" -ForegroundColor Cyan
Write-Host "目标项目根：$ProjectRoot"
Write-Host "规则包路径：$rulesRoot"
if ($Tools) {
    Write-Host "部署范围：指定工具（$($Tools -join ', ')）"
} else {
    Write-Host "部署范围：全部工具（如仅需当前工具入口，可加 -Tools <工具标识>）"
}
Write-Host ""

# 逐条部署选中入口
foreach ($e in $selected) {
    $content = Convert-PackageContent (Read-PackageFile $e.Src)
    if ($e.Note) { $content = Add-DeployNote $content }
    Write-Entry -Content $content -RelativeTarget $e.Dst -Label $e.Label
}

# --- 部署结果 ---
Write-Host "-- 已部署 $($deployed.Count) 个入口 --" -ForegroundColor Green
$deployed | ForEach-Object { Write-Host "  $_" }
if ($skipped.Count -gt 0) {
    Write-Host ""
    Write-Host "-- 跳过 $($skipped.Count) 个（已存在）--" -ForegroundColor Yellow
    $skipped | ForEach-Object { Write-Host "  $_" }
}

Write-Host ""
Write-Host "后续建议：" -ForegroundColor Cyan
Write-Host "  1. 将上述入口文件随项目提交，团队成员克隆后各工具即可自动加载规则；"
Write-Host "  2. 需要技能自动触发时（可选）：Claude Code 将 `"$rulesRoot/skills/`" 下各技能目录复制到 .claude/skills/；Trae 复制到 .trae/skills/；"
Write-Host "  3. 规则包升级后，在包目录重新执行本脚本并加 -Force 覆盖部署。"
