# CMSPRO 规则技能包

CMSPRO v5 的 AI 编码助手协作规则与技能打包，面向**任何 AI 编码工具**开放使用：Claude Code、Cursor、Codex、Trae、Windsurf、Cline、GitHub Copilot、Gemini CLI、Aider、CodeBuddy、Kiro、Qoder、通义灵码、OpenCode、龙虾、Hermes、WorkBuddy、WorkCode 等。

包内所有引用均为相对路径，不含任何环境地址、账号与内部仓库信息，可直接分发与二次定制。

## 包结构

```
规则技能包/
├── AGENTS.md                # 通用规则入口（自包含核心规则）：Codex/OpenCode/Zed 等 AGENTS.md 约定工具的项目根入口
├── CLAUDE.md                # Claude Code 入口（@AGENTS.md 导入）
├── .cursorrules             # Cursor 旧版入口（核心规则精简版）
├── README.md                # 本文件：包说明 + 接入指南
├── install.ps1              # 一键部署脚本（Windows PowerShell，含非 ASCII 故保存为 UTF-8 带 BOM）
├── install.sh               # 一键部署脚本（macOS / Linux / Git Bash）
├── adapters/                # 各目录式规则工具的入口模板（部署时由脚本替换 {{RULES_ROOT}} 占位符）
│   ├── cursor/cmspro.mdc             # → .cursor/rules/（Cursor 新版，alwaysApply）
│   ├── trae/cmspro.md                # → .trae/rules/（Trae，alwaysApply）
│   ├── windsurf/cmspro.md            # → .windsurf/rules/（Windsurf，trigger: always_on）
│   ├── kiro/cmspro.md                # → .kiro/steering/（Kiro，inclusion: always）
│   ├── cline/cmspro.md               # → .clinerules/（Cline）
│   ├── qoder/cmspro.md               # → .qoder/rules/（Qoder，无 frontmatter 始终生效）
│   ├── github/copilot-instructions.md # → .github/（GitHub Copilot 仓库级指令）
│   ├── gemini/GEMINI.md              # → 项目根（Gemini CLI，@导入 AGENTS.md）
│   ├── aider/CONVENTIONS.md          # → 项目根（Aider 自动读取）
│   └── codebuddy/cmspro.md           # → .codebuddy/rules/（CodeBuddy，alwaysApply）
├── rules/                   # 规范文档（单一来源）
│   ├── 01-CMSPRO开发规范.md           # PHP 开发编码规范（框架保护/日期时间/排查原则/Git 策略/文件编码）
│   ├── 02-CMSPRO协作总则.md           # 语言要求、核心工作流、技能路由
│   ├── 03-通用编码准则.md             # 通用编码行为准则（思考先行/简洁/精准修改/目标驱动）
│   ├── CmsPro-v5-应用开发文档.md      # 应用开发完整规范（目录/manifest/数据库/路由/钩子/安装卸载）
│   ├── 应用视图规范.md                # 应用视图开发规范（列表页/表单页结构、Layui 模板、公共资源）
│   ├── CMSPRO-UI开发规范.md           # UI 视觉规范（色彩/字体/图标/组件/动效/可访问性）
│   └── CMSPRO-v5-应用开发常见问题.md  # 问题案例库（现象/根因/修复/验证/通用经验）
└── skills/                  # 技能（SKILL.md 标准格式，含 frontmatter 触发条件）
    ├── app-technical-analysis/       # 应用技术分析与开发指导
    ├── app-maintenance/              # 应用日常维护（分析→修复→测试→文档→发布闭环）
    ├── app-acceptance/               # 应用六维度验收（含 references 检查清单）
    ├── laravel-testing/              # Laravel 测试方案与最佳实践
    ├── database-change-management/   # 数据库变更管理（SQL 脚本/回滚/排错，含模板示例）
    ├── dev-standards/                # 通用开发规范
    ├── chinese-commit-conventions/   # 中文 Git 提交规范
    ├── chinese-documentation/        # 中文技术文档写作规范
    └── chinese-code-review/          # 中文代码审查规范
```

## 快速接入（三选一）

### 方式一：一键部署（推荐，各工具自动加载）

规则包自带部署脚本，把各工具入口文件自动安装到目标项目根目录。**前提：规则包整个目录已放入目标项目内**（任意子目录位置均可，如 `docs/规则技能包/` 或克隆为 `cmspro-rules/`），脚本会自动计算包相对项目的路径并写入各入口。

```powershell
# Windows（PowerShell，在规则包目录内执行；若执行策略受限可加 -ExecutionPolicy Bypass）
.\install.ps1 -ProjectRoot <目标项目根目录>          # 首次部署（已存在的入口自动跳过）
.\install.ps1 -ProjectRoot <目标项目根目录> -Force    # 规则包升级后覆盖部署
```

```bash
# macOS / Linux / Git Bash
./install.sh <目标项目根目录>          # 首次部署
./install.sh <目标项目根目录> --force  # 覆盖部署
```

部署产物与工具对照（共 13 个入口，均为薄入口，详细规范仍以包内 `rules/`、`skills/` 为单一来源）：

| 工具 | 部署位置 | 加载机制 |
| --- | --- | --- |
| Codex / OpenCode / Zed / Jules 等 | `AGENTS.md`（项目根） | AGENTS.md 约定自动加载 |
| Claude Code | `CLAUDE.md`（项目根） | 项目级规则自动加载（`@AGENTS.md` 同目录导入） |
| Cursor（新版） | `.cursor/rules/cmspro.mdc` | `alwaysApply: true` 规则自动注入 |
| Cursor（旧版） | `.cursorrules`（项目根） | 兼容旧版机制自动加载 |
| Trae | `.trae/rules/cmspro.md` | `alwaysApply: true` 规则自动加载 |
| Windsurf | `.windsurf/rules/cmspro.md` | `trigger: always_on` 自动加载 |
| Cline | `.clinerules/cmspro.md` | 规则目录自动加载 |
| GitHub Copilot | `.github/copilot-instructions.md` | 仓库级自定义指令（需在仓库/Copilot 设置中启用 custom instructions） |
| Gemini CLI | `GEMINI.md`（项目根） | 分层记忆自动加载（`@` 导入 AGENTS.md） |
| Aider | `CONVENTIONS.md`（项目根） | 自动纳入会话上下文 |
| CodeBuddy | `.codebuddy/rules/cmspro.md` | 规则目录自动加载 |
| Kiro | `.kiro/steering/cmspro.md` | `inclusion: always` Steering 自动加载（Kiro 亦原生兼容项目根 `AGENTS.md`，双保险） |
| Qoder / 通义灵码 | `.qoder/rules/cmspro.md` | 无 frontmatter 规则随项目记忆始终生效（Qoder 亦自动读取项目根 `AGENTS.md`，双保险） |

部署说明：

- 脚本仅生成上述入口文件，不改动项目其他内容；目标位置已存在同名文件时默认跳过，`-Force` / `--force` 覆盖。
- 包根 `AGENTS.md` / `CLAUDE.md` / `.cursorrules` 部署时，其中的 `rules/`、`skills/` 相对路径会自动改写为规则包在项目内的实际路径；`adapters/` 模板中的 `{{RULES_ROOT}}` 占位符同理替换。
- 部署后建议将入口文件随项目提交，团队成员克隆后各工具即可直接自动加载规则。
- 技能自动触发（可选）：Claude Code 将包内 `skills/` 下各技能目录复制到 `.claude/skills/`；Trae 复制到 `.trae/skills/`；其余工具由 AI 按 `AGENTS.md` 第五章索引按需读取。

### 方式二：手动接入

不使用脚本时，参照上表把包根入口文件与 `adapters/` 对应模板复制到目标位置，并将文件内的 `{{RULES_ROOT}}` 占位符与 `rules/`、`skills/` 相对路径替换为规则包在项目内的实际路径。只使用单一工具时，只复制对应入口即可（如只用 Codex，仅需 `AGENTS.md` 到项目根）。请保持本包目录完整，规则文件中的文档引用按包内相对路径解析。

### 方式三：纯对话兜底（无任何规则配置机制时）

把下面这段提示词**整段复制**粘贴给你正在使用的 AI 编码工具即可，不依赖任何工具的规则配置机制，纯对话生效：

```text
请先为我完成规则加载，然后开始工作：
1. 检查当前项目内是否已有 CMSPRO 规则技能包（依次查找 docs/规则技能包/、cmspro-rules/ 目录）：
   - 已存在 → 直接使用该目录，并在其内执行 git pull 拉取最新版（拉取失败如网络不通则沿用本地现有版本继续）；
   - 不存在 → 克隆到项目内：git clone https://gitee.com/holley/cmsproaitool.git cmspro-rules
     （GitHub 源：https://github.com/rhl88/cmsproaitool.git，网络不通时可换用）
2. 通读规则包根目录的 AGENTS.md，严格遵守其中全部规则（语言要求、八荣八耻、全局框架保护、关键硬性规范）。
3. 后续任务命中 AGENTS.md 第五章技能索引的触发条件时，先读取规则包 skills/<技能名>/SKILL.md 并严格遵循其流程。
4. 需要查阅详细规范时，按 AGENTS.md 第三章索引读取规则包 rules/ 对应文档。
完成后回复「CMSPRO 规则已加载」，然后等待我的任务指令。
```

> 说明：
> - 已按方式一/二完成持久化配置的项目无需再粘贴提示词。
> - 提示词第 1 步会优先命中随项目分发的规则包（如 `docs/规则技能包/`），避免重复克隆。
> - 技能使用：任务命中技能触发条件时，AI 会读取对应 `skills/<技能名>/SKILL.md` 并遵循其流程（触发条件清单见 `AGENTS.md` 第五章）。

## 不支持上述任何机制的工具（龙虾、Hermes、WorkBuddy、WorkCode 等）

按工具能力三选一：

| 工具能力                                 | 接入方式                                                                 |
| ---------------------------------------- | ------------------------------------------------------------------------ |
| 支持 AGENTS.md 约定                       | 方式一/二部署 `AGENTS.md` 到项目根                                        |
| 支持自定义系统提示 / 项目规则 / 自定义指令 | 将 `AGENTS.md` 全文粘贴到对应配置                                         |
| 均不支持                                  | 每次任务开始时用「方式三」提示词，或指示 AI：「请先阅读规则包 AGENTS.md 并严格遵守」 |

## 规则文件说明

| 文件                             | 定位                                                                             |
| -------------------------------- | -------------------------------------------------------------------------------- |
| `AGENTS.md`                      | 规则入口：核心规则自包含 + 文档/技能索引，任何工具的第一加载点                    |
| `rules/01-CMSPRO开发规范.md`     | 强制规范：全局框架保护、日期时间 `Y-m-d H:i:s`、先看数据排查原则、Git 提交与推送策略、UTF-8 无 BOM |
| `rules/02-CMSPRO协作总则.md`     | 协作方式：中文强制、四先工作流（检查技能/设计/测试/验证）、技能路由表              |
| `rules/03-通用编码准则.md`       | 行为准则：编码前先思考、优先保持简洁、精准修改、目标驱动执行                      |
| `rules/CmsPro-v5-应用开发文档.md` | 应用开发百科：目录结构、manifest.json、命名空间、数据库隔离、路由、视图、钩子、安装/卸载/升级、测试 |
| `rules/应用视图规范.md`          | 视图落地：后台列表页/表单页标准结构、Layui `@verbatim`、公共资源引用、权限控制     |
| `rules/CMSPRO-UI开发规范.md`     | UI 标准：色彩/字体/图标/间距、组件规范、动效、响应式、可访问性、资源本地化        |
| `rules/CMSPRO-v5-应用开发常见问题.md` | 案例库：已踩坑问题的现象→根因→修复→验证→通用经验，新增问题按文末模板追加      |

## 技能清单

| 技能                       | 用途                                                                 |
| -------------------------- | -------------------------------------------------------------------- |
| `app-technical-analysis`   | 开发/创建应用、架构与性能分析、扩展性评审、优化建议                   |
| `app-maintenance`          | 已有应用维护闭环：分析→修复→测试→文档→发布                            |
| `app-acceptance`           | 六维度验收：功能完整性、界面一致性、交互体验、性能、兼容性、代码规范   |
| `laravel-testing`          | 单元/功能/API/数据库/认证测试方案，替代 curl 手工测试                 |
| `database-change-management` | 数据库结构/数据变更的 SQL 升级脚本、版本控制、回滚方案              |
| `dev-standards`            | 命名、格式、结构、架构、安全、性能等通用编码规范                     |
| `chinese-commit-conventions` | `type(scope): subject` 中文提交信息规范                            |
| `chinese-documentation`    | 中文技术文档排版、术语、结构规范                                     |
| `chinese-code-review`      | 中文代码审查规范与反馈方式                                           |

## 使用建议

- **保持包结构完整**：`rules/` 与 `skills/` 的相对位置不变，包内所有交叉引用才能解析。
- **入口文件可按工具裁剪**：只用部分工具时，仅部署对应入口（见方式一对照表），不用的入口不部署即可。
- **环境信息自行填写**：`rules/01-CMSPRO开发规范.md` 中「当前开发信息」与「双远程配置」为占位符，由使用者按实际环境填写。
- **更新方式**：规范文档升级后，替换 `rules/` 对应文件并同步 `AGENTS.md` 摘要，同时同步 `adapters/` 各精简版入口（若核心规则有变）与包根 `.cursorrules`；新增问题案例按 `rules/CMSPRO-v5-应用开发常见问题.md` 文末模板追加；新增技能在 `skills/` 建目录并同步 `AGENTS.md` 第五章与 `rules/02-CMSPRO协作总则.md` 路由表；升级后在各项目内重新执行部署脚本并加 `-Force` / `--force` 覆盖。
- **编码说明**：包内所有文件为 UTF-8 无 BOM；唯一例外是 `install.ps1` 为 UTF-8 带 BOM——Windows PowerShell 5.1 对无 BOM 的 UTF-8 脚本会按 ANSI 误读中文导致语法错误，微软官方要求含非 ASCII 的 `.ps1` 必须带 BOM；该文件为部署工具，不参与 Web 输出。

## 版本

- 打包版本：v1.2.0（2026-09-13）
- 变更记录：
  - v1.2.0：新增 Kiro（`.kiro/steering/`）与 Qoder（`.qoder/rules/`）原生适配模板，入口总数 11 → 13；两者同时原生兼容项目根 `AGENTS.md`，形成双保险。
  - v1.1.0：新增 `install.ps1` / `install.sh` 一键部署脚本与 `adapters/` 八工具入口模板（Cursor 新版、Trae、Windsurf、Cline、GitHub Copilot、Gemini CLI、Aider、CodeBuddy），实现各工具自动加载；一键提示词改为优先检测项目内已有规则包。
  - v1.0.0（2026-09-11）：首次打包。
- 规范来源：CMSPRO v5 开发体系（`.trae/rules` 规则 + `docs/` 规范文档 + 项目技能库）
