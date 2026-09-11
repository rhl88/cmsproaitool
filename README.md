# CMSPRO 规则技能包

CMSPRO v5 的 AI 编码助手协作规则与技能打包，面向**任何 AI 编码工具**开放使用：Claude Code、Cursor、Codex、Trae、龙虾、Hermes、WorkBuddy、WorkCode 等。

包内所有引用均为相对路径，不含任何环境地址、账号与内部仓库信息，可直接分发与二次定制。

## 包结构

```
规则技能包/
├── AGENTS.md                # 通用规则入口（自包含核心规则，任何工具可直接使用）
├── CLAUDE.md                # Claude Code 入口（导入 AGENTS.md）
├── .cursorrules             # Cursor 入口（核心规则精简版）
├── README.md                # 本文件：包说明 + 各 AI 工具接入指南
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

## 一键使用（推荐）

无需手动复制任何文件。把下面这段提示词**整段复制**粘贴给你正在使用的 AI 编码工具（Claude Code、Cursor、Codex、Trae、龙虾、Hermes、WorkBuddy、WorkCode 等均可），即可让它自动拉取并加载本包全部规则与技能：

```text
请先为我完成规则加载，然后开始工作：
1. 克隆 CMSPRO 规则技能包到当前环境（已存在则跳过并更新到最新）：
   git clone https://gitee.com/holley/cmsproaitool.git cmspro-rules
   （GitHub 源：https://github.com/rhl88/cmsproaitool.git，网络不通时可换用）
2. 通读 cmspro-rules/AGENTS.md，严格遵守其中全部规则（语言要求、八荣八耻、全局框架保护、关键硬性规范）。
3. 后续任务命中 AGENTS.md 第五章技能索引的触发条件时，先读取 cmspro-rules/skills/<技能名>/SKILL.md 并严格遵循其流程。
4. 需要查阅详细规范时，按 AGENTS.md 第三章索引读取 cmspro-rules/rules/ 对应文档。
完成后回复「CMSPRO 规则已加载」，然后等待我的任务指令。
```

> 说明：
> - 该提示词不依赖任何工具的规则配置机制，纯对话即可生效，适合所有 AI 工具。
> - 若工具支持项目级规则（AGENTS.md / .cursorrules / 自定义指令），建议再按下方「接入指南」做持久化配置，避免每次会话重复粘贴。
> - 在 CMSPRO 项目内使用时，若本包已随项目分发（如位于 `docs/规则技能包/`），可把第 1 步替换为直接读取该目录下的 `AGENTS.md`。

## 接入指南

统一原则：**规则以 `AGENTS.md` 为单一入口**，各工具按下表方式接入；技能目录 `skills/` 保持包内相对结构整体复制，技能内文引用的规范路径（`rules/...`）才能正确解析。

### Claude Code

1. 将本包 `CLAUDE.md` 复制到**项目根**（自动加载，内容会导入 `AGENTS.md`，两者需保持同目录或按实际路径调整 `@` 导入）。
2. 技能自动触发（可选）：将 `skills/` 下各技能目录复制到项目 `.claude/skills/` 或用户级 `~/.claude/skills/`。

### Codex（OpenAI）

1. 将本包 `AGENTS.md` 复制到**项目根**，Codex 原生自动加载。
2. 技能：Codex 无原生技能系统，AI 会按 AGENTS.md 第五章索引按需读取对应 `skills/<技能名>/SKILL.md`；请保持 `rules/` 与 `skills/` 相对结构完整。

### Cursor

1. 旧版：将本包 `.cursorrules` 复制到**项目根**。
2. 新版（推荐）：在项目 `.cursor/rules/` 下新建规则文件（如 `cmspro.mdc`，frontmatter 设置 `alwaysApply: true`），内容引用或粘贴 `AGENTS.md`。
3. 请保持本包目录完整，规则文件中的文档引用按包内相对路径解析。

### Trae

1. 将 `rules/01-CMSPRO开发规范.md`、`rules/02-CMSPRO协作总则.md`、`rules/03-通用编码准则.md` 复制到项目 `.trae/rules/`（文件头部自带 `alwaysApply: true`）。
2. 技能自动触发（可选）：将 `skills/` 下各技能目录复制到 `.trae/skills/`。

### 其他工具（龙虾、Hermes、WorkBuddy、WorkCode 等）

按工具能力三选一：

| 工具能力                                 | 接入方式                                                                 |
| ---------------------------------------- | ------------------------------------------------------------------------ |
| 支持 AGENTS.md 约定                       | 将 `AGENTS.md` 放项目根                                                  |
| 支持自定义系统提示 / 项目规则 / 自定义指令 | 将 `AGENTS.md` 全文粘贴到对应配置                                        |
| 均不支持                                  | 每次任务开始时指示 AI：「请先阅读 docs/规则技能包/AGENTS.md 并严格遵守」 |

技能使用：任务命中技能触发条件时，指示 AI 读取对应 `skills/<技能名>/SKILL.md` 并遵循其流程（触发条件清单见 `AGENTS.md` 第五章）。

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
- **入口文件可按工具裁剪**：只用 Codex 可删去 `CLAUDE.md` 与 `.cursorrules`；只用 Claude Code 可删去 `.cursorrules`。
- **环境信息自行填写**：`rules/01-CMSPRO开发规范.md` 中「当前开发信息」与「双远程配置」为占位符，由使用者按实际环境填写。
- **更新方式**：规范文档升级后，替换 `rules/` 对应文件并同步 `AGENTS.md` 摘要；新增问题案例按 `rules/CMSPRO-v5-应用开发常见问题.md` 文末模板追加；新增技能在 `skills/` 建目录并同步 `AGENTS.md` 第五章与 `rules/02-CMSPRO协作总则.md` 路由表。

## 版本

- 打包版本：v1.0.0（2026-09-11）
- 规范来源：CMSPRO v5 开发体系（`.trae/rules` 规则 + `docs/` 规范文档 + 项目技能库）
