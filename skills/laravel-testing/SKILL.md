---
name: "laravel-testing"
description: "CMSPRO 系统 Laravel 测试技能。涵盖单元测试、功能测试、API 测试、数据库测试、认证测试等内置方案与最佳实践。当需要为 CMSPRO 应用编写测试、验证接口/业务逻辑、替代 curl 手工测试时调用。"
---

# Laravel 测试技能（CMSPRO 专用）

针对 CMSPRO 系统的开发测试工作，**优先采用 Laravel 框架内置的测试方案与工具**，禁止使用 `curl.exe` + cookie 文件 + 手工抓 CSRF token 等方式进行接口测试。

## 〇、规则引导（最高优先级，执行本技能前必须加载）

本技能运行于 CMSPRO 工作区，执行任何动作前必须先读取并全程遵循以下三份规则文件：

| 规则文件 | 核心约束 |
|----------|----------|
| `rules/01-CMSPRO开发规范.md` | ① 全局框架保护：禁改 `vendor/`、`config/`、`routes/` 等全局代码，扩展一律走 `app/Apps/{AppName}/`；② 动手前必读开发文档与应用自身 `doc/` 文档；③ 应用调整后必须用 Laravel 内置测试验证、必须同步更新应用文档；④ 日期时间统一 `Y-m-d H:i:s`，禁止 ISO 8601；⑤ 排查问题先看数据（var_dump/查库），禁止从报错文案反推猜测 |
| `rules/02-CMSPRO协作总则.md` | ① 全程中文思考与回复；② 收到任务先检查匹配技能；③ 设计先于编码（brainstorming）；④ 测试先于实现（TDD）；⑤ 验证先于完成 |
| `rules/03-通用编码准则.md` | ① 编码前先思考：列明假设、主动澄清，不臆测业务；② 优先简洁：不做需求之外的抽象与配置；③ 精准修改：每行改动对应需求，不碰无关代码；④ 目标驱动：任务转化为可验证目标，循环验证至达标 |

> 冲突处理：本技能流程与上述规则冲突时，以规则为准；规则未覆盖的场景按本技能流程执行。

## 一、为什么用 Laravel 内置测试

| 对比项 | curl 手工测试 | Laravel 内置测试 |
|--------|--------------|-----------------|
| 会话维护 | 手工 cookie 文件 | 框架自动维护 |
| CSRF | 手工抓 token | 测试自动处理 |
| 数据隔离 | 污染真实库 | sqlite :memory: 隔离 |
| 断言 | 肉眼比对 | 结构化断言 |
| 可重复 | 差 | 一键回归 |
| 端口 | 需带端口（违规） | 无需真实 HTTP |

> **规范**：CMSPRO.md 明确禁止「域名 + 端口」访问（如 `http://<开发环境地址>:8000`）。Laravel 测试在内存中模拟 HTTP 请求，天然规避此问题。

## 二、项目测试环境

- **框架**：Laravel 13.8（`laravel/framework: ^13.8`）
- **测试框架**：PHPUnit 12.5（`phpunit/phpunit: ^12.5.12`）
- **测试配置**：`code/phpunit.xml`（位于框架主仓库 `code` 目录）
  - 数据库：`sqlite :memory:`（内存库，测试后自动销毁）
  - 缓存：`array`；会话：`array`；队列：`sync`；邮件：`array`
- **测试套件**（三个）：
  - `Unit` → `tests/Unit`
  - `Feature` → `tests/Feature`
  - `Apps` → `app/Apps/*/Tests`（**应用级测试放这里**）

### 运行测试命令

```powershell
# 在 code 目录下执行
php artisan test                          # 运行全部测试（仅用于系统框架回归）
php artisan test --filter=AuthLoginTest   # 运行指定测试类
php artisan test --filter=test_login      # 运行指定方法
php artisan test tests/Feature/UserTest   # 运行指定文件
php artisan test --testsuite=Apps         # 只跑应用级测试
php artisan test app/Apps/CmsproDemo/Tests   # 只跑指定应用的应用级测试（推荐）
```

> **重要**：`php artisan test` 全量回归（`tests/` 下的 Unit / Feature）**仅用于系统框架回归**。应用调整验证时，**必须**在应用自身 `Tests` 目录单独执行，例如 `php artisan test app/Apps/CmsproDemo/Tests`，不作为全量回归的附属一并带过。

## 三、测试目录结构规范

### 应用级测试（推荐）

每个应用在自身目录下建 `Tests` 目录，与 `Controllers`、`Services` 平级：

```
app/Apps/CmsproSso/
├── Controllers/
├── Services/
├── Tests/
│   ├── Unit/
│   │   └── Services/
│   │       └── SettingServiceTest.php
│   └── Feature/
│       └── AuthLoginTest.php
```

命名空间：`App\Apps\CmsproSso\Tests\Feature\...`

### 系统级测试

```
tests/
├── Unit/
└── Feature/
```

命名空间：`Tests\Unit\...`、`Tests\Feature\...`

## 四、测试基类

### 系统级基类

继承 `Tests\TestCase`（`code/tests/TestCase.php`）：

```php
<?php

namespace Tests\Feature;

use Tests\TestCase;

class UserTest extends TestCase
{
    // ...
}
```

### 应用级基类

应用级测试同样继承 `Tests\TestCase`（框架自动加载 `Tests\` 命名空间）：

```php
<?php

namespace App\Apps\CmsproSso\Tests\Feature;

use Tests\TestCase;

class AuthLoginTest extends TestCase
{
    // ...
}
```

## 五、测试类型详解

### 1. 单元测试（Unit Test）

**定位**：测试单个类/方法，不涉及 HTTP、数据库、框架容器。适合 Service、Helper、纯逻辑。

**位置**：`tests/Unit` 或 `app/Apps/*/Tests/Unit`

```php
<?php

namespace App\Apps\CmsproSso\Tests\Unit\Services;

use App\Apps\CmsproSso\Services\ShareService;
use PHPUnit\Framework\TestCase;

class ShareServiceTest extends TestCase
{
    public function test_front_url_拼接正确(): void
    {
        $url = ShareService::frontUrl('/login');
        $this->assertStringContainsString('/login', $url);
    }
}
```

> **注意**：纯单元测试继承 `PHPUnit\Framework\TestCase`（不启动 Laravel 容器）。若需访问框架（DB、Auth、Cache），改用功能测试或继承 `Tests\TestCase`。

### 2. 功能测试（Feature Test）

**定位**：模拟完整 HTTP 请求，验证「请求 → 路由 → 控制器 → 响应」整条链路。**最常用**。

**位置**：`tests/Feature` 或 `app/Apps/*/Tests/Feature`

```php
<?php

namespace App\Apps\CmsproSso\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthLoginTest extends TestCase
{
    use RefreshDatabase; // 每个测试后回滚数据库

    public function test_账号密码登录成功(): void
    {
        $user = User::create([
            'username' => 'test',
            'password' => bcrypt('123456'),
            'nickname' => '测试',
            'status'   => 1,
        ]);

        $response = $this->postJson('/api/cmspro/sso/auth/login', [
            'account'  => 'test',
            'password' => '123456',
        ]);

        $response->assertOk()
                 ->assertJson(['code' => 0])
                 ->assertJsonPath('data.redirect', '/');
    }
}
```

### 3. API 测试（API Test）

**定位**：针对 JSON 接口，使用 `postJson/getJson/putJson/deleteJson` 等方法，配合 JSON 断言。

**常用方法**：

```php
// 发送 JSON 请求
$this->postJson('/api/xxx', ['key' => 'value']);
$this->getJson('/api/xxx');
$this->putJson('/api/xxx', [...]);
$this->deleteJson('/api/xxx');

// 断言状态码
$response->assertOk();                    // 200
$response->assertStatus(201);             // 自定义
$response->assertUnauthorized();          // 401
$response->assertForbidden();             // 403
$response->assertNotFound();              // 404
$response->assertUnprocessable();         // 422 校验失败

// 断言 JSON 结构
$response->assertJson(['code' => 0]);
$response->assertJsonPath('data.user.id', 1);
$response->assertJsonCount(3, 'data.list');
$response->assertJsonMissing(['code' => 500]);

// 断言响应头
$response->assertHeader('Content-Type', 'application/json');
```

### 4. 数据库测试（Database Test）

**核心 Trait**：

| Trait | 作用 |
|-------|------|
| `RefreshDatabase` | 每个测试后迁移回滚，保证隔离（推荐） |
| `DatabaseTransactions` | 用事务包裹，测试结束回滚（更快，但依赖事务） |
| `DatabaseMigrations` | 每次测试前重新迁移（最慢） |

```php
use Illuminate\Foundation\Testing\RefreshDatabase;

class OrderTest extends TestCase
{
    use RefreshDatabase;

    public function test_创建订单写入数据库(): void
    {
        $this->postJson('/api/orders', ['amount' => 100]);

        $this->assertDatabaseHas('orders', ['amount' => 100]);
        $this->assertDatabaseCount('orders', 1);
        $this->assertDatabaseMissing('orders', ['amount' => 999]);
    }
}
```

### 5. 认证测试（Authentication Test）

**模拟登录用户**：

```php
use App\Models\User;

// 方式一：actingAs 指定 guard
$user = User::factory()->create();
$this->actingAs($user, 'web')
     ->getJson('/api/cmspro/sso/user/info')
     ->assertOk();

// 方式二：Sanctum 令牌认证
$this->actingAs($user, 'sanctum')
     ->getJson('/api/protected');
```

**测试未登录拦截**：

```php
public function test_未登录访问受保护接口返回401(): void
{
    $this->getJson('/api/cmspro/sso/user/info')
         ->assertUnauthorized();
}
```

### 6. 表单校验测试（Validation Test）

```php
public function test_密码过短校验失败(): void
{
    $this->postJson('/api/cmspro/sso/auth/login', [
        'account'  => 'test',
        'password' => '123',   // 少于6位
    ])->assertUnprocessable()
      ->assertJsonValidationErrors('password');
}
```

### 7. 视图测试（View Test）

```php
public function test_登录页渲染(): void
{
    $this->get('/sso/login')
         ->assertOk()
         ->assertSee('统一登录')
         ->assertViewHas('title');
}
```

### 8. 异常与边界测试

```php
public function test_账号锁定逻辑(): void
{
    // 连续失败 5 次触发锁定
    for ($i = 0; $i < 5; $i++) {
        $this->postJson('/api/cmspro/sso/auth/login', [
            'account'  => 'test',
            'password' => 'wrong',
        ]);
    }

    $this->postJson('/api/cmspro/sso/auth/login', [
        'account'  => 'test',
        'password' => 'wrong',
    ])->assertStatus(429); // 已锁定
}
```

## 六、常用断言速查

### 响应断言

| 断言 | 说明 |
|------|------|
| `assertOk()` | 200 |
| `assertCreated()` | 201 |
| `assertNoContent()` | 204 |
| `assertRedirect($uri)` | 重定向 |
| `assertSessionHasErrors('field')` | 会话校验错误 |
| `assertSessionHas('key')` | 会话数据 |

### JSON 断言

| 断言 | 说明 |
|------|------|
| `assertJson($array)` | 包含指定 JSON 片段 |
| `assertJsonPath($path, $value)` | 指定路径值 |
| `assertJsonCount($n, $key)` | 数组元素个数 |
| `assertJsonStructure([...])` | 结构校验 |
| `assertJsonMissing($array)` | 不包含 |
| `assertJsonValidationErrors($field)` | 校验错误字段 |

### 数据库断言

| 断言 | 说明 |
|------|------|
| `assertDatabaseHas($table, $data)` | 记录存在 |
| `assertDatabaseMissing($table, $data)` | 记录不存在 |
| `assertDatabaseCount($table, $n)` | 记录数量 |
| `assertSoftDeleted($table, $data)` | 软删除 |

## 七、CMSPRO 项目最佳实践

### 1. 应用级测试放应用目录

应用测试放在 `app/Apps/{AppName}/Tests/`，随应用一起打包分发，命名空间 `App\Apps\{AppName}\Tests\...`。

**回归执行方式**：框架级调整跑 `php artisan test` 全量回归；应用调整必须在应用自身 `Tests` 目录单独执行（`php artisan test app/Apps/{AppName}/Tests`），全量回归不作为应用调整的通过依据。

### 2. 测试数据用 Factory 或直接创建

项目未配置 Factory 时，直接用 `Model::create()` 构造数据：

```php
$user = User::create([
    'username' => 'test_' . uniqid(),
    'password' => bcrypt('123456'),
    'status'   => 1,
]);
```

### 3. 遵循 CMSPRO 日期规范

测试断言日期时，遵循「数据库直接读取输出」规范，使用 `Y-m-d H:i:s` 格式，不要断言 ISO 8601 格式。

### 4. 微信/第三方依赖用 Mock

微信授权等外部依赖，用 Mockery 或 `Http::fake()` 模拟，避免真实调用：

```php
use Illuminate\Support\Facades\Http;

Http::fake([
    'api.weixin.qq.com/*' => Http::response(['openid' => 'test_openid'], 200),
]);

$response = $this->get('/sso/auth/wechat/callback?code=xxx&state=yyy');
```

### 5. 测试命名规范

- 方法名用中文或英文均可，但需语义清晰：`test_账号密码登录成功`
- 一个测试方法只验证一个行为
- 使用 `@test` 注解或 `test_` 前缀均可

### 6. 禁止事项

- ❌ 禁止用 `curl.exe` + cookie 文件做接口测试
- ❌ 禁止用「域名 + 端口」访问测试
- ❌ 禁止测试污染真实数据库（必须用 `RefreshDatabase` 或内存库）
- ❌ 禁止在测试中硬编码真实密钥/密码

## 八、完整示例：SSO 登录测试

```php
<?php

namespace App\Apps\CmsproSso\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthLoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_账号密码登录成功(): void
    {
        User::create([
            'username' => 'test',
            'password' => bcrypt('123456'),
            'nickname' => '测试',
            'status'   => 1,
        ]);

        $this->postJson('/api/cmspro/sso/auth/login', [
            'account'  => 'test',
            'password' => '123456',
        ])->assertOk()
          ->assertJson(['code' => 0]);
    }

    public function test_密码错误返回400(): void
    {
        User::create([
            'username' => 'test',
            'password' => bcrypt('123456'),
            'status'   => 1,
        ]);

        $this->postJson('/api/cmspro/sso/auth/login', [
            'account'  => 'test',
            'password' => 'wrong',
        ])->assertStatus(400)
          ->assertJson(['code' => 400]);
    }

    public function test_登录后访问受保护页面(): void
    {
        $user = User::create([
            'username' => 'test',
            'password' => bcrypt('123456'),
            'status'   => 1,
        ]);

        $this->actingAs($user, 'web')
             ->get('/sso/home')
             ->assertOk();
    }

    public function test_未登录访问受保护页面被拦截(): void
    {
        $this->get('/sso/home')->assertRedirect();
    }
}
```

## 九、日常维护测试用例模板（可直接复制）

> 日常开发与维护时，直接复制以下模板到 `app/Apps/{AppName}/Tests/Feature/` 下，按实际业务修改即可。**所有用例均继承 `Tests\TestCase` 并使用 `RefreshDatabase`，符合 CMSPRO 规范。**

### 9.1 通用 CRUD 接口测试模板

覆盖「列表 / 详情 / 新增 / 更新 / 删除」五类接口的完整测试，含权限拦截与校验失败场景：

```php
<?php

namespace App\Apps\{AppName}\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class {Entity}ApiTest extends TestCase
{
    use RefreshDatabase;

    // 构造一个已登录的管理员/用户
    protected function actingUser(): User
    {
        return User::create([
            'username' => 'test_' . uniqid(),
            'password' => bcrypt('123456'),
            'nickname' => '测试',
            'status'   => 1,
        ]);
    }

    public function test_列表接口返回数据(): void
    {
        $this->actingAs($this->actingUser(), 'web')
             ->getJson('/api/{appId}/{entity}')
             ->assertOk()
             ->assertJson(['code' => 0]);
    }

    public function test_详情接口返回指定记录(): void
    {
        $id = 1; // 按实际业务构造记录
        $this->actingAs($this->actingUser(), 'web')
             ->getJson("/api/{appId}/{entity}/{$id}")
             ->assertOk()
             ->assertJsonPath('code', 0);
    }

    public function test_新增接口成功(): void
    {
        $this->actingAs($this->actingUser(), 'web')
             ->postJson('/api/{appId}/{entity}', [
                 'name'  => '测试数据',
                 'status' => 1,
             ])
             ->assertOk()
             ->assertJson(['code' => 0]);
    }

    public function test_新增接口必填校验失败(): void
    {
        $this->actingAs($this->actingUser(), 'web')
             ->postJson('/api/{appId}/{entity}', [])
             ->assertUnprocessable()
             ->assertJsonValidationErrors('name');
    }

    public function test_更新接口成功(): void
    {
        $id = 1;
        $this->actingAs($this->actingUser(), 'web')
             ->putJson("/api/{appId}/{entity}/{$id}", ['name' => '更新后'])
             ->assertOk()
             ->assertJson(['code' => 0]);
    }

    public function test_删除接口成功(): void
    {
        $id = 1;
        $this->actingAs($this->actingUser(), 'web')
             ->deleteJson("/api/{appId}/{entity}/{$id}")
             ->assertOk()
             ->assertJson(['code' => 0]);
    }

    public function test_未登录访问被拦截(): void
    {
        $this->getJson('/api/{appId}/{entity}')
             ->assertUnauthorized();
    }
}
```

### 9.2 业务逻辑测试模板（Service 层）

针对 Service 层核心业务逻辑，验证事务、状态流转、边界值：

```php
<?php

namespace App\Apps\{AppName}\Tests\Feature;

use App\Apps\{AppName}\Services\{Entity}Service;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class {Entity}ServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_正常业务流程(): void
    {
        $service = app({Entity}Service::class);

        $result = $service->create(['name' => '测试']);

        $this->assertTrue($result['success']);
        $this->assertDatabaseHas('app_{appId}_{entity}', ['name' => '测试']);
    }

    public function test_空值边界处理(): void
    {
        $service = app({Entity}Service::class);

        $result = $service->create([]);

        $this->assertFalse($result['success']);
        $this->assertArrayHasKey('message', $result);
    }

    public function test_状态流转正确(): void
    {
        $service = app({Entity}Service::class);

        $service->create(['name' => '测试', 'status' => 0]);
        $service->publish(1); // 按实际业务方法调整

        $this->assertDatabaseHas('app_{appId}_{entity}', ['id' => 1, 'status' => 1]);
    }
}
```

### 9.3 使用说明

1. 将 `{AppName}` 替换为应用目录名（如 `CmsproSso`）
2. 将 `{appId}` 替换为路由前缀（如 `cmspro/sso`）
3. 将 `{Entity}` 替换为业务实体名（如 `Order`）
4. 将 `{entity}` 替换为表名/资源名（如 `orders`）
5. 按实际业务调整请求参数、断言字段与状态码
6. 运行验证：`php artisan test --filter={Entity}ApiTest`

## 十、验证流程

1. 编写测试 → 运行 `php artisan test --filter=类名`
2. 确认测试通过（绿色）
3. 若测试失败，用 `systematic-debugging` 技能定位问题
4. 修复后重新运行，直到全部通过
5. 提交前回归：框架级调整运行 `php artisan test` 全量回归；应用级调整在应用自身 `Tests` 目录单独执行（`php artisan test app/Apps/{AppName}/Tests`），确认不影响原有功能
