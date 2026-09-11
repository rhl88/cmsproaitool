# 维度六：代码规范符合性检查清单

> 依据：`rules/CmsPro-v5-应用开发文档.md`（下称"开发文档"）、`rules/01-CMSPRO开发规范.md`（下称"CMSPRO 规则"）、用户开发规范
> 检查对象：应用代码安全、框架保护、错误码、日期处理、Git 提交、命名与结构
> 判定级别：**[严重]** 一票否决 / **[强制]** 必须整改 / **[建议]** 优化项

---

## 6.1 全局框架保护（最高优先级）

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| S1 | 未修改 `vendor/`（框架源码与第三方包） | [严重] | 在 code 目录运行 `git status vendor/`（或 `git diff --stat vendor/`）核对无变更 |
| S2 | 未修改 `config/app.php`、`config/auth.php`、`config/database.php` 等全局配置 | [严重] | `git status config/` 核对 |
| S3 | 未在 `routes/web.php`、`routes/api.php` 等系统路由文件添加应用专属路由 | [严重] | `git status routes/` + 读路由文件核对 |
| S4 | 未修改 `app/Http/Middleware/`、`app/Console/`、`app/Providers/`（非应用级）等系统核心类 | [严重] | `git status app/ -- ':!app/Apps'` 核对 Apps 外无变更 |
| S5 | 确需框架级修改时，已按审批流程说明（文件位置/原因/影响/替代方案）并获确认，代码注释标注修改原因与审批记录 | [强制] | [人工] 查变更记录与注释核对（CMSPRO 规则第0章） |

## 6.2 安全规范

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| S6 | 敏感字段（API 密钥、token、密码凭据）使用 `Crypt::encryptString()`/`decryptString()`，模型 `setXxxAttribute`/`getXxxAttribute` 封装；禁止 openssl_encrypt 自写加密或第三方加密库 | [强制] | Grep：`openssl_encrypt\|openssl_decrypt` 应无命中；核对敏感字段模型（开发文档第八章；注：若应用明确采用明文存储策略，须有用户确认记录并在文档中说明） |
| S7 | 严禁硬编码密钥、密码、Token（代码、配置、视图中均禁止） | [严重] | Grep：`sk-[a-zA-Z0-9]{20,}\|api_key\s*=\s*['"][^'"]{16,}\|password\s*=\s*['"]` 排查（排除占位符与变量引用） |
| S8 | 设置接口使用 `ALLOWED_KEYS` 白名单常量显式枚举配置项，禁止 `$request->all()` / `$request->except()` 接收；写入正确指定 `group_id`（禁止写 0 或不存在的组） | [严重] | Grep：`request->all\(\)` 于 Settings/Config 类 Controller 核对（开发文档12A.3） |
| S9 | 配置类敏感项封装 SettingService 暴露 `ENCRYPTED_CODES` 白名单，非敏感项不调用加解密 | [强制] | 读 SettingService（如存在）核对（开发文档第八章） |
| S10 | SQL 注入防护：查询使用 Eloquent/Query Builder 参数绑定，无字符串拼接 SQL（`DB::raw` 拼接用户输入）；文件路径访问使用项目既定黑名单方案（禁 OS 关键目录） | [严重] | Grep：`DB::raw\|whereRaw\|DB::select` 核对拼接来源；读文件操作类核对路径校验 |
| S11 | 敏感数据脱敏展示：列表/详情返回密钥类字段做掩码（如 `sk_a***z`），密码不明文存储 | [强制] | 读列表接口输出核对（CMSPRO 规则·用户规范） |
| S12 | 前台公开页面不返回敏感数据；公开 API 有合理频率限制（throttle） | [强制] | 读 Home 路由/控制器核对（开发文档第二十章第19条·20.11） |
| S13 | 子域名应用 CORS 中间件规范：路径白名单（非全局开放）、Origin 校验、OPTIONS 预检直接 204、`prepend()` 注册（非 append）、withCredentials 时 Allow-Origin 不为 `*` | [强制] | 读 CORS 中间件（开发文档22.4.1，仅子域名应用适用） |

## 6.3 日期时间处理

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| S14 | 统一 `Y-m-d H:i:s`，禁止 ISO 8601（`...T...Z`、`+08:00`）输出给前端/写库 | [严重] | Grep：`toIso8601String\|ISO8601\|->toJSON\(` 排查；API 响应抽查（CMSPRO 规则第1章） |
| S15 | Controller/Service/前端禁止对模型取出的日期二次 `format()`；手动构建 JSON 响应时 Carbon 显式 `format('Y-m-d H:i:s')` | [强制] | Grep：`->format\(` 于 Controller/Service 核对场景（CMSPRO 规则第1章） |
| S16 | 第三方 ISO 8601 日期写库前解析（`Carbon::parse(...)->format('Y-m-d H:i:s')`），禁止直接赋值模型日期字段（MySQL Invalid datetime 异常） | [强制] | Grep：`paid_at\|success_time` 等外部日期字段赋值处核对（CMSPRO 规则第1章） |

## 6.4 错误码与响应体系

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| S17 | 统一响应结构（code/message/data），业务错误用 `4xxxx`（40001 参数错误、40002 冲突、40003 登录过期等），与 50001 服务器内部错误严格区分 | [强制] | Grep：`ApiResponse::error\(` 收集错误码核对分层（开发文档第十八章） |
| S18 | 安装/卸载/升级相关错误码使用规范（50001~50019：50004 依赖未安装、50017 依赖未启用、50015 被依赖阻止卸载、50019 前台路由冲突等） | [强制] | 读安装器相关调用核对（开发文档第十八章） |
| S19 | 错误信息对用户友好、对开发者详细；异常均被捕获处理，无裸 `throw` 到用户界面 | [建议] | 读关键 Service 异常分支核对 |

## 6.5 代码结构与质量

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| S20 | 命名语义清晰（禁止 temp/data/func 模糊命名），驼峰或下划线全项目统一 | [强制] | 抽读 Controllers/Services 核对（用户规范） |
| S21 | 单函数 ≤50 行、圈复杂度 ≤10、参数 ≤4（超出封装对象）、嵌套 ≤3 层（提前返回）、单行 ≤120 字符 | [建议] | 抽读核心 Service/Controller 方法核对（用户规范） |
| S22 | 公共方法、复杂逻辑、核心业务代码有注释（功能/入参出参/业务背景）；无错误注释 | [强制] | 抽读核心方法核对（用户规范） |
| S23 | 重复代码抽取复用，模块分层清晰（Controller 不写业务、Service 不写 HTTP 层逻辑） | [建议] | [人工] 读分层结构核对 |
| S24 | 日志规范：关键业务流程、异常场景、第三方调用打日志；日志禁止泄露密钥/密码敏感信息 | [强制] | Grep：`Log::` 核对关键节点；检查日志内容不含敏感字段（用户规范） |

## 6.6 Git 提交规范

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| S25 | 应用目录存在 `.git` 时：变更已在应用目录内提交，工作区干净（无未跟踪/未提交变更） | [强制] | 在应用目录运行 `git status` 核对（CMSPRO 规则第3章） |
| S26 | 提交信息 `type(scope): subject` 中文格式（scope 用应用名），聚焦"为什么改" | [强制] | `git log -5` 核对格式（CMSPRO 规则第3章） |
| S27 | `git add` 仅添加具体文件，未使用 `git add -A` / `git add .`（无 .env、临时文件、运行产物入库） | [强制] | `git show --stat HEAD` 核对提交文件清单（CMSPRO 规则第3章） |
| S28 | 未自动 push 远程（本地 commit 后由用户逐次决定） | [强制] | [人工] 询问用户/核对操作记录（CMSPRO 规则第3、4章） |
| S29 | 框架仓库（code 目录）未混入应用目录变更（app/Apps/ 仅 Versionmgr 入库；public/apps/ 构建产物未提交） | [强制] | 在 code 目录 `git status` 核对无 Apps 应用与 public/apps 变更（CMSPRO 规则第4章） |
| S30 | 应用 `.gitignore` 覆盖敏感文件（.env）与运行产物（*.exe/*.bak/*.tmp、venv/） | [强制] | 读应用 .gitignore 核对（CMSPRO 规则第3章） |

## 6.7 发布物规范

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| S31 | `.exportignore` 排除 Tests/、tests/、.git/（.git 内对象只读，随包分发导致解压失败） | [强制] | 读 .exportignore（开发文档第十六章·CMSPRO 规则） |
| S32 | 安装包内无敏感文件（.env、含密钥的配置）、无开发残留（.bak、.tmp、调试脚本） | [严重] | 检查导出流程与 .exportignore 覆盖度（开发文档第十六章） |
| S33 | 版本管理：manifest version 已按语义化版本提升，changelog/文档同步记录本次变更 | [强制] | 读 manifest.json 与 doc/ 变更记录比对（CMSPRO 规则·开发文档第二十一章） |
