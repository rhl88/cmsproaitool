# CMSPRO v5 · 应用开发常见问题

> 本文档汇总 CMSPRO v5 应用（`app/Apps/`）开发过程中遇到并已解决的典型问题，供后续开发与交接参考。每条记录含现象、根因、修复与验证。
>
> 定位：应用开发问题「案例库」，新增问题时请遵循本模板追加，保持结构一致。

***

## 1. 前端 `fetch` 调用应用 API 返回 302 重定向（参数校验失败陷阱）

### 1.1 现象

论坛 AI 助理（`CmsproForum_ai`）发帖页 `/create` 调用以下接口时，浏览器 DevTools 显示全部 **302 Found**，`Location` 指向当前发帖页 `/create`：

```
/api/forum-ai/assist/polish      （内容润色）
/api/forum-ai/assist/titles      （标题生成）
/api/forum-ai/assist/risk        （风险自检）
/api/forum-ai/assist/format      （格式排版）
/api/forum-ai/assist/similar     （相似推荐）
/api/forum-ai/moderation/precheck 等（治理接口）
```

- 响应头为 `text/html; charset=utf-8`，带 `Location: http://<host>/create`。

- 同一路由组下 `/api/forum-ai/assist/summary` 在帖子详情页 `/t/xxx` 却正常返回 **200 JSON**。

> 排查要点：302 与「能否匹配路由」「是否 CSRF」无关（响应头已带 `x-ratelimit-*`，说明请求已进入 Laravel 并按路由命中）。关键差异在请求 **是否命中校验失败分支**。

### 1.2 根因

302 由「参数校验失败 + 请求不被识别为 JSON」触发，具体链路：

1. **控制器强校验**：出问题的接口都用 `$request->validate(['content' => ['required', 'string']])` 等规则进行字段强校验。

   - 发帖页打开时内容为空，`content: ""` 不满足 `required` → 抛出 `ValidationException`。

   - `summary` 只校验 `topic_id`，你传入有效值 → 校验通过 → 正常返回 JSON 200，**因此不受影响**。

2. **前端请求头不满足 JSON 判断**：Laravel 只有 `$request->expectsJson()` 为 `true`（带 `Accept: application/json` 或 `X-Requested-With`）时，才把校验错误序列化为 JSON。

   - `_assistant.blade.php` 用原生 `fetch`，POST 头仅带 `Content-Type: application/json` 与 `X-CSRF-TOKEN`，默认 `Accept: */*`、无 `X-Requested-With`。

3. **fallback 到重定向**：`expectsJson() == false` 时，Laravel 的 `ValidationException` 处理器执行 `redirect()` 回上级页面（发帖页 `/create`）→ 浏览器收到 **302** 而非错误 JSON。

> 一句话：**前端** **`fetch`** **不带 JSON Accept 头 + 控制器** **`validate()`** **校验失败 →** **`ValidationException`** **被 Laravel 转成 302 重定向**，而不是 JSON 错误响应。

### 1.3 为何既有测试未拦截（盲区）

- Laravel 测试 `postJson()` / `getJson()` 自带 `Accept: application/json` → 永远走 JSON 分支，捕获不到 302。

- 以「未登录」为主的回归用例会先被 `requireLogin()` 拦截返回 401，根本到不了 `validate()` 校验步骤。

> 因此，针对「真实浏览器 `fetch`」的回归用例必须用普通 `$this->post()` + **已登录** + **校验失败载荷**来构造，而不是 `postJson()`。

### 1.4 修复方案（应用内，零框架改动）

在应用 API 路由组挂载一个「强制 JSON 响应」中间件，把请求 `Accept` 头强制为 `application/json`，使框架对校验错误统一返回 **422 JSON**，消除 302：

```php
namespace App\Apps\CmsproForum_ai\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class ForceJsonResponse
{
    public function handle(Request $request, Closure $next)
    {
        $request->headers->set('Accept', 'application/json');
        return $next($request);
    }
}
```

在 `ServiceProvider::registerRoutes()` 的每个 API 分组中间件数组中加入该中间件（置于 `web` / `throttle` 之间即可）：

```php
->middleware(['web', ForceJsonResponse::class, 'throttle:60,1'])
```

> CSRF 豁免（`withoutMiddleware(PreventRequestForgery::class)`）与本问题无关，无需改动；两者都保留可以覆盖「419→302」与「校验失败→302」两类跳转。

### 1.5 验证

新增针对性回归用例（对齐真实 `fetch` 形态）：

```php
public function test_format_empty_content_returns_json_not_redirect(): void
{
    $user = $this->createUser();
    $response = $this->actingAs($user)->post('/api/forum-ai/assist/format', ['content' => '']);

    $this->assertNotEquals(302, $response->getStatusCode());   // 非 302
    $this->assertNotEquals(3, intdiv($response->getStatusCode(), 100)); // 非任何 3xx
    $decoded = json_decode($response->getContent(), true);
    $this->assertIsArray($decoded);                             // 必须为 JSON
}
```

- 修复前：该用例对普通 `post()` 断言失败（实际返回 302）。

- 修复后：`Route302RegressionTest`（27 例）、`AssistAuthTest`（13 例）全部通过。

### 1.6 通用经验（新接口须遵循）

- 应用对外 API 若使用 `fetch` 前端，应通过「强制 JSON 中间件」保证 `expectsJson()` 恒为真，统一错误响应为 JSON。

- 控制器 `validate()` 校验失败时，接口应返回 `422 JSON`（`{code,message,data,timestamp}`），**绝不应该** **`302`** **跳转**。

- 写回归测试时，务必覆盖「已登录 + 空/非法载荷 + 普通 `POST`（不带 JSON Accept）」这一真实线上形态；仅靠 `postJson` 无法暴露该 302。

***

## 2. 命名空间与路径常见问题

当应用路由 404、或全站崩溃 500 时，优先核对应用目录命名空间、目录名与 `app_id_to_class_name()` 输出是否完全一致。

| 问题                        | 现象                                                      | 排查方法                                                                       | 解决方案                                          |
| ------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------------- | --------------------------------------------- |
| 目录名与 app\_id 大小写不一致       | 路由 404，`class_exists()` 返回 false                        | 检查 `AppServiceProvider::registerEnabledApps()` 日志，会输出 `CLASS_NOT_FOUND` 信息 | 目录重命名为 `ucfirst(app_id)` 的结果                  |
| 数据库 path 为绝对路径            | 路由加载报错 `require(): Failed to open stream`               | 查询 `SELECT id,app_id,path FROM apps WHERE app_id='xxx'`                    | 更新为相对路径 `app/Apps/{AppName}`                  |
| ServiceProvider 中硬编码了错误路径 | 路由加载报错文件不存在                                             | 检查 `ServiceProvider.php` 中 `base_path()` 参数                                | 改为正确的相对路径                                     |
| Windows 正常但 Linux 全站 500  | 全站 500，管理后台无法访问，错误日志 `require(): Failed to open stream` | 用 `php -r "echo app_id_to_class_name('你的app_id');"` 输出目录名，对比目录名与命名空间声明完全一致 | 将目录名、命名空间声明、ServiceProvider 中所有路径引用统一切换为同一大小写 |

**原则**：数据库中的路径字段一律存储**相对路径**，禁止绝对路径。读取时经 `AppPathHelper::appDir()` / `AppPathHelper::storage()` 解析；入库前用 `toAppDirRelative()` / `toStorageRelative()` 转换，换服务器后数据库无需再修改。

> **排查命令**：应用路由 404 时，可临时在 `AppServiceProvider::registerEnabledApps()` 中加日志输出 catch 异常，定位是「类找不到」还是「路径错误」；全站崩溃无法进入后台时，通过 SSH 或文件管理直接核对应用目录命名空间与目录名是否一致。

***

## 3. API 响应类命名空间常见错误

`ApiResponse` 类位于 `App\Http\Responses` 命名空间，**不是** `App\Services`：

| 错误命名空间                     | 正确命名空间                           |
| -------------------------- | -------------------------------- |
| `App\Services\ApiResponse` | `App\Http\Responses\ApiResponse` |

> AI 代码生成工具可能生成错误的命名空间，引入时需核对（否则会解析到错误的类而报错）。

**路由参数禁止** **`int`** **类型提示**：Laravel 从 URL 提取的路由参数始终为字符串，使用 `int` 类型提示会抛 `TypeError`：

```php
// ❌ 错误：Argument #1 ($id) must be of type int, string given
public function show(int $id) { ... }
```

***

## 4. API 数据验证：空字符串转 null 陷阱（强制）

**核心原则**：所有写操作接口（创建/更新）的必填字段必须先验证再入库；验证失败返回 `4xxxx` 业务错误码 + 字段级提示，**禁止把未校验的数据直接写库触发程序级异常（500）**。

**现象**：数据库 NOT NULL 列（仅设 default）被写入 null。

**根因**：Laravel 默认中间件 `ConvertEmptyStringsToNull` 会把请求中的**空字符串**自动转为 `null`。而 Eloquent **显式**写入 null 时绕过列默认值，直接触发完整性约束异常：

```
SQLSTATE[23000]: Integrity constraint violation: 1048
Column 'upstream_protocol' cannot be null
→ 未验证直达用户，变成 50001 服务器内部错误（500）
```

> 原理：`insert into t (col) values (null)` 显式出现的 null 不走列默认值；只有 SQL 中**省略**该列时 default 才生效。前端表单「未选择/留空」的合法场景（如跟随供应商、暂无标签）都会以空字符串提交，必然命中。

**解决方案**：

1. **Controller 层验证（首选）**：使用 `$request->validate([...])`，失败自动抛 `ValidationException`，框架统一转为 422 + 字段级错误。
2. **Service 层兜底验证**：同一 Service 方法被控制器、任务、钩子等多处调用时，Service 层必须自带验证，`trim((string)($data[$field] ?? '')) === ''` 即判缺失。
3. **空值规范化**：验证通过后、入库前，对「合法的空值」做规范化，避免 NOT NULL 列被写 null——无 default 字符串列回落 `''`；有 default（枚举类）/数值列空值时 `unset` 让 create 走默认值、update 保留原值。

> 局部更新语义：`update` 接口若支持 PATCH 式局部更新，只校验请求中出现的必填字段；字段出现时只看请求值（空=缺失），不得回落取库中旧值放行。

***

## 5. 数据库迁移常见错误

| 问题                                       | 原因                             | 解决                                                  |
| ---------------------------------------- | ------------------------------ | --------------------------------------------------- |
| `General error: 1 near "MODIFY"`         | SQLite 不支持 MODIFY COLUMN       | 用驱动判断跳过，或用 `change()`                               |
| `General error: 1 no such table`         | 测试环境缺少系统表迁移                    | 添加 `2026_05_28_000000_create_system_core_tables` 补建 |
| `General error: 1 near "SHOW"`           | 原生 `SHOW COLUMNS` 在 SQLite 不支持 | 改用 `Schema::hasColumn()`                            |
| `Base table or view already exists`      | 迁移前未检查表是否存在                    | 加 `Schema::hasTable()` 判断                           |
| `Unknown column 'xxx' in 'where clause'` | 迁移未在 MySQL 执行，代码已引用新字段         | 先 `php artisan migrate` 再访问                         |

***

## 6. 卸载后数据库表残留（Windows 回滚不执行）

**现象**：应用卸载后数据库表和旧数据残留，重装时 `Schema::hasTable()` 发现表已存在而跳过，旧数据原封不动保留。

**根因**：卸载流程的 `rollbackMigrations()` 使用 `Artisan::call('migrate:rollback')`，依赖 `migrations` 表记录与路径解析，在 Windows 等环境下可能因路径分隔符、大小写问题导致 `down()` 未执行。

**解决方案**：在 `uninstall()` 中增加迁移回滚兜底，直接 `require` 迁移文件并调用 `down()`，同时删除 `migrations` 表中的对应记录（系统后续再调 `migrate:rollback` 时因记录不存在而跳过，不冲突）。`down()` 必须使用 `Schema::dropIfExists()` 等幂等方法，保证重复调用不报错。

***

## 7. 迁移兜底机制（Windows 路径分隔符导致迁移未执行）

**现象**：安装应用后部分表/字段缺失。

**根因**：系统安装流程自动执行 `Migrations/` 目录下的迁移文件，但在某些环境（如 Windows 路径分隔符问题）下迁移可能未正确执行。

**解决方案**：在 `Install::install()` 中增加迁移兜底逻辑（`runMigrations()`），确保表一定被创建后再执行其他初始化逻辑。

***

## 8. group\_code 与 manifest 不一致导致唯一键冲突

**现象**：升级应用时失败，报唯一键冲突 `config_items_group_code_unique`，错误形如：

```
SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry
'20-app_cmspro_domainmanager_dns_provider_type' for key 'config_items_group_code_unique'
```

**根因**：应用自定义代码（如 `SettingsApiController`）直接写库 `config_items` 时，使用了与 `manifest.json` `config_groups[].name` 经前缀化后不一致的 group\_code，形成两套并存；再经 `updateOrCreate(['code'=>...], ['group_id'=>...])` 把已有记录改写到自己创建的 group，长期累积成脏数据后触发唯一键冲突。

**正确做法**：应用层保存配置时，group\_code 必须用 `app_{应用id}_{group_name}` 与 manifest 完全一致；或 `updateOrCreate` 同时以 `code + group_id` 作为匹配条件；写入前先清理其他 group 下相同 code 的历史残留。

> **踩坑提醒**：早期版本 `SettingController::update()` 直接写 `'group_id' => 0`，导致配置项脱离 manifest 声明的 group，升级时可能触发唯一键冲突。应通过 `resolveConfigGroupMap()` 查询 `config_groups` 表得到正确的 `group_id`。

***

## 9. 配置设置页常见问题

| 问题                                                                  | 原因                                                           | 解决                                                             |
| ------------------------------------------------------------------- | ------------------------------------------------------------ | -------------------------------------------------------------- |
| 保存后页面刷新值未变                                                          | 后端 `index()` 读取时未从 `ConfigItem` 取值，而是从 `config()` 取          | 确认 `index()` 优先查 `ConfigItem` 表                                |
| 开关保存为 `on` 字符串                                                      | 未单独收集开关字段，被 jQuery 序列化为 `on`                                 | 在 `switchFields` 中显式列出并用 `:checked` 转为 `'1'/'0'`               |
| 升级时报 `Duplicate entry ... for key 'config_items_group_code_unique'` | `update()` 写入时 group\_id 与 manifest 声明不一致，配置项被改写到非标准组        | `update()` 中通过 `resolveConfigGroupMap()` 取正确 group\_id，禁止写 `0` |
| 修改 `access_mode` 后路由不生效                                             | 未执行 `route:clear`                                            | `update()` 末尾调用 `Artisan::call('route:clear')`                 |
| AJAX 返回 419                                                         | 未配置 CSRF Token                                               | 在 `$.ajaxSetup` 注入 `X-CSRF-TOKEN: {{ csrf_token() }}`          |
| 设置页面无后台菜单入口                                                         | `manifest.json` 的 `menus` 未声明 `/admin/{app_id}/settings` 菜单项 | 在 `menus.children` 中添加设置菜单项并配 `code`                           |
| 数据库无配置记录时页面报错                                                       | 视图未对 `$configs['key']` 做空值兜底                                 | 使用 `$configs['key'] ?? '默认值'` 输出                               |

***

## 10. Blade 注释中 @verbatim 关键字导致 script 块被移除

**现象**：Layui 表格操作列按钮完全不显示，且没有任何 JS 报错。

**根因**：Blade 注释 `{{-- ... --}}` 中如果包含 `@verbatim` 字样，Blade 编译器扫描整个文件时会把它误认为是指令开始，与后续真正的 `@verbatim` / `@endverbatim` 匹配错位，导致整个 `<script type="text/html">` 块在编译时被**静默移除**。

```html
{{-- ❌ 错误：注释中包含 @verbatim 关键字, 会导致整个 script 块被移除 --}}
{{-- 操作列模板: 必须用 @verbatim 包裹 --}}
<script type="text/html" id="planBar"> @verbatim ... @endverbatim </script>
```

**解决方案**：Blade 注释中**禁止**出现 `@verbatim`、`@endverbatim`、`@section`、`@yield`、`@extends` 等任何 Blade 指令关键字。需要说明某段代码用了 `@verbatim` 时，注释中写中文「原样输出」「不解析」即可，不要写指令原文。

**排查方法**：操作列按钮不显示且无 JS 报错时，在 tinker 或临时脚本执行 `view('yourapp::Admin.xxx.index')->render()` 后 `strpos($html, 'id="yourBar"')`，返回 false 即说明模板被编译器移除。

***

## 11. 配置存储一致性：切换访问模式不生效

**现象**：后台将访问模式切换为「子域名」或「前端模式」并保存后，访问子域名/根路径仍是首页（path 模式），切换不生效。

**根因**：CmsPro 应用的配置可能同时存储在两处，而**路由注册读取的配置表**与**设置页写入的配置表**不一致：

| 存储    | 表                                     | 作用                                                                                                      |
| ----- | ------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| 框架配置表 | `config_items`（code 前缀 `app_{应用id}_`） | 安装时由 manifest `config_groups` 自动创建；`ServiceProvider::getConfigValue()` 从这里读取 `access_mode` 决定**路由注册方式** |
| 应用配置表 | `app_{应用id}_settings`（应用自定义）          | 设置页读写、运行时 `overrideConfigFromDatabase()` 覆盖 `config()`                                                  |

**解决方案**：设置页保存时必须**同步写入两个表**，保持两者一致（写 `app_{应用id}_settings` 的同时，将 `config_items` 中对应 `app_{应用id}_access_mode` 一并更新）；修改访问模式后执行 `php artisan route:clear && php artisan config:clear && php artisan cache:clear`。

> 附注：`frontUrl()` 等辅助函数读取 `config('apps.{appId}.access_mode')`，该值由 `overrideConfigFromDatabase()` 从应用配置表覆盖。若两表不一致，切换模式后路由变了但链接生成仍按旧模式。自测：切换每种模式后分别验证「路由注册」（`route:list`）、「页面访问」、「链接生成」（`frontUrl()` 输出）三项。

***

## 12. domain 绑定子域名下调用应用全局 API 返回 404（catch-all 拦截）

### 现象

论坛应用以子域名模式绑定 `bbs.cmspro.com` 后，论坛页面（个人设置安全 tab）调用统一登录应用的全局 API `/api/cmspro/sso/user/bindings` 返回 404：

```json
{"code":40401,"message":"请求的资源不存在","data":null,"timestamp":1788395325}
```

同一接口在主域名 `www.cmspro.com` 下正常命中（未登录时返回 401）。其他以 path 模式运行的应用全局 API 在任何 domain 绑定子域名下均会遇到同类问题。

### 根因

1. 框架 `AppServiceProvider::registerDomainRoutesEarly()` 为 domain 绑定子域名注册了 catch-all 路由（`Route::domain($domain)->any('{any}')` → `abort(404)`），拦截子域名下所有未放行的请求。
2. 应用 Provider 的 `boot()`（应用 API 路由在此注册）被框架延迟到 `booted` 阶段执行，注册时机上**晚于** catch-all（实测路由序号：catch-all 181 vs SSO API 1428）。
3. Laravel 按注册顺序匹配路由，子域名下 `api/cmspro/sso/*` 请求先被 catch-all 命中 → 404。主域名不受影响（catch-all 只绑定子域名）。

> 排查方法：`php artisan route:list --path=api/cmspro/sso` 确认路由已注册后，用运行时脚本模拟子域名请求并对比路由集合中 catch-all 与目标路由的注册顺序，即可实锤。

### 修复方案

catch-all 的约束正则改为负向前瞻，通用放行 `api/` 前缀（`app/Providers/AppServiceProvider.php`）：

```php
Route::domain($domain)
    ->middleware(['web'])
    ->any('{any}', function () {
        abort(404);
    })
    // 放行 api/ 前缀：应用全局 API 均以 api/ 注册且不带 domain 约束，
    // catch-all 只隔离子域名下的页面类请求，API 交由路由表自然匹配。
    ->where('any', '^(?!api/).*');
```

要点：这是**通用规则**而非单应用特例——各应用全局 API 均以 `api/` 为前缀且不带 domain 约束（本就全域名可访问），未匹配的 `api/` 路径仍由框架返回 404，无新增安全暴露面；以后新增应用的 API 无需再改框架。

### 验证

- 子域名 SSO 接口 → HTTP 401（命中路由，认证中间件正常工作）
- 子域名未匹配的 `api/not-exist` → HTTP 404（兜底不变）
- 子域名页面类请求 `/admin/login` → HTTP 404（隔离不变）
- 子域名应用首页 → HTTP 200；主域接口 → HTTP 401（不受影响）
- `php artisan test --testsuite=Apps` 全量回归通过

### 通用经验

- 应用全局 API 路由必须以 `api/` 为前缀注册且不加 domain 约束，即可在所有 domain 绑定子域名下被页面同源调用（框架 catch-all 已统一放行该前缀）。
- `SESSION_DOMAIN=.cmspro.com` 使主域与子域共享 session，页面 JS 用相对路径调用即可（CSRF token 与登录态天然一致），无需跨域处理。
- 切勿为单个应用在框架 catch-all 中硬编码放行前缀，保持通用规则的扩展性。

***

## 13. 后台列表分页参数名不匹配导致每页条数设置不生效

### 现象

后台列表页（如前台用户管理 `/admin/front-user`）的分页选项选择 **100 条/页**后，表格实际只显示 **15 条**；选择其他条数（10/20/50）同样不生效。数据总量超过 15 条的列表页均会触发。

### 根因

**前后端分页参数名不一致**，逐层证据：

1. **前端**：Layui `table.render` 分页请求默认发送的参数名是 `page` 和 `limit`，切 100 条/页时实际请求为：

   ```
   GET /api/admin/front-users?page=1&limit=100
   ```

2. **后端**：框架各 Service 统一读取的却是 `per_page` 参数，取不到时回退默认值 15：

   ```php
   // FrontUserService::index()
   $perPage = $params['per_page'] ?? config('cmspro.pagination.per_page', 15);
   $users = $query->orderBy('id', 'desc')->paginate($perPage);
   ```

3. **结果**：`per_page` 永远不存在于请求中 → 后端始终按默认 15 条返回 → 无论前端选多少条/页，列表最多只显示 15 条。

> 排查方法：打开浏览器 DevTools 的 Network 面板，切换每页条数后对比「请求实际发送的参数名」与「后端 Service 读取的参数名」即可实锤，无需猜测路由/中间件/框架层问题。

### 修复方案

前端声明 `request` 配置把 Layui 的 `limitName` 改为 `per_page`，与后端全部 Service（UserService、RoleService、ContentService、AttachmentService 等 10+ 处）的统一惯例对齐，后端零改动：

```js
table.render({
    elem: '#user-table',
    url: '/api/admin/front-users',
    request: { pageName: 'page', limitName: 'per_page' },   // 对齐后端 per_page 惯例
    page: {
        layout: ['count', 'prev', 'page', 'next', 'limit'],
        groups: 5,
        limit: 20,
        limits: [10, 20, 50, 100]
    },
    // ...
});
```

共修复 10 个后台列表视图（`resources/views/admin/` 下）：前台用户、用户管理、用户组、角色、内容、内容模型、附件、操作日志、应用日志、菜单终端。

> **例外**：`database/check`（数据表查看页）后端 `DatabaseController::check()` 读取的就是 `limit`，本就正常，**不在修改范围**——统一修复前必须逐个确认后端实际读取的参数名，避免把正常的改坏。

### 验证

1. **后端验证**（临时脚本，跑完即删）：直接调用 Service 传入 `per_page => 100`，断言返回条数与分页元信息：

   ```
   UserService: total=22 本页条数=22 分页per_page=100   （修复前本页只会返回 15 条）
   ```

2. **浏览器验证**：切 100 条/页后，Network 面板确认请求变为 `?page=1&per_page=100`，分页栏显示「共 N 条」且表格渲染完整。

3. **回归测试**：`php artisan test` 全量通过（存量无关失败经 `git stash` 前后对比确认与本次改动无关）。

### 通用经验

- **新增后台列表视图必须带** `request: { pageName: 'page', limitName: 'per_page' }` 配置，这是框架级强制约定；后端新增分页接口一律读 `per_page`，不得读 `limit`。
- 前端组件默认参数名与后端 API 约定不一致时，在**前端入口处统一声明映射**，而不是让后端逐个兼容两套参数名。
- 批量修复同类问题时，先全局确认各处后端实际读取的参数名（`rg "per_page|params\['limit'\]"`），把例外页排除，防止误伤。

***

## 追加模板

新问题追加时复制本节，填写即可：

```
## N. <问题名>

### 现象
<用户可见的现象，含 URL / 状态码 / 请求方法>

### 根因
<逐层定位，含证据；遵守「先看数据，不猜」原则>

### 修复方案
<应用内代码改动，说明改动位置与理由>

### 验证
<测试命令 + 用例名 + 预期结果>

### 通用经验
<提炼出的可复用规则>
```

