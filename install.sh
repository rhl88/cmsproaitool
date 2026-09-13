#!/usr/bin/env bash
#
# CMSPRO 规则技能包一键部署脚本（macOS / Linux / Git Bash 版）
#
# 用法：
#   ./install.sh <目标项目根目录> [--force]
#
# 说明：
#   将规则技能包的各工具入口文件部署到目标项目根目录，实现对 Claude Code、Codex、
#   Cursor、Trae、Windsurf、Cline、GitHub Copilot、Gemini CLI、Aider、CodeBuddy 等
#   AI 工具的规则自动加载。
#
# 前提：
#   本规则包整个目录已位于目标项目内（任意子目录位置均可，如 docs/规则技能包/ 或
#   cmspro-rules/）。脚本会自动计算规则包相对项目根的路径，并写入各入口文件。
#
# 行为：
#   - 仅生成入口文件，不改动项目其他内容；
#   - 目标位置已存在同名文件时默认跳过，加 --force 覆盖；
#   - 包根 AGENTS.md / CLAUDE.md / .cursorrules 部署时将其中 `rules/`、`skills/`
#     相对路径改写为规则包在项目内的实际路径；adapters/ 模板中的 {{RULES_ROOT}}
#     占位符同理替换。

set -euo pipefail

# ---------- 参数解析 ----------
if [ $# -lt 1 ]; then
    echo "用法: ./install.sh <目标项目根目录> [--force]" >&2
    exit 1
fi

PROJECT_ROOT="$1"
FORCE=0
for arg in "${@:2}"; do
    case "$arg" in
        -f|--force) FORCE=1 ;;
        *) echo "错误：未知参数：$arg" >&2; exit 1 ;;
    esac
done

PKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- 基础校验 ----------
if [ ! -d "$PROJECT_ROOT" ]; then
    echo "错误：目标项目根目录不存在：$PROJECT_ROOT" >&2
    exit 1
fi
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

# 计算规则包相对项目根的路径（统一正斜杠）：
# 优先 python3（须实际可运行——Windows 下 WindowsApps 的 python3 别名 stub
# 仅 command -v 可见，执行即失败），退回 GNU realpath
RULES_ROOT=""
if command -v python3 >/dev/null 2>&1 && python3 -c 'import os,sys' >/dev/null 2>&1; then
    RULES_ROOT="$(python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]).replace(os.sep,"/"))' "$PKG_ROOT" "$PROJECT_ROOT")"
elif command -v realpath >/dev/null 2>&1 && realpath --relative-to="$PROJECT_ROOT" "$PKG_ROOT" >/dev/null 2>&1; then
    RULES_ROOT="$(realpath --relative-to="$PROJECT_ROOT" "$PKG_ROOT" | tr '\\' '/')"
fi

if [ -z "$RULES_ROOT" ]; then
    echo "错误：无法计算相对路径（需要可用的 python3 或 GNU realpath）。请安装 python3 后重试。" >&2
    exit 1
fi

case "$RULES_ROOT" in
    ../*)
        echo "错误：规则包必须位于目标项目内（当前位于项目外：$PKG_ROOT）。请先把整个规则包目录复制或克隆到项目内，再执行本脚本。" >&2
        exit 1
        ;;
esac

# ---------- 部署函数 ----------
DEPLOYED=()
SKIPPED=()

# 渲染并写入单个入口文件：render <源文件(相对包根)> <目标(相对项目根)> <标签> [部署说明]
# 内容改写顺序：先替换 {{RULES_ROOT}} 占位符，再将包内相对路径 `rules/、`skills/ 前缀化
render() {
    local src_rel="$1" dst_rel="$2" label="$3" note="${4:-}"
    local src="$PKG_ROOT/$src_rel" dst="$PROJECT_ROOT/$dst_rel"

    if [ ! -f "$src" ]; then
        echo "错误：规则包内缺少源文件：$src_rel" >&2
        exit 1
    fi
    if [ -f "$dst" ] && [ "$FORCE" -ne 1 ]; then
        SKIPPED+=("[$label] $dst_rel（已存在，跳过；--force 可覆盖）")
        return
    fi

    mkdir -p "$(dirname "$dst")"
    awk -v root="$RULES_ROOT" -v note="$note" '
        NR == 1 && note != "" { print; print ""; print note; next }
        {
            gsub(/\{\{RULES_ROOT\}\}/, root)
            gsub(/`rules\//,  "`" root "/rules/")
            gsub(/`skills\//, "`" root "/skills/")
            print
        }
    ' "$src" > "$dst"
    DEPLOYED+=("[$label] $dst_rel")
}

# ---------- 开始部署 ----------
echo "== CMSPRO 规则技能包一键部署 =="
echo "目标项目根：$PROJECT_ROOT"
echo "规则包路径：$RULES_ROOT"
echo ""

AGENTS_NOTE="> **部署说明**：本文件由规则技能包部署脚本生成，规则包位于 \`$RULES_ROOT/\`；下文所述「本包」即该目录，文内 \`rules/\`、\`skills/\` 等相对路径已改写为项目内实际路径。"

# 1) AGENTS.md：Codex / OpenCode / Zed / Jules 等 AGENTS.md 约定工具（项目根）
render 'AGENTS.md' 'AGENTS.md' 'Codex/OpenCode/Zed 等' "$AGENTS_NOTE"

# 2) CLAUDE.md：Claude Code（项目根，@AGENTS.md 同目录导入）
render 'CLAUDE.md' 'CLAUDE.md' 'Claude Code'

# 3) .cursorrules：Cursor 旧版（项目根）
render '.cursorrules' '.cursorrules' 'Cursor 旧版'

# 4) adapters/ 各目录式工具入口
render 'adapters/cursor/cmspro.mdc'              '.cursor/rules/cmspro.mdc'        'Cursor 新版'
render 'adapters/trae/cmspro.md'                 '.trae/rules/cmspro.md'           'Trae'
render 'adapters/windsurf/cmspro.md'             '.windsurf/rules/cmspro.md'       'Windsurf'
render 'adapters/cline/cmspro.md'                '.clinerules/cmspro.md'           'Cline'
render 'adapters/github/copilot-instructions.md' '.github/copilot-instructions.md' 'GitHub Copilot'
render 'adapters/gemini/GEMINI.md'               'GEMINI.md'                       'Gemini CLI'
render 'adapters/aider/CONVENTIONS.md'           'CONVENTIONS.md'                  'Aider'
render 'adapters/codebuddy/cmspro.md'            '.codebuddy/rules/cmspro.md'      'CodeBuddy'

# ---------- 部署结果 ----------
echo "-- 已部署 ${#DEPLOYED[@]} 个入口 --"
for item in "${DEPLOYED[@]}"; do
    echo "  $item"
done
if [ "${#SKIPPED[@]}" -gt 0 ]; then
    echo ""
    echo "-- 跳过 ${#SKIPPED[@]} 个（已存在）--"
    for item in "${SKIPPED[@]}"; do
        echo "  $item"
    done
fi

echo ""
echo "后续建议："
echo "  1. 将上述入口文件随项目提交，团队成员克隆后各工具即可自动加载规则；"
echo "  2. 需要技能自动触发时（可选）：Claude Code 将 \"$RULES_ROOT/skills/\" 下各技能目录复制到 .claude/skills/；Trae 复制到 .trae/skills/；"
echo "  3. 规则包升级后，在包目录重新执行本脚本并加 --force 覆盖部署。"
