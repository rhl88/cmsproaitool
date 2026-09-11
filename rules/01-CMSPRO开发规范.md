***

## alwaysApply: true

# PHP 开发编码规范

> **当前版本**：v1.1.0
> **最近更新**：2026-08-12

本项目 PHP 开发必须严格遵循以下规范，所有代码编写、审查、修改均需遵守。

## 八荣八耻

以瞎猜接口为耻，以认真查询为荣。
以模糊执行为耻，以寻求确认为荣。
以臆想业务为耻，以人类确认为荣。
以创造接口为耻，以复用现有为荣。
以跳过验证为耻，以主动测试为荣。
以破坏架构为耻，以遵循规范为荣。
以假装理解为耻，以诚实无知为荣。
以盲目修改为耻，以谨慎重构为荣

***

## 0. 全局框架保护（最高优先级）

**原则：应用开发或调整时，禁止修改应用外的全局框架代码，确需修改时必须先说明原因并征得确认。**

### 开发文档规范

**原则：涉及应用的开发必须基于开发文档，确保对系统架构和应用机制的充分理解。**

### 当前开发信息

> **以下信息由使用者按实际部署环境填写，本包不内置任何环境地址与账号**：
>
> * 开发环境访问地址：`<填写你的开发环境地址，如 http://your-domain>`
> * 开发环境后台账号：`<由环境管理员提供>`
> * 开发环境前端账号：`<由环境管理员提供>`

> **开发环境已配置完成，禁止重复启动服务**
>
> * 开发环境已由运维/环境配置完成，Web 服务（Nginx/Apache/PHP-FPM 等）已正常运行，直接通过开发环境既定访问地址即可访问，**无需、也不允许**再执行 `php artisan serve`、`php -S` 等命令自行启动开发服务器。
>
> * 若开发过程中需要验证页面效果，直接访问开发环境既定地址即可，不要额外开启端口服务。
>
> * **禁止使用「域名 + 端口」的方式访问或开启服务**，例如 `http://<开发环境地址>:8000`、`http://<开发环境地址>:8080` 等。开发环境唯一合法访问地址为既定的 80 端口地址，任何带端口号的访问地址均视为违规，一律不得使用。
>
> * **禁止停用、重启或占用现有开发环境服务**：即使检测到 80 端口被占用，也**严禁**停止、杀掉或重启现有 Web 服务（Nginx/Apache/PHP-FPM 等），更**禁止**停掉现有服务后再用 `php artisan serve`、`php -S` 等命令自建服务抢占 80 端口。现有服务是运维/环境配置好的，任何停止、重启、占用端口的操作均属违规。
>
> * 若确实遇到服务未启动或无法访问的情况，先检查环境配置，**禁止擅自启动新服务**，必要时向用户确认后再处理。

#### 应用开发文档要求

* **应用开发前**，必须深度熟悉并了解本包 `rules/CmsPro-v5-应用开发文档.md`（在 CMSPRO 项目中对应 `docs/CmsPro-v5-应用开发文档.md`），该文档包含了应用开发的完整规范（目录结构、命名空间、数据库隔离、视图、钩子系统、安装卸载流程等）

* **应用视图开发与调整**，必须遵守本包 `rules/应用视图规范.md` 的规范（后台列表页/表单页布局、Layui 模板 `@verbatim` 包裹、公共资源引用等）

* **应用调整前，必须先阅读该应用的** **`doc`** **文档**：对任意已有应用（`app/Apps/{AppName}/`）进行调整或修改前，必须先阅读其 `doc/` 目录下的文档（如 `app/Apps/{AppName}/doc/`），最大程度了解该应用的功能结构、业务逻辑、扩展点和集成方式，禁止未读文档直接动手修改

  * 示例：调整 `app/Apps/CmsproDemo` 应用，必须先了解 `app/Apps/CmsproDemo/doc/` 下的文档

* **关联应用开发时**，需阅读了解对应应用目录下的 `doc` 文档（如 `app/Apps/{AppName}/doc/`，即该应用的文档），理解目标应用的功能结构、扩展点和集成方式

* **应用调整时**，对已有应用做出修改后，必须同步检查该应用目录 `doc/` 下对应的文档是否需要更新，确保文档与代码保持一致

* **应用开发或调整后必须进行测试**：优先采用 Laravel 框架内置测试方案，必须遵循 `laravel-testing` 测试技能（本包 `skills/laravel-testing/SKILL.md`），禁止使用 `curl.exe` + cookie 文件 + 手工抓 CSRF token 等方式进行接口测试

* 违反上述规范导致的返工或质量问题，由开发者承担相应责任

### 保护范围

以下目录和文件属于全局框架范畴，**禁止**在应用开发过程中随意修改：

| 类别     | 路径                                                         | 说明               |
| ------ | ---------------------------------------------------------- | ---------------- |
| 框架核心   | `vendor/laravel/framework/`                                | Laravel 框架源码     |
| 框架核心   | `vendor/` 下其他第三方依赖                                         | Composer 安装的第三方包 |
| 系统基础配置 | `config/app.php`、`config/auth.php`、`config/database.php` 等 | 全局系统配置           |
| 系统核心类  | `app/Console/`、`app/Exceptions/`、`app/Providers/`（非应用级）    | 系统级核心类           |
| 公共路由   | `routes/` 下的系统路由文件（非应用路由）                                  | 全局路由定义           |
| 公共中间件  | `app/Http/Middleware/` 下的系统中间件                             | 全局中间件            |

> **应用级代码**指 `app/Apps/{AppName}/` 目录下的专属代码，不在本规则限制范围内。

### 违规示例

```
❌ 直接修改 vendor/laravel/framework/src/Illuminate/... 下的源码
❌ 修改 config/database.php 的默认数据库连接配置
❌ 在 routes/web.php 中添加应用专属路由
❌ 修改 app/Http/Kernel.php 注入全局中间件
```

### 正确做法

* 应用功能通过 **应用模块** (`app/Apps/{AppName}/`) 实现，不侵入框架层

* 需要扩展框架行为时，优先使用 Laravel 提供的 **扩展机制**（Service Provider、Macro、Event 等）

* 如确实需要修改全局框架代码，**必须提前说明**：

  1. 修改的具体文件和位置
  2. 修改的原因和业务背景
  3. 修改的影响范围评估
  4. 是否有替代方案及为何不可行

### 审批流程

1. 开发者发现需修改全局框架 → 停止操作
2. 提交修改申请（含上述四项说明）
3. 获得确认后方可执行修改
4. 修改后必须在代码注释中标注修改原因和审批记录

***

## 1. 日期时间处理

**原则：数据库中的日期字段直接读取输出，禁止二次格式化加工。**

### 正确格式

```
2026-05-23 15:29:13
```

### 禁止格式

```
2026-05-23T00:16:39.000000Z    // ISO 8601 带时区格式（Laravel 默认序列化格式）
2026-05-23T00:16:39+08:00      // ISO 8601 带偏移格式
May 23, 2026 3:29 PM           // 英文可读格式
```

### 实现方式

**Eloquent 模型层统一处理**，在 Model 中配置 `$casts` 或重写 `serializeDate()`：

```php
// 方案一：使用 $casts 将日期转为字符串（推荐）
protected $casts = [
    'created_at' => 'datetime:Y-m-d H:i:s',
    'updated_at' => 'datetime:Y-m-d H:i:s',
];

// 方案二：重写 serializeDate 方法（全局生效）
protected function serializeDate(DateTimeInterface $date): string
{
    return $date->format('Y-m-d H:i:s');
}
```

### 注意事项

* **禁止**在 Controller / Service 层对已从模型取出的日期字段再次调用 `format()` 方法

* **禁止**在前端视图或 API 响应中对日期做二次格式化

* **禁止**使用 Laravel 默认的 ISO 8601 序列化格式返回给前端

* 数据库存储什么格式，API/页面就展示什么格式（`Y-m-d H:i:s`）

* 新建模型时必须包含上述日期格式化配置

### 外部 ISO 8601 日期写入数据库

第三方 API（微信支付、支付宝等）返回的日期字段通常为 ISO 8601 格式（如 `2026-05-23T00:16:39+08:00`），**禁止直接赋值给 Eloquent 模型的日期字段**，MySQL 的 `datetime` 列不接受此格式，会抛出 `Invalid datetime format` 异常。

**必须**在写入数据库前，将 ISO 8601 字符串解析为 `Y-m-d H:i:s` 格式：

```php
// 正确：解析外部 ISO 8601 日期后写入
$paidAt = $result['paid_at'] ?? now();
if (is_string($paidAt)) {
    try {
        $paidAt = \Carbon\Carbon::parse($paidAt)->format('Y-m-d H:i:s');
    } catch (\Throwable $e) {
        $paidAt = now()->format('Y-m-d H:i:s');
    }
}
$order->update(['paid_at' => $paidAt]);

// 错误：直接将 ISO 8601 字符串写入数据库
$order->update(['paid_at' => $result['paid_at']]);  // 2026-05-23T00:16:39+08:00 → MySQL 报错
```

**适用场景**：

* 支付渠道回调/查询返回的 `paid_at`、`success_time` 等字段

* 任何第三方 API 返回的日期时间字段

* 手动构建 JSON 响应时，Carbon 对象必须显式 `format('Y-m-d H:i:s')`，不可直接放入 `response()->json()`

**不适用场景**：

* 从 Eloquent 模型取出的日期字段（已通过 `$casts` 或 `serializeDate()` 自动格式化，直接使用即可）

* `now()` 赋值给 Eloquent 模型时（Eloquent 自动处理 Carbon → MySQL datetime）

***

## 2. 问题排查：先看数据，不要猜

**原则：排查 bug 时用证据定位，禁止从报错文案反推去猜服务器/框架/环境。**

* 报错文案（如 405、404、500）只是表象，不代表根因。不要一上来就怀疑 nginx、路由匹配、CORS、框架核心、PHP 配置。

* 先确认代码实际执行到了哪一步、数据是什么：

  * 用 `var_dump`/日志打印关键变量（入参、查询结果、中间值），确认"走到了哪一步、数据长什么样"。

  * 直接查数据库，核对记录是否存在、字段值是否符合代码里的过滤条件。

  * 对比"正常接口"与"异常接口"的差异，而不是对比服务器配置。

* 不要被"间歇性成功/失败"误导。先想清楚两次操作的真实差异（如测试数据不同），再下结论。

* 不要为了排查去修改框架核心代码或加一堆诊断日志，除非已确认问题确实在框架层。

* 若排查方向连续多次无进展，停下来重新审视：是不是一开始的假设就错了？

**典型反例**：接口报 405，就反复排查路由定义、nginx 伪静态、CORS，甚至改框架源码。实际根因是控制器查询时多了一个状态过滤条件，把目标记录过滤掉了——只要查一下数据库、打印一下查询结果，一眼就能定位。

***

## 3. 应用独立仓库提交

**原则：调整** **`app/Apps/{AppName}/`** **下的应用后，若该目录存在** **`.git`（应用独立仓库），调整完成且测试通过后，必须在该应用目录内主动完成 git 提交。**

### 适用范围

* 适用于 `app/Apps/{AppName}/` 目录内存在 `.git` 的应用（如 `CmsproDemo`）

* 仅 `Versionmgr` 随框架仓库提交、无独立仓库；其余应用按本章流程在各自目录内独立建仓与提交

### 应用目录独立性原则

* `app/Apps/` 下各应用目录**彼此独立、与框架仓库独立**（框架仓库仅保留 `Versionmgr`，见第 4 章）

* 有远程仓库的应用按本章流程在应用目录内提交，推送由用户决定

* **无远程仓库的应用仅保留本地仓库**：已在本地 `git init` 建仓并完成初始提交，后续调整按本章流程在应用目录内提交，不配置远程、不自动推送

* 新建应用目录时，随首次交付一并 `git init -b master` 建仓并完成初始提交（提交信息 `chore({应用名小写}): 初始化应用本地仓库`）；敏感文件（`.env`）、运行产物（`*.exe`、`*.bak`、`*.tmp`）、虚拟环境（`venv/`）须先写入应用 `.gitignore` 再提交

### 提交流程（强制）

1. 应用调整完成、**应用级测试通过**、`doc/` 文档同步更新后，在**应用目录内**（而非项目根目录）执行 git 操作
   > **应用级测试**须在应用自身 `Tests` 目录单独执行，例如在 `code` 目录运行 `php artisan test app/Apps/CmsproDemo/Tests`。`php artisan test` 全量回归**仅用于系统框架**，不作为应用调整的通过依据
2. 先执行 `git status` / `git diff` 确认本次变更清单
3. `git add` 仅添加本次修改涉及的具体文件，**禁止** **`git add -A`** **/** **`git add .`**（避免带入无关文件）
4. 提交信息遵循 `chinese-commit-conventions` 规范（`type(scope): subject` 格式，scope 用应用名，如 `feat(demo): 新增项目标签筛选功能`），中文描述，聚焦"为什么改"
5. 提交后执行 `git status` 确认工作区干净、提交成功

### README.md 兜底创建（强制）

* 对存在 `.git` 的应用进行调整时，若应用根目录**缺少** **`README.md`**，必须在本次提交前自动创建

* 内容禁止臆造，须基于 `manifest.json`（id/name/version/依赖）与应用 `doc/` 文档实际信息生成，基本结构：

  1. 标题：`# {应用名称} 应用文档`
  2. 元信息：应用 ID、文档版本、应用版本、依赖（PHP/CmsPro 版本）
  3. 官方地址：固定为 `https://www.cmspro.cn/apps/{应用ID}`（如应用 ID 为 `cmspro.demo`，则官方地址为 `https://www.cmspro.cn/apps/cmspro.demo`）
  4. 应用概述（核心功能与业务闭环）
  5. 目录结构（实际目录树 + 职责注释）
  6. 指向 `doc/` 下三类文档的引用（如已交付）

* 参考样例：`code/app/Apps/CmsproDemo/README.md`

### push 约束（强制）

* **禁止自动 push 到远程**：本地 commit 完成后，必须向用户询问是否推送到远程，由用户逐次决定

* 用户明确要求 push 时方可执行；push 失败（凭据、网络等）时如实报告，不得反复重试

### 违规示例

```
❌ 调整了 CmsproDemo 代码后不提交，工作区遗留未跟踪变更
❌ 在项目根目录执行 git 提交（应用有独立仓库时）
❌ git add -A 把 .env、临时文件等一并提交
❌ commit 后未经用户确认直接 git push
```

***

## 4. 框架级调整 Git 提交与推送策略

**原则：框架级调整（`app/Apps/`** **之外的框架代码与文档）完成后，必须在框架主仓库内完成提交；推送时双远程同步，禁止只推单边造成平台漂移。**

### 仓库定位

* 框架主仓库位于 `code` 目录（仓库根即 `code` 目录，**不是**项目根）

* 双远程配置（由使用者按团队实际仓库填写，已配置后禁止重复添加）：

  * `origin` → `<团队主上游仓库地址，如 gitee 私有仓库>`（默认上游）

  * `github` → `<团队备用远程仓库地址，如 github 私有仓库>`

> 原则：保持两个远程同步推送，禁止只推单边造成平台漂移（具体地址以团队实际配置为准，不内置在本包中）。

### 适用范围

* 框架级代码调整：`config/`、`routes/`、`app/`（非 `Apps/` 部分）、`resources/`、`public/`、`composer.json`、`tests/` 等——此类调整须先走第 0 章全局框架保护审批流程。其中 **`tests/` 目录存放的是系统框架级测试**（Unit / Feature），不属于任何应用；应用测试必须放在各自应用目录 `app/Apps/{AppName}/Tests/`（即 phpunit.xml 的 `Apps` 测试套件），**禁止**将应用测试放入 `tests/`

* 框架仓库内除应用目录外的文档、脚本等变更

* **`app/Apps/`** **下仅** **`Versionmgr`** **随框架仓库提交**（版本管理器与框架同体发布）；其余应用一律不入框架仓库——无论有无独立 `.git`，有 `.git` 的走第 3 章应用仓库流程，无 `.git` 的独立分发、后续按需建仓

### 提交流程（强制）

1. 变更完成、`php artisan test` 全量回归通过后，在 `code` 目录内执行 git 操作
   > **全量回归仅用于系统框架**（`tests/` 下的 Unit / Feature 测试）。框架级调整只需本步全量回归；若同时涉及应用调整，应用级测试须在应用自身 `Tests` 目录单独执行（见第 3 章），不在全量回归范围内一并带过
2. 先 `git status` / `git diff` 确认变更清单，甄别无关变更
3. `git add` 仅添加本次调整涉及的具体文件，**禁止** **`git add -A`** **/** **`git add .`**——特别注意 `app/Apps/` 下除 `Versionmgr` 外均已忽略，禁止强制添加（`git add -f`）
4. 提交信息遵循 `chinese-commit-conventions` 规范（`type(scope): subject` 格式，如 `feat(framework): ...`、`fix(pay): ...`），中文描述，聚焦"为什么改"
5. 提交后 `git status` 确认工作区干净

### 推送策略（强制）

* **禁止自动 push**：commit 完成后必须向用户询问是否推送，由用户逐次决定

* 用户同意推送后，**双远程同步推送**，保持 gitee 与 github 一致：

  1. `git push origin master`
  2. `git push github master`

* 除 master 外的本地分支（如 worktree 检出的 `feat/*` 分支）不自动推送；用户要求同步时，确认分支清单后逐一推送双远程

* push 失败（凭据、网络等）时如实报告，不得反复重试

### 排除目录（强制）

* `app/Apps/*` 已在 `.gitignore` 排除并取消跟踪，仅 `!/app/Apps/Versionmgr/` 重新包含（白名单模式），**禁止提交其他应用、禁止解除忽略、禁止** **`git add -f`** **强推**

* `public/apps/` 为应用安装/升级时自动生成的资源副本（构建产物），已在 `.gitignore` 中排除并取消 git 跟踪，**禁止提交、禁止解除忽略**

* 同类运行产物目录（`/public/Uploads/*`、`/storage/app_packages/` 等）均遵循 `.gitignore` 既有规则，不得纳入版本控制

### 违规示例

```
❌ 框架调整后只在 gitee 推送，遗漏 github（或反之），造成双平台代码漂移
❌ 在项目根执行框架仓库的 git 操作（主仓库在 code 目录）
❌ 把 app/Apps/ 下 Versionmgr 之外的应用（含 CmsproDemo、CmsproAiproxy、CmsproRabbitmath 等独立仓库应用）提交进框架仓库
❌ 把 public/apps/ 下的应用生成资源提交进框架仓库
❌ commit 后未经用户确认直接 git push
```

### 应用测试落点与校验（强制）

**原则：测试「测试什么代码」决定「放在哪里」。凡是直接测试 `app/Apps/{AppName}/` 下应用代码的测试，一律归属该应用；只有测试框架代码（`app/` 中非 `Apps/` 部分、`config/`、`routes/`、系统服务等）的测试才属于框架 `tests/`。**

#### 归属判定

* **应用测试** → 放 `app/Apps/{AppName}/Tests/`（phpunit.xml 的 `Apps` 套件），随该应用独立仓库提交
  * 判定：`use`/`new`/`assert` 涉及的对象来自 `App\Apps\{AppName}\` 命名空间，或以 `Tests\Unit\CmsproXxx`、`Tests\Apps\CmsproXxx` 等老头部 namespace 命名的既有应用测试，均属应用测试
* **框架测试** → 放 `tests/Unit` 或 `tests/Feature`（及其合法子目录 `Helpers`/`Services`/`Versionmgr`），`namespace Tests\Unit` / `Tests\Feature`
  * 判定：测试的是框架级代码；**Versionmgr 随框架提交，其测试保留在 `tests/Unit/Versionmgr`，不迁移**

#### 自查命令（强制）

新增或调整测试后，用以下命令扫描，`tests/` 下出现任何应用归属文件即为违规：

```bash
# 列出 tests/ 下所有疑似应用测试（落点不符规则的存量/新增文件）
git ls-files "tests/*" | grep -iE "tests/(Unit|Feature|Apps)/Cmspro" || true

# 更精确：目录级核对——框架 tests/ 下仅允许 Unit/Feature 直属、Unit/Helpers、Unit/Services、Unit/Versionmgr
```

#### 自检失败口径

* `php artisan test` 运行时，应用测试必须出现在 `Apps` 套件徽标下；若出现在 `Unit`/`Feature` 徽标下，说明落点错误
* 执行全量回归前，先跑上述扫描命令确认 `tests/` 无应用归属文件，再运行 `php artisan test`
* 发现存量违规：就近迁移至对应 `app/Apps/{AppName}/Tests/`（如需新建 Tests 目录，参照已迁移应用的命名空间与 autoload），并在该应用独立仓库内提交，禁止长期滞留框架 `tests/`

#### 机器强制校验（强制）

框架仓库内置守卫脚本 `code/guard-app-tests.php`，并已接入 `composer.json` 的 `scripts.test`：执行 `composer test`（含 `php artisan test` 全量回归）前，会先用机械特征扫描 `tests/Unit` 与 `tests/Feature`，发现任何目录段以 `Cmspro` 开头的文件即以非 0 退出码中断，防止应用测试误入框架。

```bash
composer test
```

机器强制的意义：不依赖开发者自觉跑手动自查命令，一旦 `tests/` 出现应用归属文件，全量回归直接失败，倒逼就地迁移。守卫使用路径段机械特征（与命名空间解析无关），不放过漏跑自查的场景；若确有合法的框架级例外（非应用测试亦以 `Cmspro` 命名），须先说明理由并调整守卫，禁止临时绕过。

> **全量回归口径**：`composer test` 会连带运行 `Apps` 套件（`app/Apps/*/Tests`，框架外的应用测试）。如需「仅框架」回归，用 `php artisan test --testsuite=Unit --testsuite=Feature`；日常全量可用 `composer test`。

***

## 5. 文件编码规范

**原则：所有代码与模板文件必须以「UTF-8 无 BOM」格式保存，禁止使用带 BOM 的 UTF-8。**

### 问题背景

UTF-8 BOM（字节顺序标记，字节 `EF BB BF`，显示为 `﻿` / U+FEFF）位于文件首字节时：

* PHP/Blade 渲染会将 BOM 原样输出到 HTTP 响应最前面，导致页面顶部出现一条空白条
* 影响响应头发送（BOM 输出后 headers 已发送，可能导致 `Cannot modify header information` 警告）
* JSON 接口响应首字符非 `{`/`[` 时可能导致前端解析失败

### 保存要求

* 新建或编辑任何 `.php`、`.blade.php`、`.js`、`.css`、`.json` 文件时，保存格式必须为「UTF-8 无 BOM」
* Windows 下部分编辑器（如记事本）默认「UTF-8」保存带 BOM，须另存为「UTF-8 无 BOM」；IDE 中确认编码设置为「UTF-8（无 BOM）」

### 排查方法

* 页面顶部出现空白条：查看网页源代码首行，若出现 `﻿` 字符（U+FEFF）即为 BOM 输出
* 批量检测：读取文件首三字节，为 `0xEF 0xBB 0xBF` 即带 BOM（PowerShell 示例：`[System.IO.File]::ReadAllBytes($path)[0..2]`）
* 处理方式：去除文件头部 BOM 三字节后重新保存，并全目录扫描确认无残留

### 违规示例

```
❌ 用记事本等默认带 BOM 的编辑器保存模板文件
❌ 页面顶部出现空白条时盲目调整 CSS/布局，而不先检查文件编码
❌ 只修复单个文件，不扫描同目录其他文件是否同样带 BOM
```

