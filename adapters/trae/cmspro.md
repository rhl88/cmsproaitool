***

## alwaysApply: true

# CMSPRO 规则技能包 · Trae 规则入口

> 完整规则与文档以规则包（`{{RULES_ROOT}}/`）为单一来源：核心规则见 `{{RULES_ROOT}}/AGENTS.md`，详细规范见 `{{RULES_ROOT}}/rules/`，技能见 `{{RULES_ROOT}}/skills/`。本文件为核心精简版。

## 语言要求（最高优先级）

思考与回复全程使用中文；代码注释、技术文档、对话交流均使用中文。

## 核心行为准则（八荣八耻）

以瞎猜接口为耻，以认真查询为荣。以模糊执行为耻，以寻求确认为荣。
以臆想业务为耻，以人类确认为荣。以创造接口为耻，以复用现有为荣。
以跳过验证为耻，以主动测试为荣。以破坏架构为耻，以遵循规范为荣。
以假装理解为耻，以诚实无知为荣。以盲目修改为耻，以谨慎重构为荣。

工作方式：收到任务先检查规则包 `{{RULES_ROOT}}/skills/` 是否有匹配技能（触发条件见 `{{RULES_ROOT}}/AGENTS.md` 第五章）；设计先于编码；测试先于实现；验证先于完成；不做主观假设；优先保持简洁；只改必要内容。

## 全局框架保护（最高优先级）

- 禁止修改 `vendor/`、`config/` 全局配置、`routes/` 系统路由、`app/Http/Middleware/` 系统中间件、`app/Console|Exceptions|Providers`（非应用级）等全局框架代码。
- 一切扩展通过 `app/Apps/{AppName}/` 应用模块实现；确需改框架必须先说明（文件位置/原因/影响/替代方案）并征得确认。
- 禁止 `php artisan serve` / `php -S` 自建服务；禁止停用/重启现有 Web 服务；禁止「域名 + 端口」访问。

## 必读规范（按任务加载，位于规则包 `{{RULES_ROOT}}/rules/` 目录）

- 任何代码编写 → `{{RULES_ROOT}}/rules/01-CMSPRO开发规范.md`
- 应用开发/架构分析 → `{{RULES_ROOT}}/rules/CmsPro-v5-应用开发文档.md`
- 应用视图开发 → `{{RULES_ROOT}}/rules/应用视图规范.md`
- UI 视觉与交互 → `{{RULES_ROOT}}/rules/CMSPRO-UI开发规范.md`
- 疑难问题排查 → `{{RULES_ROOT}}/rules/CMSPRO-v5-应用开发常见问题.md`
- 调整已有应用前，必读该应用 `app/Apps/{AppName}/doc/` 文档；修改后同步更新对应文档。

## 关键硬性规范

1. 日期时间统一 `Y-m-d H:i:s`，禁止 ISO 8601；模型层配置 `$casts`；外部 ISO 8601 写库前必须解析。
2. 排查问题先看数据（打印变量、查库、对比接口差异），禁止从报错文案反推猜测。
3. Git：应用目录内提交（有独立 .git 时）；`git add` 只加具体文件，禁止 `git add -A`；提交信息 `type(scope): subject` 中文格式；禁止未经确认自动 push；框架级调整在 code 目录提交并双远程同步。
4. 测试：应用测试放 `app/Apps/{AppName}/Tests/`，禁止放入框架 `tests/`；应用级测试单独执行。
5. 文件编码：UTF-8 无 BOM。
6. Blade：`<script type="text/html">` 块用 `@verbatim ... @endverbatim` 包裹；注释中禁止出现指令关键字；Layui 模板 `{{ }}` 用 `@{{ }}` 转义。
7. 数据库中的应用路径字段一律存相对路径。

## 技能索引（位于规则包 `{{RULES_ROOT}}/skills/`，任务命中触发条件时读取对应 SKILL.md）

- 开发/分析应用 → `{{RULES_ROOT}}/skills/app-technical-analysis/SKILL.md`
- 维护/修复/升级应用 → `{{RULES_ROOT}}/skills/app-maintenance/SKILL.md`
- 应用验收 → `{{RULES_ROOT}}/skills/app-acceptance/SKILL.md`
- 编写测试 → `{{RULES_ROOT}}/skills/laravel-testing/SKILL.md`
- 数据库变更 → `{{RULES_ROOT}}/skills/database-change-management/SKILL.md`
- 通用开发规范 → `{{RULES_ROOT}}/skills/dev-standards/SKILL.md`
- 代码审查 → `{{RULES_ROOT}}/skills/chinese-code-review/SKILL.md`
- 提交信息 → `{{RULES_ROOT}}/skills/chinese-commit-conventions/SKILL.md`
- 技术文档 → `{{RULES_ROOT}}/skills/chinese-documentation/SKILL.md`
