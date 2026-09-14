# CmsPro 应用开发文档

> 版本：1.9 | 更新日期：2026-08-24
> 适用系统：CmsPro v5.0.0+

***

## 一、概述

CmsPro 应用系统允许开发者创建独立的功能插件，通过标准化的安装/卸载流程集成到 CmsPro 系统中。每个应用在隔离目录中运行，支持完全无污染的安装与卸载。

### 核心特性

- **目录隔离**：应用文件全部位于 `app/Apps/{AppName}/` 目录
- **命名空间隔离**：每个应用使用 `App\Apps\{AppName}\` 命名空间
- **数据库隔离**：应用表使用 `app_{app_id}_` 前缀
- **视图隔离**：应用视图使用命名空间前缀访问
- **配置隔离**：应用配置通过 `apps.{app_id}` 键访问
- **钩子系统**：支持 Action 和 Filter 两种钩子类型
- **版本管理**：支持语义化版本号和增量升级
- **文档同步**：每个应用根目录包含 `doc/` 目录存放应用文档，应用调整时必须同步更新对应文档


***

## 二、快速开始

### 创建应用目录

```
code/app/Apps/Blog/
├── manifest.json
├── icon.svg               # 应用图标（推荐 SVG 格式）
├── ServiceProvider.php
├── Hooks.php              # 可选
├── Install.php            # 可选
├── Routes/
│   └── web.php
├── Controllers/
│   └── PostController.php
├── Models/
│   └── Post.php
├── Services/
│   └── PostService.php
├── Migrations/
│   └── 2026_05_22_000001_create_app_blog_posts_table.php
├── Views/
│   └── index.blade.php
├── Config/
│   └── blog.php
├── Assets/
│   ├── css/
│   └── js/
├── Tests/                     # 应用测试用例（必须放应用目录，禁止放框架 tests/）
│   └── AiChatServiceTest.php
└── doc/                      # 应用文档（详见「应用文档规范」章节）
    └── CmsPro-博客应用使用指南.md
```

**测试存放规范（强制）：** 应用的测试用例必须放在应用目录 `Tests/` 下（命名空间 `App\Apps\{AppName}\Tests`，与 `app/Apps/{AppName}/Tests/` 的 PSR-4 目录一一对应），**禁止**放在框架主仓库 `tests/` 目录。`phpunit.xml` 已配置 `Apps` 测试套件自动扫描 `app/Apps/*/Tests`，执行 `php artisan test app/Apps/{AppName}/Tests`（或 `--testsuite=Apps`）即可运行。`Tests/` 属开发期产物，打包分发时必须通过 `.exportignore` 排除。

### 最小化应用

一个最简单的应用只需要两个文件：

**manifest.json**

```json
{
    "id": "helloworld.hello",
    "name": "你好世界",
    "description": "示例应用",
    "version": "1.0.0",
    "author": "Developer",
    "require": {
        "php": ">=8.3",
        "cmspro": ">=5.0.0"
    },
    "providers": ["ServiceProvider"]
}
```

**ServiceProvider.php**

```php
<?php

namespace App\Apps\Hello;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider as BaseServiceProvider;

class ServiceProvider extends BaseServiceProvider
{
    public function boot(): void
    {
        $this->registerRoutes();
        $this->loadViews();
    }

    protected function registerRoutes(): void
    {
        Route::prefix('admin/hello')
            ->namespace('App\Apps\Hello\Controllers')
            ->middleware(['auth:admin'])
            ->group(base_path('app/Apps/Hello/Routes/web.php'));
    }

    protected function loadViews(): void
    {
        $this->loadViewsFrom(
            base_path('app/Apps/Hello/Views'),
            'hello'
        );
    }
}
```

***

## 三、manifest.json 规范

`manifest.json` 是应用的唯一标识和声明文件，必须放在应用根目录。

### 完整字段

```json
{
    "id": "cmspro.blog",
    "name": "博客",
    "description": "博客应用，支持文章发布、分类、标签管理",
    "version": "1.0.0",
    "author": "CmsPro",
    "author_url": "https://example.com",
    "icon": "fa fa-book",
    "require": {
        "php": ">=8.1",
        "cmspro": ">=5.0.0"
    },
    "dependencies": {
        "app_ids": [],
        "versions": {}
    },
    "providers": ["ServiceProvider"],
    "hooks": "Hooks",
    "install": "Install",
    "menus": [],
    "config_groups": [],
    "permissions": [],
    "runtime_files": []
}
```

### 字段说明

| 字段             | 类型     | 必填 | 说明                                           |
| -------------- | ------ | -- | -------------------------------------------- |
| id             | string | 是  | 应用唯一标识，**必须**采用 `开发者唯一标识.应用标识` 格式（如 `cmspro.blog`），详见「应用命名规范」章节 |
| name           | string | 是  | 应用显示名称                                       |
| description    | string | 是  | 应用描述                                         |
| version        | string | 是  | 语义化版本号（如 1.0.0）                              |
| author         | string | 是  | 作者                                           |
| author\_url    | string | 否  | 作者主页                                         |
| icon           | string | 否  | 应用图标，支持三种格式：FontAwesome 类名（如 `fa fa-book`）、Layui 图标类名（如 `layui-icon layui-icon-app`）、图片 URL。优先使用应用目录下的 `icon.svg` 或 `icon.png` 文件展示 |
| require        | object | 是  | 系统要求，支持 `php` 和 `cmspro` 两个键                 |
| dependencies   | object | 否  | 依赖的其他应用，`app_ids` 为依赖应用ID数组，`versions` 为版本约束。依赖应用必须已安装**且已启用**，否则安装将被拒绝 |
| providers      | array  | 是  | ServiceProvider 类名数组                         |
| hooks          | string | 否  | Hooks 类名                                     |
| install        | string | 否  | Install 类名（默认为 `Install`）                    |
| menus          | array  | 否  | 声明的菜单结构                                      |
| config\_groups | array  | 否  | 声明的配置组（系统自动添加应用前缀，详见第十四章）                    |
| permissions    | array  | 否  | 声明的权限列表，支持对象格式（推荐）或字符串格式（兼容）                 |
| home\_routes   | object | 否  | 前台路由占用声明，键为路由路径，值为路由中文名称。用于安装/启用时检测路由冲突       |
| runtime\_files | array  | 否  | 声明的运行时技术文件目录及清理策略（豁免附件规范的目录），详见第六章【运行时文件存储规范（豁免）】 |

### 版本约束格式

```
">=8.3"      大于等于
">5.0.0"     大于
"<=2.0.0"    小于等于
"<2.0.0"     小于
"1.0.0"      精确匹配（等同于 >=1.0.0）
```

### 应用图标

应用图标在管理后台的应用列表中展示，支持以下方式（按优先级从高到低）：

1. **图标文件**（推荐）：在应用根目录放置 `icon.svg` 或 `icon.png` 文件，系统通过 `/api/app/{appId}/icon` 接口自动提供图标访问。SVG 优先于 PNG。
2. **FontAwesome 类名**：在 `manifest.json` 的 `icon` 字段中使用 FontAwesome 图标类名，如 `"fa fa-book"`。
3. **Layui 图标类名**：使用 Layui 内置图标类名，如 `"layui-icon layui-icon-app"`。
4. **图片 URL**：使用远程图片地址，如 `"https://example.com/icon.png"`。

**图标文件规范：**

| 项目 | 说明 |
|------|------|
| 文件名 | `icon.svg`（推荐）或 `icon.png` |
| 位置 | 应用根目录，与 `manifest.json` 同级 |
| 尺寸 | 建议 120×120 像素 |
| 格式 | SVG 优先（矢量、体积小），PNG 作为备选 |
| 访问路径 | `/api/app/{appId}/icon`（无需认证） |

**目录结构示例：**

```
code/app/Apps/Blog/
├── manifest.json
├── icon.svg          ← 应用图标文件
├── ServiceProvider.php
└── ...
```

**manifest.json 配合使用：**

```json
{
    "id": "cmspro.blog",
    "name": "博客",
    "icon": "fa fa-book",
    ...
}
```

> 当图标文件（`icon.svg`/`icon.png`）存在时，系统优先使用图标文件展示；图标文件不存在时，回退到 `icon` 字段指定的 FontAwesome/Layui 类名显示。

### 应用依赖

应用可通过 `dependencies` 字段声明对其他应用的依赖关系。安装时系统会校验依赖应用是否满足条件：

**校验规则：**
- 依赖应用必须**已安装**，否则返回错误码 `50004`
- 依赖应用必须**已启用**（状态为 `ENABLED`），否则返回错误码 `50017`
- 存在依赖关系的应用被卸载时，系统会阻止卸载并提示哪些应用依赖它（错误码 `50015`）

**声明示例：**

```json
{
    "dependencies": {
        "app_ids": ["finance", "points"],
        "versions": {}
    }
}
```

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| app_ids | array | 依赖的应用ID数组，应用ID对应 `manifest.json` 中的 `id` 字段 |
| versions | object | 版本约束映射，键为应用ID，值为版本约束表达式（当前预留，暂未校验） |

**依赖链示例：**

```
finance（财务管理） ← 被依赖
points（积分管理）  ← 被依赖
    ↓
onlinepay（在线支付） ← 依赖 finance + points
payclient（聚合支付客户端） ← 依赖 finance + points
```

> 安装 `onlinepay` 或 `payclient` 前，必须先安装并启用 `finance` 和 `points` 应用。

***

## 应用命名规范

### app_id 格式

**应用标识（id）必须**采用 `开发者唯一标识.应用标识` 的命名格式（即 `xx.xx` 格式），这是强制性规则，所有新开发的应用必须遵守：

```
格式：{developer_slug}.{app_name}
示例：cmspro.blog、zhangsan.shop
```

#### 规则

| 部分 | 规则 | 正则 |
|------|------|------|
| developer_slug | 小写字母开头，仅允许小写字母和数字 | `[a-z][a-z0-9]*` |
| app_name | 小写字母开头，允许小写字母、数字和下划线 | `[a-z][a-z0-9_]*` |
| 连接符 | 点号（.） | - |
| 总长度 | 不超过 64 字符 | - |

#### 旧格式兼容

系统安装时已有的应用（如 `onlinepay`、`versionmgr`）保持原有 app_id 不变。**新开发的应用必须**使用 `开发者唯一标识.应用标识`（`xx.xx`）格式，不符合此格式的应用将无法通过安装校验。

### 各层映射规则

| 维度 | 旧格式（如 `onlinepay`） | 新格式（如 `cmspro.blog`） |
|------|------------------------|--------------------------|
| 目录名 | `Onlinepay/` | `CmsproBlog/` |
| 命名空间 | `App\Apps\Onlinepay\` | `App\Apps\CmsproBlog\` |
| 表前缀 | `app_onlinepay_` | `app_cmspro_blog_` |
| 路由前缀 | `/admin/onlinepay` | `/admin/cmspro/blog` |
| 静态资源 | `public/apps/onlinepay` | `public/apps/cmspro/blog` |
| 配置键 | `apps.onlinepay` | `apps.cmspro.blog` |

**映射规则**：
- 目录名/命名空间：点号分隔的每段 `ucfirst()` 后拼接（如 `cmspro.blog` → `CmsproBlog`）
- 表前缀：点号替换为下划线（如 `cmspro.blog` → `app_cmspro_blog_`）
- 路由前缀：点号替换为斜杠（如 `cmspro.blog` → `cmspro/blog`）
- 静态资源：同路由前缀规则
- 配置键：保持点号不变（如 `apps.cmspro.blog`）

### 开发者标识

开发者标识即注册时的**用户名**，作为应用ID的前缀（`xx.xx` 格式中的前段），确保不同开发者的同名应用不会冲突。**这是应用 id 的必填组成部分，不可省略**。

示例：
- 开发者 `cmspro` 发布的博客应用：`cmspro.blog`
- 开发者 `zhangsan` 发布的博客应用：`zhangsan.blog`

### ⚠️ 强制规则（必读）

以下规则涉及应用能否在 Linux 服务器（大小写敏感文件系统）上正常运行，**必须严格遵守**。

#### 规则 1：app_id 只允许一个点号

app_id 格式验证正则：`/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)?$/`

这意味着 app_id 最多只有一个点号，`开发者标识.应用标识` 的两段式结构。**严禁使用多个点号**（如 `cmspro.tvbox.player` 将被拒绝安装）。

#### 规则 2：目录名必须严格等于 app_id_to_class_name() 的输出

目录名不是随意取的，而是由系统函数 `app_id_to_class_name($appId)` 精确生成。**不允许手动调整任何字母的大小写**。

```php
app_id_to_class_name('cmspro.tvboxplayer') = CmsproTvboxplayer  // 不能改成 CmsproTvboxPlayer
app_id_to_class_name('cmspro.blog')        = CmsproBlog         // 精确匹配
```

##### 验证方法（创建目录前必做）

```bash
# 实际创建目录前，用以下命令输出正确的目录名
php artisan tinker --execute="echo app_id_to_class_name('你的app_id');"
# 或直接运行 PHP
php -r "echo app_id_to_class_name('cmspro.tvboxplayer') . PHP_EOL;"
# 输出：CmsproTvboxplayer
```

确认输出后，**将这个输出值作为目录名称**。

#### 规则 3：命名空间必须与目录名完全一致

所有 PHP 文件中的命名空间声明、ServiceProvider 中的 `base_path()` 和 `->namespace()` 参数，**必须与目录名完全一致**（包括大小写）。

| 位置 | 内容 | 示例 |
|------|------|------|
| **目录名** | 文件系统中的目录 | `CmsproTvboxplayer/` |
| **Namespace 声明** | 所有 PHP 文件顶部 | `namespace App\Apps\CmsproTvboxplayer;` |
| **ServiceProvider routes** | `->namespace('App\Apps\CmsproTvboxplayer\Controllers')` | 末尾不能有多余空格 |
| **ServiceProvider base_path** | `base_path('app/Apps/CmsproTvboxplayer/Routes/...')` | 全部使用小写 `player` |
| **Route `->group()` 路径** | `group(base_path('app/Apps/CmsproTvboxplayer/Routes/web.php'))` | |

#### 规则 4：Windows 不报错 ≠ 正确

Windows 文件系统是大小写不敏感的，命名空间 `CmsproTvboxplayer` 和 `CmsproTvboxPlayer` 在 Windows 上指向同一个文件。**在 Windows 上测试通过不代表部署到 Linux 能运行**。

**必须**在开发环境就确保目录名、命名空间、代码引用三者完全一致。

#### 违反规则的后果（严重）

```
目录名 = CmsproTvboxPlayer（大写 P）
app_id_to_class_name 输出 = CmsproTvboxplayer（小写 p）

在 Linux 上安装时：
  executeInstall 创建目录：app/Apps/CmsproTvboxplayer/（小写 p）
  但 ServiceProvider 引用：app/Apps/CmsproTvboxPlayer/Routes/config.php（大写 P）
  → require() 失败 → PHP Fatal Error
  → 该 App 的 ServiceProvider 崩溃
  → Laravel 框架启动失败（所有已启用 App 的 Provider 在 bootstrap 阶段统一加载）
  → 全站 500，包括管理后台
  → 无法进入应用商店卸载/禁用该应用（死锁）
```

#### 排查命令

当怀疑是大小写/目录问题导致异常时：

```bash
# 1. 确认 app_id_to_class_name 的精确输出
php -r "echo app_id_to_class_name('你的app_id') . PHP_EOL;"

# 2. 确认目录是否存在
ls -la app/Apps/ | grep -i '你的app'

# 3. 确认命名空间声明与目录名一致
head -3 app/Apps/你的目录/ServiceProvider.php
# 输出应为：namespace App\Apps\你的目录;
```

### 正误对照示例

#### ✅ 正确的 app_id（可通过安装校验）

| app_id | 说明 |
|--------|------|
| `cmspro.blog` | 两段式，全小写 |
| `zhangsan.shop` | 开发者标识 + 应用标识 |
| `cmspro.blog_tools` | app_name 可含下划线 |

#### ❌ 错误的 app_id（安装报错「应用ID格式无效，需为 小写字母开头 或 开发者标识.应用名 格式」）

| app_id | 错误原因 |
|--------|---------|
| `niuren.Inkblog` | 应用名含大写字母（校验正则**仅允许小写**） |
| `Cmspro.Blog` | 两段均含大写字母 |
| `cmspro.tvbox.player` | 多个点号（最多一个） |
| `blog` | 缺少开发者标识（新应用必须 `xx.xx` 两段式） |
| `1cmspro.blog` | 数字开头 |
| `cmspro-.blog` | 含不允许的连字符 |

#### 真实案例：大写 app_id 的修复成本

应用 `niuren.Inkblog`（大写 `I`）安装时报错「应用ID格式无效」，根因是框架校验正则 `/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)?$/` 仅允许小写。修复时需要三向全量替换（约 644 处、上百文件）：

| 形式 | 替换 | 涉及位置 |
|------|------|---------|
| 点号形式 | `niuren.Inkblog` → `niuren.inkblog` | manifest id、配置键、视图命名空间 `niuren.inkblog::` |
| 表前缀 | `app_niuren_Inkblog_` → `app_niuren_inkblog_` | Migrations、Models、Install.php |
| 路由/资源前缀 | `niuren/Inkblog` → `niuren/inkblog` | Routes、`asset('apps/...')`、菜单 path |

目录名与命名空间 `NiurenInkblog` 由 `app_id_to_class_name()` 生成（`ucfirst` 拼接），改名前后不变，无需调整。

> **教训**：app_id 决定目录名、命名空间、表前缀、路由前缀、静态资源、配置键全部映射，创建应用前必须先确认（见 app-technical-analysis 技能 3.2 节），改名成本远高于开发前确认。

***

## 四、ServiceProvider 开发

ServiceProvider 是应用的运行时入口，负责注册路由、视图、配置等资源。

### 模板

```php
<?php

namespace App\Apps\Blog;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider as BaseServiceProvider;

class ServiceProvider extends BaseServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(
            base_path('app/Apps/Blog/Config/blog.php'),
            'apps.blog'
        );
    }

    public function boot(): void
    {
        $this->registerRoutes();
        $this->loadViews();
        $this->registerHooks();
    }

    protected function registerRoutes(): void
    {
        Route::prefix('admin/blog')
            ->namespace('App\Apps\Blog\Controllers')
            ->middleware(['auth:admin'])
            ->group(base_path('app/Apps/Blog/Routes/web.php'));
    }

    protected function loadViews(): void
    {
        $this->loadViewsFrom(
            base_path('app/Apps/Blog/Views'),
            'blog'
        );
    }

    protected function registerHooks(): void
    {
        $manifest = json_decode(
            file_get_contents(base_path('app/Apps/Blog/manifest.json')),
            true
        );

        if (isset($manifest['hooks'])) {
            $hooksClass = "App\\Apps\\Blog\\{$manifest['hooks']}";
            if (class_exists($hooksClass)) {
                $instance = new $hooksClass;
                $instance->register(app(\App\Services\HookManager::class));
            }
        }
    }
}
```

### 关键规则

1. **命名空间与目录名一致**：目录名由 `app_id_to_class_name(app_id)` 函数精确生成。对于单段式 app_id（如 `versionmgr`），是 `ucfirst(app_id)` 结果（`Versionmgr`）；对于 `xx.xx` 格式（如 `cmspro.tvboxplayer`），每段分别 `ucfirst` 后拼接（`CmsproTvboxplayer`）。**严禁手动调整任何字母的大小写**
2. **数据库 path 字段必须为相对路径**：安装后需确认 `apps` 表中的 `path` 字段值为相对路径格式（如 `app/Apps/Versionmgr`）。若为绝对路径（如 `<项目根>/app/Apps/Versionmgr`，即包含盘符或根目录前缀的完整路径）会导致换服务器后路由加载失败，存储与读取统一经 `AppPathHelper::appDir()` 解析
3. **命名空间**：必须使用 `App\Apps\{AppName}\` 前缀，其中 `{AppName}` 是应用ID的首字母大写形式（即目录名）
4. **路由前缀**：所有路由以 `admin/{app_id}` 为前缀，其中 `{app_id}` 必须替换为实际的 app_id（点号→斜杠）。如 app_id=`cmspro.blog` → 视图路由 `admin/cmspro/blog`、API路由 `api/admin/cmspro/blog`。严禁保留 `{app_id}` 字面量
5. **中间件**：必须添加 `auth:admin` 中间件
6. **视图命名空间**：使用应用ID作为命名空间，如 `blog`
7. **配置键**：使用 `apps.{app_id}` 作为配置键前缀

#### 路由与目录规范（新应用强制）

> **适用范围**：以下规范对**新开发的应用**强制生效；存量应用（如 `onlinepay`、`versionmgr`、`niuren.distributor`）保持现状，不强制迁移，后续迭代时可逐步对齐。

**① 路由前缀规范**

| 端 | 视图路由 | 接口路由 | 说明 |
|----|---------|---------|------|
| 后台 | `/admin/{app_id}` | `/api/admin/{app_id}` | 需管理员登录 |
| 用户端 | `/user/{app_id}` | `/api/user/{app_id}` | 需用户登录，带用户态 |
| 前台 | `/{app_id}` | `/api/{app_id}` | 公开接口，无需登录 |

- `{app_id}` 必须替换为实际 app_id（点号→斜杠），严禁保留字面量
- URL 一律**小写**；目录/命名空间**首字母大写**（见下）

**② 目录结构规范**

```
Views/                    Controllers/
├── Admin/                ├── Admin/     # 后台控制器
├── User/                 ├── User/      # 用户端控制器
├── Home/                 └── Home/      # 前台公开控制器
└── layouts/
```

- 视图目录与控制器目录按 `Admin/User/Home` 三端对应，首字母大写
- 视图命名空间强制带前缀：`view('{app_id}::Admin.xxx')`、`view('{app_id}::User.xxx')`、`view('{app_id}::Home.xxx')`

**③ 路由文件拆分**

```
Routes/
├── admin.php        # 后台路由（视图 + 接口）
├── user.php         # 用户端路由（视图 + 接口）
├── home.php         # 前台路由（视图 + 公开接口）
└── home-api.php     # 前台公开接口（可选，与 home.php 分离时使用）
```

> 后台/用户端接口与视图可同文件，也可按 `admin-api.php` / `user-api.php` 拆分，视应用复杂度而定。

> 命名空间 / 路径类问题（目录名与 app_id 大小写不一致、数据库绝对路径、ServiceProvider 硬编码路径、Windows 正常而 Linux 全站 500 等）的现象、根因与完整排查方法详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 2 章。

### AppPathHelper 路径解析规范（相对路径统一约定）

**原则：数据库中的路径字段一律存储相对路径，禁止存储绝对路径。**

- `apps.path`：相对项目根（如 `app/Apps/Versionmgr`），读取时经 `AppPathHelper::appDir()` 解析为当前服务器绝对路径
- 备份/升级包路径（`app_backups.file_path`、`app_versionmgr_system_version.backup_path`、`app_versionmgr_upgrade_package.package_path`、`app_versionsvr_version.package_path` / `program_package_path`、`app_cmspro_aidev_file_changes.backup_path` 等）：相对 `storage/`（如 `app_backups/cmspro.blog/backup_xxx.zip`），读取时经 `AppPathHelper::storage()` 解析

换服务器后数据库无需再修改；若存在旧服务器残留的绝对路径，`AppPathHelper` 会检测当前环境是否真实存在该路径，不存在时自动剥取 `/app/Apps/` 或 `/storage/` 之后的片段回退到当前项目内。

**常用方法**（`app/Helpers/AppPathHelper.php`）：

| 方法 | 用途 |
| ---- | ---- |
| `AppPathHelper::appDir($path, $fallbackSub)` | 解析 `apps.path` 为绝对路径；`$fallbackSub` 为无法解析时的项目内回退目录 |
| `AppPathHelper::storage($path)` | 解析 `storage/` 下的相对路径（备份/升级包）为绝对路径 |
| `AppPathHelper::toAppDirRelative($path)` | 入库前将绝对路径转为相对项目根（`app/Apps/...`） |
| `AppPathHelper::toStorageRelative($path)` | 入库前将绝对路径转为相对 `storage/` |

**开发要求**：
1. 新增/修改存储路径字段时，写入数据库前必须调用 `toAppDirRelative()` / `toStorageRelative()` 转为相对路径
2. 读取路径时必须通过 `AppPathHelper::appDir()` / `AppPathHelper::storage()`（或模型上的 `resolvePath()` / `resolveFilePath()` / `resolveBackupPath()` / `resolvePackagePath()` 等方法）解析，禁止直接拼绝对路径
3. 前端下载/展示链接一律使用相对路径（如 `/api/versionsvr/download/...`），禁止硬编码域名前缀

***

## 五、路由开发

### 路由文件

创建 `Routes/web.php`：

```php
<?php

use Illuminate\Support\Facades\Route;

Route::get('/', [PostController::class, 'index']);
Route::get('/create', [PostController::class, 'create']);
Route::post('/', [PostController::class, 'store']);
Route::get('/{id}/edit', [PostController::class, 'edit']);
Route::put('/{id}', [PostController::class, 'update']);
Route::delete('/{id}', [PostController::class, 'destroy']);
```

#### 路由文件拆分（新应用强制）

新开发的应用建议按端拆分路由文件，便于维护：

```
Routes/
├── admin.php        # 后台路由（视图 + 接口）
├── user.php         # 用户端路由（视图 + 接口）
├── home.php         # 前台路由（视图 + 公开接口）
└── home-api.php     # 前台公开接口（可选，与 home.php 分离时使用）
```

- 后台/用户端接口与视图可同文件，也可按 `admin-api.php` / `user-api.php` 拆分，视应用复杂度而定
- 各文件在 `ServiceProvider::registerRoutes()` 中通过 `Route::prefix()` + `->namespace()` 分别注册，前缀遵循「路由与目录规范」中的三端前缀规则
- 存量应用保持现状，不强制迁移

### 视图路由

如果需要返回 Blade 页面，在路由中直接返回视图：

```php
Route::get('/', function () {
    return view('blog::index');
});
```

### API 路由

API 路由同样在 `Routes/web.php` 中定义，因为系统使用 Session 认证：

```php
Route::get('/api/posts', [PostController::class, 'apiIndex']);
Route::post('/api/posts', [PostController::class, 'apiStore']);
```

### API 响应格式

系统提供 `App\Http\Responses\ApiResponse` 统一响应类，所有 API 接口必须使用此类返回数据。

#### 正确引入

```php
use App\Http\Responses\ApiResponse;

// 成功响应
return ApiResponse::success($data, '操作成功');

// 失败响应（错误码在前，提示文案在后）
return ApiResponse::error(40001, '参数错误');
```

> `ApiResponse` 类的错误命名空间导入（`App\Services\ApiResponse`）问题详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 3 章。

### 路由参数类型声明

> 路由参数 `int` 类型提示导致 `TypeError` 的问题背景详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 3 章。

**禁止对路由参数使用 `int` 类型提示**。Laravel 从 URL 中提取的路由参数始终为字符串类型，使用 `int` 类型提示会导致 `TypeError`：

```php
// ❌ 错误：路由参数是字符串，int 类型提示会报 TypeError
// Argument #1 ($id) must be of type int, string given
public function show(int $id) { ... }
public function update(Request $request, int $id) { ... }
public function destroy(int $id) { ... }

// ✅ 正确：不写类型提示，或显式声明 string
public function show($id) { ... }
public function update(Request $request, $id) { ... }
public function destroy($id) { ... }
```

> **原理**：URL `/posts/123` 中的 `123` 在 Laravel 路由匹配后作为字符串 `"123"` 传递给控制器方法。PHP 严格模式下 `int` 类型提示会拒绝字符串参数。此规则同时适用于控制器方法和闭包路由中的所有 URL 路径参数。

### API 数据验证规范（强制）

**核心原则：所有写操作接口（创建/更新）的必填字段必须先验证再入库。验证失败返回验证错误（4xxxx 错误码 + 字段级提示），禁止把未校验的数据直接写库触发程序级异常（500）。**

#### 为什么必须验证：空字符串转 null 陷阱

> 空字符串被中间件转 null、写入 NOT NULL 列触发 1048 异常的问题现场与原理详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 4 章；以下为验证与空值规范化规范。

Laravel 默认中间件 `ConvertEmptyStringsToNull` 会把请求中的空字符串自动转为 `null`。而数据库 NOT NULL 列（仅设 default）一旦被 Eloquent **显式**写入 null，会绕过默认值直接触发完整性约束异常：

```
SQLSTATE[23000]: Integrity constraint violation: 1048
Column 'upstream_protocol' cannot be null
→ 未验证直达用户，变成 50001 服务器内部错误（500）
```

> **原理**：`insert into t (col) values (null)` 中显式出现的 null 不走列默认值；只有 SQL 中**省略**该列时 default 才生效。前端表单「未选择/留空」的合法场景（如跟随供应商、暂无标签）都会以空字符串提交，必然命中此陷阱。

#### 验证层级与写法

**第一层：Controller 层验证（首选）**，使用 Laravel 内置验证：

```php
public function store(Request $request)
{
    $validated = $request->validate([
        'name'      => 'required|string|max:100',
        'provider'  => 'required|string|max:50',
        'api_base'  => 'required|url|max:500',
        'priority'  => 'nullable|integer|min:0',
    ]);
    // validate 失败自动抛 ValidationException，框架统一转为 422 + 字段级错误
    return $this->service->create($validated);
}
```

**第二层：Service 层兜底验证（数据入口不唯一时必须）**。同一 Service 方法可能被控制器、任务、钩子等多处调用时，Controller 验证无法覆盖全部入口，Service 层必须自带验证：

```php
public function create(array $data): array
{
    // 必填字段验证：缺失时返回验证错误，而非触发数据库异常
    $error = $this->validateChannelData($data);
    if ($error !== null) {
        return ApiResponse::error(40001, $error);
    }
    $data = $this->normalizeChannelData($data);
    // ... 入库
}

private function validateChannelData(array $data, ?Channel $item = null): ?string
{
    $required = [
        'name'     => '渠道名称',
        'provider' => '供应商',
        'api_base' => 'API地址',
    ];
    foreach ($required as $field => $label) {
        // 局部更新场景：仅校验请求中携带的字段，未携带的不拦截
        if ($item !== null && !array_key_exists($field, $data)) {
            continue;
        }
        // 注意：空字符串已被中间件转为 null，?? '' 统一归一后判断
        if (trim((string) ($data[$field] ?? '')) === '') {
            return "{$label}不能为空";
        }
    }
    return null;
}
```

> **局部更新语义**：`update` 接口若支持 PATCH 式局部更新，只校验请求中出现的必填字段；字段出现在请求中时只看请求值（空 = 缺失），不得回落取库中旧值放行。

#### 空值规范化规则

验证通过后、入库前，还须对「合法的空值」做规范化，避免 NOT NULL 列被写入 null：

| 字段类型 | 规范化规则 |
|---------|-----------|
| NOT NULL 字符串列（无 default） | `null` 回落为空字符串 `''` |
| NOT NULL 字符串列（有 default，如枚举类） | 空值时 `unset` 该字段，让 create 走默认值、update 保留原值 |
| 数值列 | 空值时 `unset` 该字段，避免 cast 后写入 `0` 覆盖库默认值 |
| 语义推导列（如「跟随供应商」的协议字段） | 留空时按业务规则推导写入，与运行时解析逻辑保持一致 |

#### 错误响应格式

验证失败统一返回 `4xxxx` 业务错误码 + 面向用户的提示文案，与 500 程序错误严格区分：

```php
// ✅ 验证错误：用户可理解、可修正
return ApiResponse::error(40001, '供应商不能为空');

// ❌ 未验证直接入库：数据库异常被全局处理器渲染为
// {"code": 50001, "message": "服务器内部错误", "data": {"exception": "...QueryException..."}}
```

#### 正反例对照

```php
// ❌ 错误：未验证直接 create，空 upstream_protocol → null → SQLSTATE[23000] → 500
public function create(array $data): array
{
    $keys = $data['keys'] ?? null;
    unset($data['keys']);
    $item = Channel::create($data);   // 数据库异常直达用户
    return ApiResponse::success($item);
}

// ✅ 正确：验证 → 规范化 → 入库，任何入口进来都拦得住
public function create(array $data): array
{
    $error = $this->validateChannelData($data);
    if ($error !== null) {
        return ApiResponse::error(40001, $error);
    }
    $data = $this->normalizeChannelData($data);
    $item = Channel::create($data);
    return ApiResponse::success($item);
}
```

#### 测试要求

每个写接口必须覆盖以下验证用例（参考 `CmsproAiproxy/Tests/Feature/ChannelValidationTest.php`）：

1. **用户报错场景回放**：用触发过问题的原始 payload 验证修复
2. **逐个必填字段置空**：断言返回 40001 + 对应提示文案、无记录落库
3. **合法空值场景**：可空字段为空时创建成功且走默认值
4. **更新拦截**：更新时必填字段传空被拦截、原记录不变

***
## 六、视图开发

### 视图文件

视图文件放在 `Views/` 目录下，使用命名空间访问：

```php
// 在控制器或路由中
return view('blog::index');
return view('blog::posts.form', ['post' => $post]);
```

### 视图路径规范

`loadViewsFrom()` 注册的视图命名空间（如 `blog`）指向 `Views/` 根目录，后续路径必须与 `Views/` 下的实际目录结构完全一致，包括所有子目录和大小写。

**规则**：视图路径中的点号 `.` 对应目录分隔符 `/`。路径必须从 `Views/` 下的第一层子目录开始写，不可跳过子目录直接用文件名。

**目录规范（新应用强制）**：`Views/` 下按 `Admin/`（后台）、`User/`（用户端）、`Home/`（前台公开）三端建立首层子目录，与控制器目录 `Controllers/Admin`、`Controllers/User`、`Controllers/Home` 一一对应。视图命名空间必须带前缀：`view('{app_id}::Admin.xxx')`、`view('{app_id}::User.xxx')`、`view('{app_id}::Home.xxx')`。存量应用保持现状，不强制迁移。

| 目录结构 | 正确引用 | 错误引用 |
|---------|---------|---------|
| `Views/Admin/Post/index.blade.php` | `blog::Admin.Post.index` | `blog::post.index`（缺少 `Admin` 目录，大小写错误） |
| `Views/Admin/Comment/index.blade.php` | `blog::Admin.Comment.index` | `blog::comment.index`（缺少 `Admin` 目录，大小写错误） |
| `Views/User/posts/index.blade.php` | `blog::User.posts.index` | `blog::posts.index`（缺少 `User` 目录） |
| `Views/Home/index.blade.php` | `blog::Home.index` | `blog::home.index`（大小写错误） |

> **常见错误**：直接写 `view('blog::post.index')` 而视图实际在 `Views/Admin/Post/` 目录下。由于视图路径必须从 `Views/` 根目录的第一层子目录开始匹配，缺少 `Admin` 目录层级会导致视图找不到的错误。

### 使用后台布局

应用视图可以继承系统后台布局：

```html
@extends('layouts.admin')

@section('content')
<div class="pear-container">
    <div class="layui-card">
        <div class="layui-card-body">
            <!-- 应用内容 -->
        </div>
    </div>
</div>
@endsection

@section('script')
layui.use(['table', 'form', 'jquery'], function(){
    // JavaScript 逻辑
});
@endsection
```

### 引用静态资源

应用静态资源通过符号链接访问：

```html
<link rel="stylesheet" href="{{ asset('apps/cmspro.blog/css/style.css') }}">
<script src="{{ asset('apps/cmspro.blog/js/app.js') }}"></script>
<img src="{{ asset('apps/cmspro.blog/icon.png') }}">
```

> **⚠️ 禁止使用 CDN 引用 UI 资源**：系统已内置 layui（`public/CmsProUi/component/layui/`）、pear（`public/CmsProUi/component/pear/`）、font-awesome（`public/CmsProUi/font-awesome/`）等 UI 框架，引用这些系统资源时**必须使用本地路径**。如需使用其他第三方库（如 echarts、qrcodejs、highlight.js 等），应下载到应用的 `Assets/` 目录中，通过 `public/apps/{appId}/` 访问。禁止在视图文件中直接引用 `cdn.jsdelivr.net`、`cdnjs.cloudflare.com`、`unpkg.com` 等 CDN 域名。

### Assets 静态资源发布机制

应用的 `Assets/` 目录用于存放需要通过 Web 公开访问的静态资源（CSS、JS、字体、图片等）。系统在安装、升级、卸载时会自动管理 `Assets/` 目录与 `public/apps/{appId}/` 之间的映射关系，**应用无需自行处理资源复制**。

#### 自动发布流程

系统 `AppInstallerService` 在应用生命周期中自动处理资源发布：

| 操作 | 调用方法 | 行为 |
| ---- | -------- | ---- |
| 安装 | `createAssetSymlink()` | 将 `Assets/` 目录链接/复制到 `public/apps/{appId}/` |
| 升级 | `removeAssetSymlink()` → `createAssetSymlink()` | 先删除旧资源，再重新发布 |
| 卸载 | `removeAssetSymlink()` | 删除 `public/apps/{appId}/` 目录 |

#### 发布策略

- **Linux 环境**：优先创建符号链接（`symlink`），`public/apps/{appId}` 指向 `Assets/` 目录
- **Windows 环境**：`symlink()` 可能不可用，降级为 `File::copyDirectory()` 将 `Assets/` 内容复制到 `public/apps/{appId}/`
- **目标路径已存在时跳过**：如果 `public/apps/{appId}/` 已存在，`createAssetSymlink()` 不会重复处理

#### 目录结构映射

```
app/Apps/Blog/Assets/          →  public/apps/blog/
├── css/                       →  ├── css/
│   └── style.css              →  │   └── style.css
├── js/                        →  ├── js/
│   └── app.js                 →  │   └── app.js
└── fonts/                     →  └── fonts/
    └── icon.ttf               →      └── icon.ttf
```

#### ⚠️ 关键注意事项

1. **禁止在 Install.php 中创建 `public/apps/{appId}/` 下的目录**：安装流程的执行顺序是先调用 `Install::install()`，再调用 `createAssetSymlink()`。如果在 `Install::install()` 中提前创建了 `public/apps/{appId}/` 下的任何目录，`createAssetSymlink()` 检测到目标路径已存在后会直接跳过，导致 `Assets/` 下的文件不会被复制/链接

```php
// ❌ 错误：提前创建目录会阻止框架的资源发布
public function install(): void
{
    $this->runMigrations();
    mkdir(public_path('apps/blog/uploads'), 0755, true); // 这会导致 Assets 不被复制
}

// ✅ 正确：不在 Install.php 中创建 public/apps/{appId}/ 下的目录
public function install(): void
{
    $this->runMigrations();
}
```

2. **运行时上传目录不应放在 Assets 中**：`Assets/` 目录的文件由系统在安装/升级时统一管理，用户上传的文件应存放在 `storage/` 或其他独立目录中，避免升级时被 `removeAssetSymlink()` 清除

3. **升级时 Assets 内容会被刷新**：升级流程先删除 `public/apps/{appId}/` 再重新发布，因此 `Assets/` 中应只包含应用自带的静态资源，不要存放运行时生成的文件

### 附件上传路径规范（强制）

应用上传的附件（用户上传的图片、文件等运行时数据）**必须**存放在 `public/uploads/` 目录下，并按以下规则组织目录：

```
public/uploads/{应用id}/{年}/{月}/{日}/{文件名}
```

#### 目录结构示例

以应用 `cmspro.blog` 为例，2026 年 8 月 20 日上传的附件：

```
public/uploads/
└── cmspro.blog/                  # 应用 id 目录（点号保留，如 cmspro.blog）
    └── 2026/                     # 年
        └── 08/                   # 月
            └── 20/               # 日
                └── abc123.png    # 附件文件
```

#### 强制规则

1. **根目录固定**：附件必须存放在 `public/uploads/` 根目录下，禁止存放到其他位置（如 `storage/`、应用 `Assets/` 目录等）
2. **应用 id 目录**：`public/uploads/` 根目录下必须以**应用 id**（如 `cmspro.blog`）创建一级文件夹，不同应用的附件相互隔离，禁止混放
3. **日期目录**：应用 id 目录下按 `年/月/日` 三级文件夹组织，日期取上传当天（`date('Y/m/d')`）
4. **文件名**：建议使用随机字符串 + 原扩展名（如 `Str::random(40).'.'.$extension`），避免文件名冲突与路径穿越风险
5. **访问方式**：附件通过 `{{ asset('uploads/{应用id}/{年}/{月}/{日}/{文件名}') }}` 或 `/uploads/{应用id}/{年}/{月}/{日}/{文件名}` 访问

#### 实现示例

```php
use Illuminate\Support\Str;

// 应用 id，如 cmspro.blog
$appId = 'cmspro.blog';
$datePath = date('Y/m/d');
$fileName = Str::random(40).'.'.$file->getClientOriginalExtension();

// 目标目录：public/uploads/cmspro.blog/2026/08/20/
$path = $file->storeAs(
    $appId.'/'.$datePath,
    $fileName,
    'public_uploads'   // 对应 public/uploads/ 磁盘
);

// 访问 URL：/uploads/cmspro.blog/2026/08/20/abc123.png
$url = '/uploads/'.$path;
```

> **注意**：`public/uploads/` 下的附件属于运行时生成数据，不属于应用 `Assets/` 静态资源，升级/卸载应用时不会被 `removeAssetSymlink()` 清除，可安全存放。

### 附件上传记录规范（强制）

**原则：任何上传均须可追溯、可复原。** 每一条附件记录必须能回答"谁、从哪个 IP、通过什么渠道、由哪个应用、传了什么、何时上传"，系统侧据此实现上传行为的完整审计与追溯。

#### 必录维度

| 维度 | 字段 | 说明 |
|---|---|---|
| 谁上传 | `user_id` + `uploader_type` | 后台、用户端必须记录登录账号；公共上传归 `uploader_type=system` |
| 来源 IP | `ip` | 上传者来源 IP（`$request->getClientIp()`） |
| 上传渠道 | `channel` + `user_agent` | 渠道标识（后台/用户端/公共入口），及客户端 UA |
| 所属应用 | `app_id` | 应用归属；系统级上传可为空 |
| 传了什么 | `name/path/url/extension/mime_type/size/hash/category` | 文件本体 + hash（用于去重与校验） |
| 何时 | `create_time` | 上传时间 |

#### 新增字段（`attachments` 表）

- `uploader_type`：账号体系，取值 `admin`（后台管理员，对应 `admin_users`）、`user`（前台用户，对应 `users`）、`developer`（开发者）、`system`（系统级/公共上传）；
- `ip`：来源 IP；
- `channel`：上传渠道标识；
- `user_agent`：客户端 UA（可选）。

#### 兼容旧数据（强制）

上述字段均需**兼容历史记录**：

1. `uploader_type` 为空的旧记录，默认按 `admin` 处理；
2. `ip`、`channel`、`user_agent` 旧记录允许为空；
3. `app_id` 旧记录允许为空（系统级）；**新上传按本规范执行**。

#### 上传者解析规则（统一）

`AttachmentService::upload` 写入 `user_id + uploader_type` 时，按当前登录 guard 依次识别：

- `auth('admin')` → `admin`；
- `auth('developer')` → `developer`；
- `auth('web')` → `user`；
- 均未登录 → `system`。

#### 入口记录规则

| 上传入口 | user_id | ip | channel | app_id | 登录强制 |
|---|---|---|---|---|---|
| 后台 | 必须（admin） | 记 | 记 | 应用场景必带 | 是 |
| 用户端 | 必须（web） | 记 | 记 | 应用场景必带 | 是 |
| 公共上传 | 不记（system） | 记 | 必须 | 必须 | 否 |

**公共上传强制校验**：对 `system` 类（未登录）上传，后端必须校验 `app_id` 与 `channel` 均已提供，缺一即拒绝。

#### 应用侧接入要求

1. 应用发起的附件上传必须携带 `app_id`；前台场景须保证 `auth('web')` 登录态；
2. 统一走 `AttachmentService::upload`，**禁止自行写 `attachments` 表绕过上传记录规范**；
3. 目录仍遵循上文"附件上传路径规范"（`public/uploads/{应用id}/{年}/{月}/{日}/{文件名}`）。

***

### 运行时文件存储规范（豁免）

**原则：区分"用户附件"与"运行时技术文件"。** 用户上传的图片/文档等内容必须走附件规范（`public/uploads/{应用id}/...` + `attachments` 表追溯）；而应用运行期产生的技术文件（版本升级包、备份、导入导出包、IP 数据库、支付证书等）**豁免附件规范**，允许自定义存储，但**必须在 `manifest.json` 的 `runtime_files` 字段中声明**，以便系统统一管理、清理与审计。

#### 豁免判定条件

满足以下任一条即属于"运行时技术文件"，可豁免附件规范：

1. **运行期产物**：由程序自动生成/保存的临时文件、缓存、编译产物，非用户主动上传的内容；
2. **技术包体**：版本升级包、应用安装包、导入/导出包、备份文件等 zip/压缩类文件；
3. **数据源文件**：IP 数据库、字典数据等运行时加载的数据文件；
4. **密钥证书**：支付证书、密钥、私钥等敏感文件（`protected`，禁止清理）；
5. **日志**：应用运行日志。

> **注意**：凡属"用户上传的内容"（头像、图片、附件等），一律不属于豁免，必须走附件规范。

#### 豁免目录约定（强制）

1. **根目录固定**：运行时技术文件统一存放在 `storage/` 下，推荐以 `storage/app_{应用id}/` 作为应用私有运行时根目录；
2. **禁止混放**：禁止将运行时技术文件写入 `public/uploads/`（附件专属）或应用 `Assets/` 静态资源目录（会被 `removeAssetSymlink()` 清理）；
3. **目录隔离**：不同应用各自独立目录，禁止混放；
4. **敏感文件**：证书、密钥类文件存放于 `storage/certs/` 或 `storage/app_{应用id}/certs/`，且 `protected` 声明。

#### manifest runtime_files 字段规范

在 `manifest.json` 中新增 `runtime_files` 数组字段，声明应用的全部运行时文件目录及清理策略：

```json
"runtime_files": [
  {
    "key": "packages",
    "name": "版本升级包",
    "dir": "app_versionsvr/packages",
    "type": "package",
    "description": "上传的历史版本升级包",
    "cleanable": true,
    "strategy": "keep_latest",
    "keep": 5,
    "ttl_days": 30,
    "pattern": ["*.zip"],
    "protected": false
  },
  {
    "key": "certs",
    "name": "支付证书密钥",
    "dir": "certs/wechat",
    "type": "cert",
    "description": "微信支付商户证书与平台证书，不可删除",
    "cleanable": false,
    "strategy": "protected",
    "protected": true
  }
]
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| key | string | 是 | 唯一标识，应用内不可重复 |
| name | string | 是 | 中文名称，用于后台展示 |
| dir | string | 是 | 目录路径，**相对 `storage/` 根目录**（如 `app_versionsvr/packages`）；也支持 `public/uploads` 下的子目录（`uploads/{应用id}/...`）或绝对路径（不推荐） |
| type | string | 是 | 文件类型：`package`（升级/安装包）、`backup`（备份）、`import_export`（导入导出包）、`temp`（临时文件）、`cache`（缓存）、`ipdb`（数据源）、`cert`（证书密钥）、`log`（日志）、`other` |
| description | string | 否 | 描述 |
| cleanable | bool | 是 | 是否可清理。`false` 表示只读展示、禁止删除 |
| strategy | string | 是 | 清理策略：`keep_latest`（保留最近 N 个）、`ttl`（超过 N 天可清理）、`manual`（仅人工）、`protected`（禁止清理） |
| keep | int | 否 | `keep_latest` 策略的保留数量 |
| ttl_days | int | 否 | `ttl` 策略的保留天数 |
| pattern | array | 否 | 匹配的文件名通配符数组（如 `["*.zip"]`）；为空表示目录下全部文件 |
| protected | bool | 否 | 是否受保护禁止删除（证书/密钥必须为 `true`），默认 `false` |

**清理策略说明：**

| 策略 | 含义 | 判定规则 |
|---|---|---|
| keep_latest | 保留最近 N 个 | 目录下按修改时间排序，超过 `keep` 个的文件视为可清理 |
| ttl | 保留 N 天 | 文件修改时间距今超过 `ttl_days` 天视为可清理 |
| manual | 仅人工 | 仅列出，不自动判定可清理，由人工决定 |
| protected | 禁止清理 | 只读展示，任何情况下不可删除 |

#### 豁免必声明（强制）

1. 应用存在任何运行时技术文件目录，**必须**在 `manifest.json` 的 `runtime_files` 中声明；
2. 未声明的运行时目录视为不合规，安装/升级校验时给出告警提示；
3. 清理助手（`cmspro.cleaner`）通过**直接扫描各应用 `manifest.json`** 收集豁免目录清单，不依赖数据库；
4. 应用新增/调整运行时目录时，同步更新 `runtime_files` 声明并提升 `version`。

#### 现有豁免目录归类示例

| 应用 | dir | type | strategy | 说明 |
|---|---|---|---|---|
| Versionsvr | `app_versionsvr/packages` | package | keep_latest(5) | 版本升级包 |
| Versionsvr | `app_versionsvr/temp` | temp | ttl(7) | 临时包 |
| Versionmgr | `app_versionmgr/packages` | package | keep_latest(3) | 系统升级包 |
| Versionmgr | `app_versionmgr/backups` | backup | keep_latest(5) | 升级前备份 |
| CmsproMigrator | `app_migrator/packages` | import_export | keep_latest(5) | 导入导出包 |
| CmsproMigrator | `app_migrator/staging` | temp | ttl(7) | 导入解压临时目录 |
| CmsproMigrator | `app_migrator/backups` | backup | keep_latest(5) | 导入前备份 |
| CmsproIplocation | `app/ipdb` | ipdb | ttl(30) | IP 数据库文件 |
| Payment | `certs/wechat` | cert | protected | 微信支付证书 |
| Payment | `app/onlinepay` | cert | protected | 支付证书密钥 |
| CmsproAppointment | `sys_get_temp_dir()` | temp | 系统临时目录 | 批量导入 CSV 使用 PHP 系统临时目录，不属于 storage，无需声明 |
| 框架 | `app_packages` | package | manual | 应用安装包 |
| 框架 | `app_backups` | backup | keep_latest(5) | 应用备份 |
| 框架 | `framework/cache` | cache | manual | Laravel 框架缓存 |
| 框架 | `framework/views` | cache | manual | 编译视图缓存 |
| 框架 | `logs` | log | ttl(30) | 系统日志 |

> 清理助手会依据上述声明 + `strategy` 自动计算可清理项，删除前预览、人工确认，删除记录写入 `operation_log`。

***

## 七、数据库迁移

### 命名规范

应用创建的数据库表必须使用 `app_{app_id}_` 前缀：

```
app_blog_posts          → Blog 应用的文章表
app_blog_categories     → Blog 应用的分类表
app_blog_tags           → Blog 应用的标签表
```

### 迁移文件

在 `Migrations/` 目录下创建迁移文件：

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('app_blog_posts')) {
            return;
        }

        Schema::create('app_blog_posts', function (Blueprint $table) {
            $table->bigIncrements('id')->comment('主键ID');
            $table->string('title')->comment('文章标题');
            $table->text('content')->nullable()->comment('文章内容');
            $table->unsignedTinyInteger('status')->default(0)->comment('状态：0-草稿 1-已发布 2-已下架');
            $table->timestamp('create_time')->nullable()->comment('创建时间');
            $table->timestamp('update_time')->nullable()->comment('更新时间');

            $table->index('status');
        });

        DB::statement("ALTER TABLE `app_blog_posts` COMMENT '博客文章表'");
    }

    public function down(): void
    {
        Schema::dropIfExists('app_blog_posts');
    }
};
```

### ⚠️ 迁移幂等性规范

迁移的 `up()` 和 `down()` 方法必须具备幂等性——即重复执行不会报错。这是因为在安装、升级、卸载流程中，迁移可能被多次调用（系统 `Artisan::call('migrate')` + `Install::install()` 兜底），如果缺少幂等检查会导致 `SQLSTATE[42S01]: Table already exists` 或 `SQLSTATE[42S02]: Base table or view not found` 错误。

#### 建表迁移的幂等性

```php
public function up(): void
{
    if (Schema::hasTable('app_blog_posts')) {
        return;
    }

    Schema::create('app_blog_posts', function (Blueprint $table) {
        // ...
    });
}

public function down(): void
{
    Schema::dropIfExists('app_blog_posts');
}
```

> `Schema::dropIfExists()` 本身已具备幂等性（表不存在时不报错），但 `Schema::create()` 不具备——重复建表会抛异常，因此 `up()` 必须添加表存在性检查。

#### 加列迁移的幂等性

当通过迁移为已有表添加字段时，`up()` 和 `down()` 都需要检查表和列的存在性：

```php
public function up(): void
{
    if (!Schema::hasTable('app_blog_posts')) {
        return;
    }

    Schema::table('app_blog_posts', function (Blueprint $table) {
        if (!Schema::hasColumn('app_blog_posts', 'summary')) {
            $table->string('summary', 500)->nullable()->after('title')->comment('摘要');
        }
        if (!Schema::hasColumn('app_blog_posts', 'sort')) {
            $table->integer('sort')->default(0)->after('status')->comment('排序');
        }
    });
}

public function down(): void
{
    if (!Schema::hasTable('app_blog_posts')) {
        return;
    }

    Schema::table('app_blog_posts', function (Blueprint $table) {
        $columns = [];
        if (Schema::hasColumn('app_blog_posts', 'summary')) $columns[] = 'summary';
        if (Schema::hasColumn('app_blog_posts', 'sort')) $columns[] = 'sort';
        if (!empty($columns)) $table->dropColumn($columns);
    });
}
```

> **关键场景**：卸载时系统先调 `Install::uninstall()` 再调 `rollbackMigrations()`。如果 `down()` 缺少表存在性检查，在表已被清理的情况下执行 `ALTER TABLE ... DROP COLUMN` 会报 `Table not found` 错误，导致卸载失败。

#### 幂等性速查表

| 操作类型 | up() 检查 | down() 检查 |
| ------- | --------- | ----------- |
| 建表 `Schema::create` | `Schema::hasTable()` → return | `Schema::dropIfExists()`（自带幂等） |
| 加列 `$table->string()` | `Schema::hasTable()` + `Schema::hasColumn()` | `Schema::hasTable()` + `Schema::hasColumn()` |
| 加索引 `$table->index()` | `Schema::hasTable()` | `Schema::hasTable()` |
| 改列 `$table->change()` | `Schema::hasTable()` + `Schema::hasColumn()` | `Schema::hasTable()` + `Schema::hasColumn()` |

### 备注规范

**表和字段必须添加备注**，这是数据库可维护性的基本要求，方便团队成员理解每个表和字段的业务含义。

#### 表备注

使用 `DB::statement()` 在 `up()` 方法中添加表备注：

```php
DB::statement("ALTER TABLE `app_blog_posts` COMMENT '博客文章表'");
```

#### 字段备注

使用 Laravel Schema Builder 的 `->comment()` 方法为每个字段添加备注：

```php
$table->string('title')->comment('文章标题');
$table->unsignedTinyInteger('status')->default(0)->comment('状态：0-草稿 1-已发布 2-已下架');
```

#### 备注编写规则

| 规则    | 说明                   | 示例                             |
| ----- | -------------------- | ------------------------------ |
| 语义清晰  | 备注必须说明字段的业务含义，而非数据类型 | ✅ `状态：0-禁用 1-启用` ❌ `tinyint类型` |
| 枚举值说明 | 状态、类型等枚举字段必须列出所有可选值  | `类型：1-Web 2-移动端 3-服务端`         |
| 关联说明  | 外键字段需说明关联的表          | `分类ID，关联app_blog_categories表`  |
| 简洁明了  | 备注应精炼，避免冗余描述         | ✅ `用户名` ❌ `用户的名字用于登录系统`        |

#### 基础字段备注参考

系统规范的基础字段，备注应统一如下：

| 字段            | 推荐备注                    |
| ------------- | ----------------------- |
| `id`          | 主键ID                    |
| `status`      | 状态：0-禁用 1-启用（根据业务调整枚举值） |
| `create_time` | 创建时间                    |
| `update_time` | 更新时间                    |

### 时间字段

遵循系统规范，使用 `create_time` 和 `update_time`（非 Laravel 默认）。

### 日期时间格式规范

**原则：数据库中的日期字段直接读取输出，禁止二次格式化加工。统一使用 `Y-m-d H:i:s` 格式，禁止 ISO 8601 格式。**

> 详细规范参见本包 `rules/01-CMSPRO开发规范.md` 第1节「日期时间处理」。

#### 正确格式

```
2026-05-23 15:29:13
```

#### 禁止格式

```
2026-05-23T00:16:39.000000Z    // ISO 8601 带时区格式（Laravel 默认序列化格式）
2026-05-23T00:16:39+08:00      // ISO 8601 带偏移格式
May 23, 2026 3:29 PM           // 英文可读格式
```

#### 实现方式

**方式一：模型 `$casts` 配置（推荐，按字段控制）**

```php
protected $casts = [
    'create_time' => 'datetime:Y-m-d H:i:s',
    'update_time' => 'datetime:Y-m-d H:i:s',
];
```

**方式二：重写 `serializeDate` 方法（全局生效）**

> 系统基类 `App\Models\BaseModel` 已全局重写 `serializeDate()`，返回 `Y-m-d H:i:s` 格式，所有继承 `BaseModel` 的模型自动生效。

```php
protected function serializeDate(DateTimeInterface $date): string
{
    return $date->format('Y-m-d H:i:s');
}
```

#### 关键陷阱：`$casts` 只在模型序列化时生效

**`$casts` 中配置的 `datetime:Y-m-d H:i:s` 仅在调用 `toArray()` / `toJson()` 时生效。直接属性访问 `$model->create_time` 仍返回 Carbon 对象，放入普通数组后 `response()->json()` 会将 Carbon 序列化为 ISO 8601 格式，导致前端显示 `2026-05-23T00:16:39.000000Z`。**

##### 错误写法

```php
// ❌ 直接从模型取属性放入数组 → Carbon 对象 → JSON 序列化为 ISO 8601
$data = array_map(function ($item) {
    return [
        'id' => $item->id,
        'create_time' => $item->create_time,  // Carbon 对象！
    ];
}, $notes);
```

##### 正确写法一：先 `toArray()` 再提取字段

```php
// ✅ 先转为数组（触发 $casts 格式化），再提取字段
$data = array_map(function ($item) {
    $arr = $item->toArray();
    return [
        'id' => $arr['id'],
        'create_time' => $arr['create_time'],  // 已格式化为 "Y-m-d H:i:s" 字符串
    ];
}, $notes);
```

##### 正确写法二：显式 `format()`

```php
// ✅ 手动格式化 Carbon 对象
$data = array_map(function ($item) {
    return [
        'id' => $item->id,
        'create_time' => $item->create_time ? $item->create_time->format('Y-m-d H:i:s') : null,
    ];
}, $notes);
```

##### 正确写法三：直接返回 Eloquent 模型（自动序列化）

```php
// ✅ 直接将模型放入响应，response()->json() 会调用 toArray() 触发 $casts
return response()->json($note);  // 自动走 toArray() → serializeDate() → Y-m-d H:i:s
```

#### 禁止事项

- **禁止**在 Controller / Service 层对已从模型取出的日期字段再次调用 `format()` 方法（仅当直接访问 Carbon 对象需要格式化时除外，见正确写法二）
- **禁止**在前端视图或 API 响应中对日期做二次格式化
- **禁止**使用 Laravel 默认的 ISO 8601 序列化格式返回给前端
- **禁止**从 Eloquent 模型直接取日期属性放入普通数组（会丢失 `$casts` 格式化）
- 第三方 API 返回的 ISO 8601 日期写入数据库前，**必须**先解析为 `Y-m-d H:i:s` 格式

### 迁移文件兼容性规范

**原则：迁移文件必须兼容 MySQL（生产环境）和 SQLite（测试环境），编写时优先使用 Schema facade 方法，避免直接使用 DB::statement 执行原生 SQL。**

#### 强制要求

| 场景 | 要求 |
|------|------|
| CREATE TABLE | 必须用 `Schema::create()`，**禁止**裸写 `CREATE TABLE` SQL |
| 创建表前检查 | 必须用 `Schema::hasTable('table_name')` 判断，避免已存在时报错 |
| 新增字段 | 必须用 `Schema::table()` + `$table->type()` 方法，**禁止** `ALTER TABLE ADD COLUMN` |
| 新增字段前检查 | 必须用 `Schema::hasColumn('table', 'column')` 判断，确保重复执行安全 |
| 删除字段 | 必须用 `$table->dropColumn()`，**禁止** `ALTER TABLE DROP COLUMN` |
| 删除字段前检查 | 删除前必须用 `Schema::hasColumn()` 判断 |
| 驱动兼容 | `after('column')` 仅 MySQL 生效，SQLite 自动忽略，可用于统一代码但不可依赖 |
| 索引操作 | 新增/删除索引前必须用 `Schema::hasIndex()`（Laravel 11+）或 try-catch 兜底 |
| 数据回填 | 用 `chunkById` 分批处理，避免大表锁死，**禁止**一次性 `all()` 全量加载 |
| 幂等性 | `up()` 和 `down()` 必须可重复执行，无论执行多少次结果一致 |

#### 禁止写法

```php
// ❌ 直接 CREATE TABLE（表已存在时崩溃）
DB::statement('CREATE TABLE `jobs` (`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY)');

// ❌ ALTER TABLE ADD COLUMN（MySQL 特定语法，SQLite 不兼容）
DB::statement('ALTER TABLE admin_permissions ADD COLUMN status TINYINT NOT NULL DEFAULT 1');

// ❌ ALTER TABLE MODIFY（SQLite 不支持 MODIFY）
DB::statement('ALTER TABLE config_items MODIFY code VARCHAR(191) NOT NULL');

// ❌ MODIFY COLUMN（SQLite 不支持）
DB::statement('ALTER TABLE admin_users MODIFY COLUMN ...');

// ❌ 无幂等性检查（第二次执行时崩溃）
Schema::table('admin_menus', function (Blueprint $table) {
    $table->string('code', 100)->nullable(); // 再次执行报错：字段已存在
});
```

#### 正确写法

```php
// ✅ CREATE TABLE 前检查
if (!Schema::hasTable('jobs')) {
    Schema::create('jobs', function (Blueprint $table) {
        $table->bigIncrements('id');
        $table->string('queue')->index();
    });
}

// ✅ 新增字段前检查
if (!Schema::hasColumn('admin_menus', 'code')) {
    Schema::table('admin_menus', function (Blueprint $table) {
        $table->string('code', 100)->nullable()->after('path');
        $table->index(['app_id', 'code'], 'idx_admin_menus_app_code');
    });
}

// ✅ 数据回填：分批处理 + chunkById
AdminMenu::whereNull('code')->chunkById(200, function ($menus) {
    foreach ($menus as $menu) {
        $menu->update(['code' => $this->slugifyPath($menu->path)]);
    }
});

// ✅ 跨驱动兼容的字段长度修改
$driver = Schema::getConnection()->getDriverName();
if ($driver !== 'sqlite') {
    Schema::table('config_items', function (Blueprint $table) {
        $table->string('code', 191)->change();
    });
}
```

#### 数据库驱动判断

当需要编写 MySQL 特定逻辑时，通过驱动名称判断：

```php
$driver = Schema::getConnection()->getDriverName();

if ($driver === 'sqlite') {
    // SQLite 兼容路径：跳过或使用替代方案
    return;
}

// MySQL / MariaDB 特定操作（如 MODIFY COLUMN、全文索引等）
Schema::table('table', function (Blueprint $table) {
    // ...
});
```

#### 测试环境注意事项

- SQLite 内存数据库（`:memory:`）用于 PHPUnit 测试的 `RefreshDatabase`
- SQLite 不支持 `MODIFY COLUMN`、`CHANGE COLUMN`、`AFTER`、`DROP FOREIGN KEY`（需先 `SET foreign_keys=OFF`）
- SQLite 的 `ALTER TABLE` 能力有限，**增删字段前必须检查列是否存在**
- 迁移编写完成后，**必须在 SQLite 内存数据库下运行测试验证**，确保兼容
- 测试环境迁移失败通常表现为 `General error: 1 near "MODIFY": syntax error` 或 `General error: 1 no such table: xxx`

> 迁移常见错误（SQLite 不支持 `MODIFY` / `SHOW`、表已存在、Unknown column 等）详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 5 章。

***

## 八、敏感数据加密存储规范

> 本规范解决跨站点数据迁移时，加密字段因 `APP_KEY` 不同而解密失败的问题（`The MAC is invalid.`）。

### 8.1 核心问题：`APP_KEY` 与加密数据强绑定

Laravel 的 `Crypt` 加密（AES-256-CBC）依赖 `.env` 中的 `APP_KEY`：

- 加密时用**当时的** `APP_KEY` 生成密文；
- 解密时用**当前的** `APP_KEY` 校验并解密。

因此，**同一份密文在 `APP_KEY` 不同的站点之间无法通用**。数据库迁移、备份恢复、跨环境导入时，若源站与目标站的 `APP_KEY` 不一致，读取加密字段会抛 `The MAC is invalid.`。

### 8.2 加密字段识别特征

无论字段名是什么，只要值是用 `Crypt::encryptString()` 生成的，其底层为 base64 编码的 JSON：

```json
{"iv":"...","value":"...","mac":"...","tag":""}
```

base64 后**恒以 `eyJpdiI6`（即 `{"iv":`）开头**。据此可凭**值特征**识别加密字段，无需维护字段名清单：

- 值非空且以 `eyJpdiI6` 开头 → Laravel Crypt 加密串；
- 其余 → 明文，原样处理。

### 8.3 强制规范

#### 8.3.1 统一使用 `Crypt`，禁止自写加密

- 敏感字段（API 密钥、账号 token、密码类凭据）必须使用 `Crypt::encryptString()` / `Crypt::decryptString()` 加密存储；
- **禁止**用 `openssl_encrypt` 自写加密或其他第三方加密库，否则通用迁移工具无法识别。

#### 8.3.2 加密字段的模型访问器

加密字段在模型中通过 `setXxxAttribute` / `getXxxAttribute` 封装加解密，调用方无感知：

```php
public function setTokenAttribute(?string $value): void
{
    if ($value === null || $value === '') {
        $this->attributes['token'] = $value;
        return;
    }
    $this->attributes['token'] = \Illuminate\Support\Facades\Crypt::encryptString($value);
}

public function getTokenAttribute(?string $value): ?string
{
    if ($value === null || $value === '') {
        return $value;
    }
    try {
        return \Illuminate\Support\Facades\Crypt::decryptString($value);
    } catch (\Throwable) {
        // 解密失败（如旧明文或 key 不匹配）原样返回，避免抛异常
        return $value;
    }
}
```

#### 8.3.3 配置类敏感项封装进 `SettingService`

应用配置中的敏感项（如 `proxy_api_key`）在 `SettingService` 内统一加解密，并暴露 `ENCRYPTED_CODES` 白名单：

```php
protected const ENCRYPTED_CODES = ['proxy_api_key'];
```

对不在白名单的非敏感项，**不得调用加解密**，避免误判。

### 8.4 跨站点迁移：通用密钥迁移工具

框架提供跨站点迁移时按值特征解密/重加密的 artisan 命令，通杀所有应用、所有加密字段：

```bash
# 源站导出（解密为明文，可加 --passphrase 加密导出文件）
php artisan key-migrate:export --tables=app_xxx_% --passphrase=你的口令

# 目标站导入（用目标站 APP_KEY 重新加密后写入）
php artisan key-migrate:import --file=storage/app/key-migrate-export.json --passphrase=你的口令
```

工具核心逻辑见 `app/Services/KeyMigrationService.php`。

### 8.5 注意事项

- **`APP_KEY` 变更影响面**：更换 `APP_KEY` 会导致所有已加密数据无法解密，非必要不更换；确需更换时使用上述迁移工具重加密；
- **多站点一致性**：保证各站点 `.env` 的 `APP_KEY` 一致可避免多数迁移问题（最简单），但 key 泄露影响所有站点，权衡取舍；
- **识别局限**：仅识别 Laravel 标准 `Crypt` 格式；未按要求使用 `Crypt` 的字段会被当明文原样保留（不误伤、不转换），需人工核对。

***

## 十、模型开发

### 模型模板

```php
<?php

namespace App\Apps\Blog\Models;

use App\Models\BaseModel;

class Post extends BaseModel
{
    protected $table = 'app_blog_posts';

    public const CREATED_AT = 'create_time';

    public const UPDATED_AT = 'update_time';

    protected $fillable = [
        'title',
        'content',
        'status',
    ];

    protected $casts = [
        'status' => \App\Enums\Status::class,
        'create_time' => 'datetime:Y-m-d H:i:s',
        'update_time' => 'datetime:Y-m-d H:i:s',
    ];
}
```

***

## 十一、钩子系统

### 钩子类型

| 类型     | 说明           | 返回值       |
| ------ | ------------ | --------- |
| Action | 在特定节点执行自定义逻辑 | 无         |
| Filter | 在特定节点拦截并修改数据 | 必须返回修改后的值 |

### 注册钩子

创建 `Hooks.php`：

```php
<?php

namespace App\Apps\Blog;

use App\Services\HookManager;

class Hooks
{
    public function register(HookManager $hooks): void
    {
        $hooks->registerAction('content.after_create', [$this, 'onContentCreated'], 10, 'blog');
        $hooks->registerFilter('content.list.query', [$this, 'filterContentQuery'], 10, 'blog');
    }

    public function onContentCreated($content): void
    {
        // 内容创建后的自定义逻辑
    }

    public function filterContentQuery($query)
    {
        return $query->where('status', 1);
    }
}
```

**重要**：注册钩子时必须传入 `app_id`（第4个参数），以便应用禁用时自动移除钩子。

### 系统内置钩子点

> 钩子点按模块分组列出。所有系统级钩子在注册时**无需**传入 `app_id`（系统不会自我卸载）；应用自定义钩子仍需传 `app_id`。

#### 已实现：应用生命周期（app.* 系列）

| 钩子点             | 类型     | 参数                  | 触发位置                                        |
| --------------- | ------ | ------------------- | ------------------------------------------- |
| `app.installed` | Action | $appId              | `AppInstallerService::install` / `installFromPackage` |
| `app.uninstalled` | Action | $appId              | `AppInstallerService::uninstall`            |
| `app.upgraded`  | Action | $appId, $from, $to  | `AppInstallerService::upgrade`              |
| `app.enabled`   | Action | $appId              | `AppManagerService::enable`                 |
| `app.disabled`  | Action | $appId              | `AppManagerService::disable`                |

#### 已实现：前台用户认证与资料（user.* 系列）

| 钩子点                    | 类型     | 参数               | 触发位置                          |
| ---------------------- | ------ | ---------------- | ----------------------------- |
| `user.before_register` | Filter | $data            | `Api\UserAuthController::register` |
| `user.after_register`  | Action | $user            | `Api\UserAuthController::register` |
| `user.before_login`    | Filter | $credentials     | `Api\UserAuthController::login` |
| `user.after_login`     | Action | $user            | `Api\UserAuthController::login` |
| `user.before_logout`   | Action | $user            | `Api\UserAuthController::logout` |
| `user.profile.updating` | Filter | $data, $user     | `Api\UserAuthController::updateProfile` |
| `user.profile.updated` | Action | $user            | `Api\UserAuthController::updateProfile` |

> **重要**：`user.*` 系列仅由**前台用户自助操作**触发（注册 / 登录 / 登出 / 修改个人资料）。以下场景**不触发**：
> - 管理员在后台管理前台用户（增删改、改状态、重置密码）—— 当前无钩子，规划使用 `front_user.*` 系列
> - 后台管理员自身的登录 / 登出 / 改密 —— 当前无钩子，规划使用 `admin.*` 系列

#### 已实现：内容管理（content.* 系列）

| 钩子点                    | 类型     | 参数              | 触发位置                          |
| ---------------------- | ------ | --------------- | ----------------------------- |
| `content.list.query`   | Filter | $query          | `ContentService::index` 查询构建后 |
| `content.before_create` | Filter | $data           | `ContentService::store` 事务前   |
| `content.after_create`  | Action | $content        | `ContentService::store` 事务提交后 |
| `content.before_update` | Filter | $data, $content | `ContentService::update` 事务前  |
| `content.after_update`  | Action | $content        | `ContentService::update` 事务后  |
| `content.before_delete` | Action | $content        | `ContentService::destroy` / `batchDelete` 事务前 |
| `content.after_delete`  | Action | $content        | `ContentService::destroy` / `batchDelete` 事务后 |
| `content.before_update_status` | Filter | $status, $content | `ContentService::updateStatus` 更新前 |
| `content.after_update_status`  | Action | $content, $status | `ContentService::updateStatus` 更新后 |

> **事务边界约定**：`after_*` 钩子在 `DB::transaction` 闭包**外**触发，确保钩子内副作用不会被回滚；`before_*` 钩子在事务内触发。Filter 钩子必须接收返回值（`$data = $hookManager->applyFilter(...)`）。`batchDelete` 的 `before_delete` 在事务内逐条触发，`after_delete` 在事务提交后逐条触发。

#### 已实现：菜单渲染（menu.* 系列）

| 钩子点             | 类型     | 参数     | 触发位置                                |
| --------------- | ------ | ------ | ----------------------------------- |
| `menu.rendering` | Filter | $menus | `MenuService::tree` / `userMenus` / `homeMenus` buildTree 后 |

> 该钩子用于动态注入或隐藏菜单项，覆盖菜单管理页全量树、后台用户菜单、前台导航三个场景。

#### 已实现：后台管理员认证（admin.* 系列）

| 钩子点                       | 类型     | 参数                  | 触发位置                          |
| --------------------------- | ------ | ------------------- | ----------------------------- |
| `admin.before_login`        | Filter | $credentials        | `AuthService::login` 查询前     |
| `admin.after_login`         | Action | $user               | `AuthService::login` 更新登录信息后 |
| `admin.login_failed`        | Action | $username, $reason  | `AuthService::login` 校验失败处  |
| `admin.before_logout`       | Action | $user               | `AuthService::logout` 前       |
| `admin.after_password_changed` | Action | $user             | `AuthService::changePassword` 后 |

#### 已实现：后台管理员管理（admin_user.* 系列）

| 钩子点                       | 类型     | 参数              | 触发位置                              |
| --------------------------- | ------ | --------------- | ----------------------------------- |
| `admin_user.before_create`  | Filter | $data           | `UserService::store` 创建前          |
| `admin_user.after_create`   | Action | $user           | `UserService::store` return 前       |
| `admin_user.after_update`   | Action | $user           | `UserService::update` return 前      |
| `admin_user.before_delete`  | Action | $user           | `UserService::destroy` / `batchDelete` 事务前 |
| `admin_user.after_delete`   | Action | $user           | `UserService::destroy` / `batchDelete` 删除后 |
| `admin_user.status_changed` | Action | $user, $status  | `UserService::updateStatus` 更新后    |
| `admin_user.password_reset` | Action | $user           | `UserService::resetPassword` 更新后   |

#### 已实现：管理员操作前台用户（front_user.* 系列）

> 与 `user.*` 区分：`user.*` 是前台用户**自助**操作；`front_user.*` 是**管理员**操作前台用户。

| 钩子点                       | 类型     | 参数              | 触发位置                              |
| --------------------------- | ------ | --------------- | ----------------------------------- |
| `front_user.after_create`   | Action | $user           | `FrontUserService::store` return 前  |
| `front_user.after_update`   | Action | $user           | `FrontUserService::update` return 前 |
| `front_user.before_delete`  | Action | $user           | `FrontUserService::destroy` / `batchDelete` 事务前 |
| `front_user.after_delete`   | Action | $user           | `FrontUserService::batchDelete` 事务后 |
| `front_user.status_changed` | Action | $user, $status  | `FrontUserService::updateStatus` 后  |
| `front_user.password_reset` | Action | $user           | `FrontUserService::resetPassword` 后 |

#### 已实现：附件管理（attachment.* 系列）

| 钩子点                     | 类型     | 参数                  | 触发位置                              |
| ------------------------- | ------ | ------------------- | ----------------------------------- |
| `attachment.before_upload` | Filter | $file, $config      | `AttachmentService::upload` 校验后    |
| `attachment.after_upload`  | Action | $attachment         | `AttachmentService::upload` 创建后    |
| `attachment.before_delete` | Action | $attachment         | `AttachmentService::destroy` 事务内   |
| `attachment.after_delete`  | Action | $attachment         | `AttachmentService::destroy` 事务后   |

#### 已实现：角色管理（role.* 系列）

| 钩子点              | 类型     | 参数   | 触发位置                          |
| ------------------ | ------ | ---- | ----------------------------- |
| `role.after_create` | Action | $role | `RoleService::store` 缓存清理后 |
| `role.after_update` | Action | $role | `RoleService::update` 缓存清理后 |
| `role.after_delete` | Action | $role | `RoleService::destroy` 缓存清理后 |

#### 已实现：用户组管理（user_group.* 系列）

| 钩子点                    | 类型     | 参数    | 触发位置                              |
| ------------------------ | ------ | ----- | ----------------------------------- |
| `user_group.after_create` | Action | $group | `UserGroupService::store` return 前 |
| `user_group.after_update` | Action | $group | `UserGroupService::update` return 前 |
| `user_group.after_delete` | Action | $group | `UserGroupService::destroy` return 前 |

#### 已实现：配置项管理（config.* 系列）

| 钩子点                     | 类型     | 参数    | 触发位置                              |
| ------------------------- | ------ | ----- | ----------------------------------- |
| `config.after_create`     | Action | $item | `ConfigItemController::store` 创建后  |
| `config.after_update`     | Action | $item | `ConfigItemController::update` 更新后 |
| `config.after_batch_update` | Action | $items | `ConfigItemController::batch` 清缓存后 |

#### 已实现：仪表盘统计（dashboard.* 系列）

| 钩子点             | 类型     | 参数    | 触发位置                              |
| ----------------- | ------ | ----- | ----------------------------------- |
| `dashboard.stats` | Filter | $stats | `DashboardController::stats` 汇总后  |

> 该钩子允许应用注入自定义统计卡片（如订单数、营收额等），返回的 `$stats` 数组会直接作为响应数据。

#### 文档声明但尚未实现（应用暂不可挂载）

> 当前无。所有规划的系统级钩子点均已落地。

### 触发自定义钩子

应用也可以定义自己的钩子点供其他应用使用：

```php
$hookManager = app(\App\Services\HookManager::class);

// 触发 Action
$hookManager->doAction('blog.post.published', $post);

// 触发 Filter
$query = $hookManager->applyFilter('blog.post.query', $query);
```

***

## 十二、Install 脚本

### 模板

创建 `Install.php` 可在安装/卸载/升级时执行自定义逻辑：

```php
<?php

namespace App\Apps\Blog;

class Install
{
    public function install(): void
    {
        // 在迁移执行之后调用
        // 如：创建默认数据、初始化设置等
    }

    public function uninstall(): void
    {
        // 在迁移回滚之前调用
        // 仅用于清理缓存、通知外部服务等非数据库操作
        // 禁止在此方法中删除数据库表（详见下方卸载规范）
    }

    public function upgrade(string $fromVersion, string $toVersion): void
    {
        // 在增量迁移执行之后调用
        // 如：数据格式转换、配置迁移等

        if (version_compare($fromVersion, '1.1.0', '<')) {
            // 1.0.x 升级到 1.1.0 的特殊处理
        }
    }
}
```

### 执行顺序

**安装**：Install::install() → 数据库迁移 → 注册菜单/配置/权限

**卸载**：Install::uninstall() → 回滚迁移 → 删除菜单/配置/权限

**升级**：Install::upgrade() → 增量迁移 → 更新菜单/权限

### ⚠️ 升级文件覆盖语义与废弃文件清理（强制）

**升级采用「解压覆盖」而非「先删后装」**：系统将新版本包直接解压覆盖到应用目录（`ZipArchive::extractTo`），包内同名文件被覆盖、新增文件写入，但**新版本中已删除的旧文件会残留在应用目录中**。各位置行为差异：

| 位置 | 升级行为 |
| --- | --- |
| `app/Apps/{AppName}/` 源码目录 | 解压覆盖，新版本已删除的旧文件**残留** |
| `public/apps/{appId}/` 资源侧 | 先删旧（`removeAssetSymlink()`）再重新发布，**不残留** |
| `storage/`、`public/uploads/` 运行时数据 | 不在覆盖范围，始终保留 |

因此，应用发生**代码结构变更**（文件删除、重命名、目录调整）时，必须在 `Install::upgrade()` 中维护「废弃文件清单」执行清理，否则残留的旧文件将成为死代码，甚至与新版类冲突：

```php
public function upgrade(string $fromVersion, string $toVersion): void
{
    $appPath = __DIR__;

    // 废弃文件清单：新版本中已不存在的旧结构文件
    $obsolete = [
        'Services/OldService.php',
        'Http/Controllers/LegacyController.php',
    ];
    foreach ($obsolete as $rel) {
        $path = $appPath.'/'.$rel;
        if (is_file($path)) {
            @unlink($path);
        }
    }

    // 复杂结构迁移按版本区间处理
    if (version_compare($fromVersion, '1.2.0', '<')) {
        @rmdir($appPath.'/Legacy');
    }
}
```

**要点**：

1. **执行时序安全**：`Install::upgrade()` 在新版文件解压就位之后、数据库事务提交之前调用，且应用处于禁用状态（升级强制禁用，运行时未加载应用代码），此时删除旧文件不会误删新版文件，也不会遇到文件锁。
2. **推荐「全量废弃清单 + 版本判断」**：前端支持逐级升级（如 v1.0→v1.1→v1.2 每步触发一次 `upgrade()`），全量清单在任何升级路径下都收敛到正确状态，不要为每个中间版本单独写清理逻辑。
3. **不要清理 `public/apps/{appId}/`**：资源侧由系统在升级时先删旧再重新发布，应用 `Assets/` 中删除旧资源后发布侧自动同步。
4. **运行时数据禁止列入废弃清单**：`storage/`、`public/uploads/` 等运行时目录不受升级覆盖影响，删除将丢失用户数据。

### ⚠️ 卸载规范

**`uninstall()` 方法中禁止删除数据库表。** 系统卸载流程是两步走：

1. 先调 `Install::uninstall()` 执行自定义清理逻辑
2. 再调 `rollbackMigrations()` 执行迁移的 `down()` 方法回滚数据库

如果在 `uninstall()` 中手动调用 `Schema::dropIfExists()` 删除了表，第 2 步 `down()` 方法再对已不存在的表执行 `ALTER TABLE ... DROP COLUMN` 等操作时会报 `Table not found` 错误，导致卸载失败。

```php
// ❌ 错误：手动删表会导致 rollbackMigrations() 报错
public function uninstall(): void
{
    Schema::dropIfExists('app_blog_posts');
    Schema::dropIfExists('app_blog_categories');
}

// ✅ 正确：卸载时仅做非数据库清理，表删除交给系统的 rollbackMigrations()
public function uninstall(): void
{
    Cache::flush();
}
```

> **原则**：数据库表的创建和删除完全由迁移文件的 `up()` / `down()` 方法负责，`Install::uninstall()` 只处理缓存清理、外部通知等非数据库操作。

### ⚠️ 卸载迁移回滚兜底

> 卸载后数据库表残留（Windows 下 `migrate:rollback` 回滚未执行）的现象与原理详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 6 章；以下为应用内实现规范。

系统卸载流程第 2 步 `rollbackMigrations()` 使用 `Artisan::call('migrate:rollback', ['--path' => ...])` 回滚数据库。该命令依赖 `migrations` 表记录和路径解析，在 Windows 等环境下可能因路径分隔符、大小写等问题导致 `down()` 未执行，造成**卸载后数据库表和数据残留**。重装时 `up()` 的 `Schema::hasTable()` 检查发现表已存在会跳过，旧数据原封不动保留。

**解决方案**：在 `uninstall()` 中增加迁移回滚兜底，直接 `require` 迁移文件并调用 `down()` 方法，确保表一定被清理。同时删除 `migrations` 表中的对应记录，避免系统后续调 `rollbackMigrations()` 时因记录已删除而跳过（不会冲突）。

```php
public function uninstall(): void
{
    $this->rollbackMigrations();

    Cache::flush();
}

protected function rollbackMigrations(): void
{
    $migrationsPath = __DIR__ . '/Migrations';
    $migrationFiles = glob($migrationsPath . '/*.php');

    foreach (array_reverse($migrationFiles) as $file) {
        $migrationName = pathinfo($file, PATHINFO_FILENAME);

        if (!DB::table('migrations')->where('migration', $migrationName)->exists()) {
            continue;
        }

        $migration = require $file;
        if (method_exists($migration, 'down')) {
            try {
                $migration->down();

                DB::table('migrations')->where('migration', $migrationName)->delete();
            } catch (\Throwable $e) {
                Log::error('应用迁移回滚失败', [
                    'app' => 'blog',
                    'file' => basename($file),
                    'error' => $e->getMessage(),
                ]);
            }
        }
    }
}
```

关键设计说明：

| 要点 | 说明 |
| ---- | ---- |
| 逆序回滚 | `array_reverse()` 确保后建的表先删，避免外键约束问题 |
| 检查 migrations 记录 | 仅回滚 `migrations` 表中有记录的迁移，跳过未执行的迁移 |
| 删除 migrations 记录 | 回滚成功后删除记录，避免系统 `rollbackMigrations()` 重复执行 |
| down() 幂等性 | `down()` 必须使用 `Schema::dropIfExists()` 等幂等方法，确保重复调用不报错 |
| 与系统 rollbackMigrations 不冲突 | 先删 `migrations` 记录，系统后续调 `migrate:rollback` 时找不到记录，不会重复执行 |

### 迁移兜底机制

> Windows 路径分隔符导致安装时迁移未执行的问题背景详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 7 章；以下为 `Install.php` 的兜底实现规范。

系统安装流程会自动执行 `Migrations/` 目录下的迁移文件。但在某些环境下（如 Windows 路径分隔符问题），迁移可能未正确执行。为确保安装可靠性，建议在 `Install.php` 的 `install()` 方法中增加迁移兜底逻辑：

```php
<?php

namespace App\Apps\Blog;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class Install
{
    public function install(): void
    {
        $this->runMigrations();
        // 其他初始化逻辑（如种子数据）...
    }

    public function uninstall(): void
    {
        $this->rollbackMigrations();

        Cache::flush();
    }

    public function upgrade(string $fromVersion, string $toVersion): void
    {
        $this->runMigrations();
    }

    protected function runMigrations(): void
    {
        $migrationsPath = __DIR__ . '/Migrations';
        $migrationFiles = glob($migrationsPath . '/*.php');

        foreach ($migrationFiles as $file) {
            $migrationName = pathinfo($file, PATHINFO_FILENAME);

            if (DB::table('migrations')->where('migration', $migrationName)->exists()) {
                continue;
            }

            $migration = require $file;
            if (method_exists($migration, 'up')) {
                try {
                    $migration->up();

                    DB::table('migrations')->insert([
                        'migration' => $migrationName,
                        'batch' => DB::table('migrations')->max('batch') + 1,
                    ]);
                } catch (\Throwable $e) {
                    Log::error('应用迁移执行失败', [
                        'app' => 'blog',
                        'file' => basename($file),
                        'error' => $e->getMessage(),
                    ]);
                }
            }
        }
    }

    protected function rollbackMigrations(): void
    {
        $migrationsPath = __DIR__ . '/Migrations';
        $migrationFiles = glob($migrationsPath . '/*.php');

        foreach (array_reverse($migrationFiles) as $file) {
            $migrationName = pathinfo($file, PATHINFO_FILENAME);

            if (!DB::table('migrations')->where('migration', $migrationName)->exists()) {
                continue;
            }

            $migration = require $file;
            if (method_exists($migration, 'down')) {
                try {
                    $migration->down();

                    DB::table('migrations')->where('migration', $migrationName)->delete();
                } catch (\Throwable $e) {
                    Log::error('应用迁移回滚失败', [
                        'app' => 'blog',
                        'file' => basename($file),
                        'error' => $e->getMessage(),
                    ]);
                }
            }
        }
    }
}
```

> **注意**：此兜底机制使用 `__DIR__` 定位迁移文件，避免路径分隔符兼容性问题。`require` 迁移文件后直接调用 `$migration->up()` 创建表，绕过 `Artisan::call('migrate')` 在事务上下文中可能失败的问题。执行成功后必须向 `migrations` 表插入记录，防止 `php artisan migrate` 重复执行。卸载时同理，直接调用 `$migration->down()` 删除表，绕过 `Artisan::call('migrate:rollback')` 路径解析可能失败的问题，回滚成功后删除 `migrations` 表记录，防止系统 `rollbackMigrations()` 重复执行。

### ⚠️ 配置同步规范（seedDefaultConfigs）

**应用在 `manifest.json` 中声明了 `config_groups` 时，必须在 Install.php 中实现 `seedDefaultConfigs()` 方法**，并在 `install()` 和 `upgrade()` 中调用。该方法负责以 `manifest.json` 为基准同步配置组/配置项到数据库，确保安装时初始化默认值，升级时自动更新结构且不覆盖用户已设置的值。

#### 核心规则

```
seedDefaultConfigs() 以 manifest.json 为唯一基准，执行三向同步：

  新增的配置项  ──→  创建记录，写入 manifest 默认值
  保留的配置项  ──→  更新结构（name/type/tips/sort），保留用户设置的 value
  删除的配置项  ──→  删除 DB 中对应的残留记录
```

| 时机 | 行为 | 说明 |
|------|------|------|
| 安装 | 读取 manifest 创建全部配置组和配置项 | 所有配置项写入 manifest 默认值 |
| 升级 | 以 manifest 为基准做三向同步 | 新增项写入默认值，已有项保留用户值，已删除项清理残留 |
| 卸载 | `removeConfigs()` 全量清理 | 删除该应用所有配置组和配置项 |

#### 模板

```php
/**
 * 从 manifest.json 同步配置到数据库
 * - 新增配置：写入默认值
 * - 已有配置：仅更新结构（name/type/tips/sort），保留用户设置的 value
 * - 已删除配置：清理 DB 残留
 */
protected function seedDefaultConfigs(): void
{
    if (!class_exists(\App\Models\ConfigGroup::class) || !class_exists(\App\Models\ConfigItem::class)) {
        return;
    }

    $manifestPath = __DIR__ . '/manifest.json';
    if (!file_exists($manifestPath)) {
        return;
    }

    $manifest = json_decode(file_get_contents($manifestPath), true);
    $configGroups = $manifest['config_groups'] ?? [];
    $appId = '你的应用ID'; // 替换为实际 app_id

    // 1. 收集 manifest 中定义的所有配置项 code（用于清理残留）
    $manifestCodes = [];

    foreach ($configGroups as $groupDef) {
        $group = \App\Models\ConfigGroup::updateOrCreate(
            ['code' => 'app_' . $appId . '_' . $groupDef['name']],
            [
                'name' => $groupDef['title'],
                'app_id' => $appId,
                'sort' => 0,
                'status' => 1,
            ]
        );

        foreach ($groupDef['items'] as $index => $item) {
            $fullCode = 'app_' . $appId . '_' . $item['name'];
            $manifestCodes[] = $fullCode;

            $existing = \App\Models\ConfigItem::where('code', $fullCode)->first();

            if ($existing) {
                // 已有记录 → 仅更新结构信息，不覆盖用户设置的 value
                $existing->update([
                    'group_id' => $group->id,
                    'name'     => $item['title'],
                    'type'     => $item['type'] ?? 'text',
                    'tips'     => $item['tips'] ?? '',
                    'sort'     => $index,
                    'status'   => 1,
                ]);
            } else {
                // 新增配置 → 写入默认值
                \App\Models\ConfigItem::create([
                    'code'     => $fullCode,
                    'group_id' => $group->id,
                    'name'     => $item['title'],
                    'type'     => $item['type'] ?? 'text',
                    'value'    => $item['value'] ?? '',
                    'tips'     => $item['tips'] ?? '',
                    'sort'     => $index,
                    'status'   => 1,
                ]);
            }
        }
    }

    // 2. 清理 manifest 中已删除的配置项（防残留）
    \App\Models\ConfigItem::where('code', 'like', 'app_' . $appId . '_%')
        ->whereNotIn('code', $manifestCodes)
        ->delete();

    // 3. 清理 manifest 中已删除的配置组（无子项的组）
    \App\Models\ConfigGroup::where('app_id', $appId)
        ->whereDoesntHave('items')
        ->delete();
}
```

#### 强制要求

1. **manifest.json 是唯一基准**：`seedDefaultConfigs()` 必须以 `manifest.json` 的 `config_groups` 定义为唯一数据源，不得在代码中硬编码配置定义。

2. **已存在配置项禁止覆盖 value**：使用 `$existing->first()` + `update()`（不传 value），不得使用 `updateOrCreate` 第二个参数统一覆盖。

3. **必须清理删除的配置项**：manifest 移除的配置项，必须在 `seedDefaultConfigs()` 中清理 DB 残留，防止重名配置项读到旧值。

4. **install() 和 upgrade() 必须调用**：`install()` 确保首次安装写入初始化默认值；`upgrade()` 确保升级时同步新增/变更的配置结构。

5. **卸载时全量清理**：`uninstall()` 通过 `removeConfigs()` 删除该应用所有配置组和配置项，此操作不可逆。

6. **select 类型变更处理**：如果已有配置项从 select 改为其他类型（或 options 变化），由于 value 保留用户旧值可能不兼容新格式。开发者应在升级脚本中自行处理数据迁移。

***

## 十三、菜单声明

在 `manifest.json` 中声明菜单：

> **⚠️ 菜单声明硬性规范**：
> 1. **目录不声明 path**：`menus` / `user_menus` 中**含 `children` 的目录（顶级分组菜单）不得声明 `path` 字段**，禁止写 `"path": "/"`、`"path": ""` 或任何路径值。目录本身不承担路由跳转，`path` 仅由叶子菜单（children）声明。`home_menus` 为扁平结构、无目录层级，每个菜单项均为叶子导航，**必须声明 `path`**。
> 2. **code 全局唯一**：`menus` 中目录（父级）的 `code` **不得与任何子菜单的 `code` 相同**，同一 `menus` 结构内所有 `code`（含目录与子菜单）必须全局唯一，否则升级时按 `(app_id, code, terminal_type)` 幂等匹配会错乱，导致菜单被误删或角色关联丢失。

### 基本结构（独立顶级菜单）

```json
{
    "menus": [
        {
            "code": "blog",
            "title": "博客管理",
            "icon": "fa fa-book",
            "order": 100,
            "children": [
                {
                    "code": "blog_posts",
                    "title": "文章管理",
                    "icon": "fa fa-file-text",
                    "path": "/admin/blog/posts",
                    "order": 1
                },
                {
                    "code": "blog_categories",
                    "title": "分类管理",
                    "icon": "fa fa-folder",
                    "path": "/admin/blog/categories",
                    "order": 2
                }
            ]
        }
    ]
}
```

### 挂载到指定父菜单（parent 字段）

如果希望应用的菜单插入到已有的系统菜单下（而非创建新的顶级菜单），可使用 `parent` 字段：

```json
{
    "menus": [
        {
            "code": "versionmgr",
            "title": "版本管理",
            "icon": "layui-icon layui-icon-refresh",
            "order": 4,
            "parent": 15,
            "children": [
                { "code": "versionmgr_overview", "title": "版本总览", "icon": "fa fa-info-circle", "path": "/admin/versionmgr", "order": 1 },
                { "code": "versionmgr_packages", "title": "升级管理", "icon": "fa fa-upload", "path": "/admin/versionmgr/packages", "order": 2 }
            ]
        }
    ]
}
```

**效果**：当指定了 `parent` 时，不会创建「版本管理」这个中间级菜单，其 `children` 会直接挂载到「系统维护」（ID=15）菜单下。

### parent 字段说明

| 值类型            | 示例          | 匹配规则            |
| -------------- | ----------- | --------------- |
| 菜单名称（字符串）      | `"系统维护"`    | 按 `name` 字段精确匹配 |
| 菜单路径（以 `/` 开头） | `"/system"` | 按 `path` 字段精确匹配 |
| 菜单 ID（数字）      | `14`        | 按 `id` 精确查找     |

**优先级**：ID > 路径 > 名称。**推荐使用 ID**，因为菜单名称可能被管理员修改导致匹配失败。

### 菜单字段说明

| 字段         | 类型         | 必填        | 说明                                           |
| ---------- | ---------- | --------- | -------------------------------------------- |
| title      | string     | 是         | 菜单显示名称                                       |
| **code**   | string     | **否（推荐）** | **菜单稳定标识符，用于升级时幂等匹配保留菜单 ID 和角色关联。同一 `menus` 内必须全局唯一，目录 code 不得与子菜单 code 相同（硬性规范）。详见下方「菜单 code 字段」** |
| icon       | string     | 否         | 图标 CSS 类名                                    |
| path       | string     | 否         | 菜单路径，用于路由跳转。**目录（含 `children` 的顶级分组菜单）不得声明 `path` 字段（硬性规范，禁止写 `"path": "/"`），`path` 仅由叶子菜单声明** |
| order      | integer    | 否         | 排序值，越小越靠前                                    |
| **parent** | string/int | **否**     | **父菜单标识（名称/路径/ID），指定后将 children 直接挂载到该父菜单下** |
| children   | array      | 否         | 子菜单列表                                        |

> **注意**：使用 `parent` 字段时，当前菜单项本身不会被创建为可见菜单，其 `children` 将直接成为父菜单的子项。卸载应用时仅删除 `app_id` 匹配的菜单，**不影响父菜单**。

### 菜单 code 字段（推荐）

`code` 是菜单的**稳定标识符**，用于应用升级时按 code 匹配旧菜单，保留菜单 ID 和角色关联，避免升级后管理员权限丢失。

**为什么需要 code？**

未引入 code 前，菜单升级依赖 `path + parent_id + terminal_type` 三元组做幂等匹配，存在以下问题：

- 应用调整路由 path（如 `/admin/blog` 改为 `/admin/cmspro/blog`）时，旧菜单被判定为已删除并新建菜单，导致菜单 ID 变化、`admin_role_menus` 角色关联丢失
- 部分升级路径会全量删除并重建菜单，角色权限需要管理员重新分配

引入 code 字段后：

- 升级时优先按 `(app_id, code, terminal_type)` 匹配旧菜单
- 命中则保留菜单 ID 和角色关联，仅更新 `name`/`icon`/`path`/`sort` 等属性
- path 调整不影响匹配，角色关联完整保留
- code 未命中时按 `(app_id, path, terminal_type)` 兜底匹配，命中后回写 code 字段

**命名规范**：

- 仅允许小写字母、数字、下划线：`^[a-z][a-z0-9_]*$`
- 长度 ≤ 80 字符
- 同一应用、同一 `terminal_type` 下唯一
- **同一 `menus` 结构内全局唯一（硬性规范）**：目录（父级）的 `code` 不得与任何子菜单的 `code` 相同，否则升级时按 `(app_id, code, terminal_type)` 匹配会错乱，导致菜单被误删或角色关联丢失
- 推荐使用语义化命名，如 `blog_posts`、`domainmanager_settings`、`my_blog_posts`

**可选声明与兜底机制**：

- code 字段为可选，**未声明时系统按 path 自动 slug 化生成**（如 `/admin/blog/posts` → `admin_blog_posts`）作为兜底
- 但自动生成的 code 在 path 变化时也会变化，无法保证稳定，**强烈推荐开发者主动声明 code**
- 历史应用无需改造 manifest 即可继续工作，系统会自动为已安装菜单回填 code

**完整示例**：

```json
{
    "menus": [
        {
            "code": "blog",
            "title": "博客管理",
            "icon": "fa fa-book",
            "order": 100,
            "children": [
                { "code": "blog_posts", "title": "文章管理", "icon": "fa fa-file-text", "path": "/admin/blog/posts", "order": 1 },
                { "code": "blog_categories", "title": "分类管理", "icon": "fa fa-folder", "path": "/admin/blog/categories", "order": 2 }
            ]
        }
    ],
    "user_menus": [
        {
            "code": "my_blog",
            "title": "我的博客",
            "icon": "fa fa-book",
            "order": 50,
            "children": [
                { "code": "my_blog_posts", "title": "我的文章", "icon": "fa fa-file-text", "path": "/user/blog/posts", "order": 1 }
            ]
        }
    ],
    "home_menus": [
        { "code": "blog_home", "title": "博客", "path": "/blog", "order": 30 }
    ]
}
```

> **重要**：`menus`、`user_menus`、`home_menus` 中每个菜单项均支持 `code` 字段，命名规范一致。一旦声明 code，后续版本**不要修改 code 值**，否则会被识别为新菜单导致旧菜单被删除（角色关联同步清理）。如确需重命名 code，应在升级日志中明确告知管理员重新分配角色权限。

### 系统内置父菜单参考

| 名称   | 路径      | ID | 说明         |
| ---- | ------- | -- | ---------- |
| 系统   | -       | 1  | 系统根目录      |
| 系统账号 | /system | 13 | 用户、角色管理    |
| 系统设置 | -       | 14 | 站点设置、系统配置  |
| 系统维护 | -       | 15 | 日志、附件、数据管理 |
| 首页   | -       | 17 | 控制台首页      |
| 管理   | -       | 25 | 内容管理等业务模块  |
| 应用   | -       | 34 | 已装应用、应用市场  |

菜单会在安装时自动注册到 `admin_menus` 表，卸载时自动清除（仅清除 `app_id` 匹配的记录）。

### 用户端菜单声明（user\_menus）

应用可以同时注册后台管理菜单和用户端菜单。在 `manifest.json` 中使用 `user_menus` 字段声明用户端菜单，结构与 `menus` 完全一致，但注册时自动设置 `terminal_type='user'`：

```json
{
    "menus": [
        {
            "code": "blog",
            "title": "博客管理",
            "icon": "fa fa-book",
            "order": 100,
            "children": [
                { "code": "blog_posts", "title": "文章管理", "icon": "fa fa-file-text", "path": "/admin/blog/posts", "order": 1 }
            ]
        }
    ],
    "user_menus": [
        {
            "code": "my_blog",
            "title": "我的博客",
            "icon": "fa fa-book",
            "order": 50,
            "children": [
                { "code": "my_blog_posts", "title": "我的文章", "icon": "fa fa-file-text", "path": "/user/blog/posts", "order": 1 },
                { "code": "my_blog_create", "title": "写文章", "icon": "fa fa-pencil", "path": "/user/blog/create", "order": 2 }
            ]
        }
    ]
}
```

`user_menus` 同样支持 `parent` 字段，可挂载到用户端已有父菜单下。用户端内置父菜单参考：

| 名称   | 路径 | 说明     |
| ---- | -- | ------ |
| 用户中心 | -  | 用户端根目录 |

> **注意**：`user_menus` 中**含 `children` 的目录不得声明 `path` 字段**（硬性规范，同 `menus`），`path` 仅由叶子菜单声明；叶子菜单的 `path` 必须以 `/user/` 开头，与用户端路由前缀对应。卸载应用时，`user_menus` 注册的菜单同样通过 `app_id` 自动清除。

### 官网前端菜单声明（home\_menus）

应用可以在 `manifest.json` 中使用 `home_menus` 字段声明官网前端导航菜单，注册时自动设置 `terminal_type='home'`：

```json
{
    "home_menus": [
        { "code": "home", "title": "首页", "path": "/", "order": 1 },
        { "code": "about", "title": "系统介绍", "path": "/about", "order": 2 },
        { "code": "news", "title": "新闻动态", "path": "/news", "order": 3 },
        { "code": "help", "title": "帮助中心", "path": "/help", "order": 4 }
    ]
}
```

`home_menus` 与 `menus`/`user_menus` 的区别：

| 维度 | `menus` | `user_menus` | `home_menus` |
| ---- | ------- | ------------ | ------------ |
| 终端类型 | `admin` | `user` | `home` |
| 认证要求 | 需登录 | 需登录 | 公开访问 |
| 支持子菜单 | 是（children） | 是（children） | 否（扁平结构） |
| 支持父级挂载 | 是（parent） | 是（parent） | 否 |
| 支持 code 字段 | 是（推荐） | 是（推荐） | 是（推荐） |
| 路由前缀 | `/admin/{appId}` | `/user/{appId}` | 无前缀或自定义 |

> **注意**：`home_menus` 为扁平结构，不支持 `children` 和 `parent` 字段，**不存在目录层级**，每个菜单项均为叶子导航，**必须声明 `path`** 指向实际页面路由（如首页 `"path": "/"`）。官网前端菜单通常为一级导航，无需层级嵌套。卸载应用时，`home_menus` 注册的菜单同样通过 `app_id` 自动清除。

***

## 十四、配置声明

在 `manifest.json` 中声明配置组，安装时系统会自动将配置组和配置项注册到数据库。

### 基本结构

```json
{
    "config_groups": [
        {
            "name": "blog_settings",
            "title": "博客设置",
            "items": [
                {
                    "name": "posts_per_page",
                    "title": "每页文章数",
                    "type": "number",
                    "value": "10"
                },
                {
                    "name": "allow_comments",
                    "title": "允许评论",
                    "type": "switch",
                    "value": "1"
                },
                {
                    "name": "default_category",
                    "title": "默认分类",
                    "type": "select",
                    "value": "1",
                    "options": [
                        { "label": "技术", "value": "1" },
                        { "label": "生活", "value": "2" },
                        { "label": "随笔", "value": "3" }
                    ]
                }
            ]
        }
    ]
}
```

### 配置项类型

| 类型       | 说明   | value 格式         |
| -------- | ---- | ---------------- |
| text     | 文本输入 | 字符串              |
| number   | 数字输入 | 数字字符串（如 `"10"`）  |
| switch   | 开关   | `"0"` 或 `"1"`    |
| select   | 下拉选择 | 需配合 `options` 字段 |
| textarea | 多行文本 | 字符串              |
| image    | 图片选择 | 图片路径字符串          |
| password | 密码输入 | 字符串（后台显示为掩码）     |

### 字段说明

#### 配置组字段

| 字段    | 类型     | 必填 | 说明                   |
| ----- | ------ | -- | -------------------- |
| name  | string | 是  | 配置组标识，仅允许小写字母、数字、下划线 |
| title | string | 是  | 配置组显示名称              |
| items | array  | 是  | 配置项列表                |

#### 配置项字段

| 字段      | 类型     | 必填 | 说明                                    |
| ------- | ------ | -- | ------------------------------------- |
| name    | string | 是  | 配置项标识，仅允许小写字母、数字、下划线                  |
| title   | string | 是  | 配置项显示名称                               |
| type    | string | 是  | 配置项类型，见上方类型表                          |
| value   | string | 否  | 默认值，所有类型均以字符串形式存储                     |
| options | array  | 否  | select 类型的选项列表，每项包含 `label` 和 `value` |
| tips    | string | 否  | 配置项提示信息，显示在输入框下方，用于说明配置项用途或格式要求       |

### 命名空间与存储规则

系统会自动为应用配置添加前缀，确保不同应用之间的配置不会冲突：

**配置组 code 规则：** `app_{应用id}_{配置组name}`

例如应用 `blog` 中 `name` 为 `blog_settings` 的配置组，存储到数据库的 code 为 `app_blog_blog_settings`。

**配置项 code 规则：** `app_{应用id}_{配置项name}`

例如应用 `blog` 中 `name` 为 `posts_per_page` 的配置项，存储到数据库的 code 为 `app_blog_posts_per_page`。

> **注意：** 在 `manifest.json` 中只需写原始 name，系统在安装时自动添加前缀。不要在 name 中手动添加 `app_` 前缀。

### 读取配置

在代码中通过数据库直接读取应用配置：

```php
use App\Models\ConfigItem;

$item = ConfigItem::where('code', 'app_blog_posts_per_page')->first();
$perPage = $item ? (int) $item->value : 10;
```

也可以通过应用配置服务读取：

```php
use App\Services\AppManagerService;

$manager = app(AppManagerService::class);
$result = $manager->getAppConfig('blog');
```

### ⚠️ 注意事项

1. **name 命名规范：** 配置组和配置项的 `name` 只能使用小写字母、数字和下划线，不要使用中文或特殊字符。
2. **配置项唯一性：** 不同应用的配置项 `name` 可以相同（系统会自动加前缀区分），但同一应用内的配置项 `name` 必须唯一。
3. **系统配置组不可删除：** 系统内置的配置组（基础配置、上传配置、安全配置、邮箱设置）受保护，不允许通过 API 删除或修改其 code。
4. **升级时配置同步：** 应用升级时，系统会自动同步 `manifest.json` 中新增的配置组和配置项。已有配置项的值不会被覆盖（用户修改过的配置会保留）。
5. **卸载时配置清除：** 应用卸载时，该应用的所有配置组和配置项会被级联删除，此操作不可逆。
6. **select 类型必须提供 options：** 使用 `select` 类型时，`options` 字段为必填，格式为 `[{ "label": "显示文本", "value": "存储值" }]`。
7. **value 统一为字符串：** 无论配置项类型是 number 还是 switch，`value` 字段都以字符串形式存储和声明（如 `"10"` 而非 `10`，`"1"` 而非 `true`）。
8. **tips 提示信息：** `tips` 字段会在配置表单中输入框下方显示为灰色提示文字，建议为以下类型的配置项填写 tips：
   - **URL 类配置**：提示完整路径格式，如 `"路径：{域名}/api/onlinepay/v1/notify/wechat"`
   - **路径类配置**：说明相对路径基准目录，如 `"相对于storage路径，如certs/wechat/apiclient_key.pem"`
   - **密钥类配置**：说明密钥格式要求，如 `"RSA2私钥，不含头尾标记"`
   - **数值类配置**：说明取值范围和单位，如 `"超时时间，单位：分钟，范围1-1440"`
   - tips 在安装时写入数据库，升级时已有记录的 tips 会被更新为最新值（value 不会被覆盖）

9. **应用层 group_code 必须与 manifest 一致（重要，踩坑记录）：** 该问题（唯一键冲突的根因、诊断 SQL 与清理脚本）详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 8 章；当应用自定义 `SettingsApiController` 等代码直接写库 `config_items` 时，使用的 `group_code` 必须与 `manifest.json` 中 `config_groups[].name` 经系统前缀化后的 `app_{应用id}_{group_name}` 完全一致。

   **背景：** 系统安装/升级应用时统一走 `AppInstallerService::registerConfigGroups` 按 manifest 注册配置组和配置项。如果应用层自定义代码使用了不同的 group_code，会造成两套并存：
   - 系统按 manifest 注册到 `app_xxx_dns_provider` 等标准 group 下
   - 应用层保存时通过 `updateOrCreate(['code' => $code], ['group_id' => ...])` 把现有记录的 group_id 改写到自创的 `app_xxx` group 下

   长期累积形成脏数据后，再次升级时触发唯一键冲突（`config_items_group_code_unique`），升级失败，错误形如：
   ```
   SQLSTATE[23000]: Integrity constraint violation: 1062 Duplicate entry
   '20-app_cmspro_domainmanager_dns_provider_type' for key 'config_items_group_code_unique'
   ```

   **错误示例：**
   ```php
   // manifest 中 config_groups 用了 dns_provider/domain_settings/expire_settings 三个 group
   // 但应用层写死了一个不一致的 group_code：
   private const CONFIG_GROUP_CODE = 'app_cmspro_domainmanager';  // ❌ 缺少 _dns_provider 等后缀

   private function saveConfig(string $code, string $value): void
   {
       ConfigItem::updateOrCreate(
           ['code' => $code],
           [
               'group_id' => $this->ensureConfigGroup()->id,  // ❌ 把现有记录 group_id 改到自创组
               'name' => $code,
               'value' => $value,
               'type' => 'text',
           ]
       );
   }
   ```

   **正确做法：**
   - 应用层保存配置时，根据 code 解析对应的 manifest group_name，使用 `app_{应用id}_{group_name}` 作为 group_code
   - 或使用 `updateOrCreate(['code' => $code, 'group_id' => $group->id], [...])` 同时以 code+group_id 作为匹配条件
   - 写入前先清理其他 group 下相同 code 的历史残留，杜绝脏数据：
     ```php
     ConfigItem::where('code', $code)
         ->where('group_id', '!=', $group->id)
         ->delete();
     ```

   **诊断方法：** 当出现 `Duplicate entry 'XX-app_xxx_yyy' for key 'config_items_group_code_unique'` 错误时，用以下 SQL 检查是否存在非 manifest group 下的脏数据：
   ```sql
   SELECT g.id, g.code AS group_code, i.id AS item_id, i.code AS item_code
   FROM config_groups g
   LEFT JOIN config_items i ON i.group_id = g.id
   WHERE g.app_id = '{应用id}'
   ORDER BY g.code, i.id;
   ```

   **清理脚本模板：** 确认存在脏数据后，按以下步骤清理（执行前请备份数据库）：
   ```sql
   -- 1. 删除非 manifest 标准组下的配置项残留
   DELETE FROM config_items
   WHERE code LIKE 'app_{应用id}_{prefix}%'
     AND group_id NOT IN (
       SELECT id FROM (
         SELECT id FROM config_groups
         WHERE app_id = '{应用id}'
           AND code IN ('app_{应用id}_{group1}', 'app_{应用id}_{group2}', ...)
       ) AS t
     );

   -- 2. 删除应用自创的非 manifest 标准组
   DELETE FROM config_groups
   WHERE app_id = '{应用id}'
   AND code NOT IN ('app_{应用id}_{group1}', 'app_{应用id}_{group2}', ...);

   -- 3. 检查 manifest 标准组内是否仍有重复 code 残留
   SELECT code, COUNT(*) AS cnt, GROUP_CONCAT(id) AS dup_ids
   FROM config_items
   WHERE code LIKE 'app_{应用id}_{prefix}%'
   GROUP BY code
   HAVING cnt > 1;

   -- 4. 若上一步发现重复，保留 id 最小那条
   DELETE FROM config_items
   WHERE code LIKE 'app_{应用id}_{prefix}%'
     AND id NOT IN (
       SELECT min_id FROM (
         SELECT MIN(id) AS min_id FROM config_items
         WHERE code LIKE 'app_{应用id}_{prefix}%'
         GROUP BY code
       ) AS t
     );
   ```

***

## 十四A、后台设置页面开发

`manifest.json` 的 `config_groups` 仅声明配置项元数据（写入 `config_items` 表），系统不会自动为应用生成可视化的设置界面。当应用需要后台可视化配置入口时，需按本节规范自行开发「后台设置页面」。

> **参考实现**：`app/Apps/CmsproForum/Views/Admin/settings/index.blade.php` + `Controllers/Admin/SettingController.php`

### 12A.1 适用场景

| 场景 | 是否需要开发独立设置页面 |
| ---- | ---------------------- |
| 配置项少于 3 项，类型简单 | 否，可由系统通用配置管理界面维护 |
| 配置项需要分组展示、带说明文案 | 是 |
| 配置项之间存在联动（如开关控制子项是否可编辑） | 是 |
| 需要保存后执行副作用（清缓存、写日志、同步外部） | 是 |
| 配置项包含 textarea（如违禁词列表）、需自定义排版 | 是 |

### 12A.2 目录与路由约定

```
app/Apps/{AppName}/
├── Controllers/Admin/SettingController.php
├── Routes/admin.php
└── Views/Admin/settings/index.blade.php
```

**路由声明**（页面路由 + API 路由分离）：

```php
// Routes/admin.php

// 页面路由（返回 HTML 视图）
Route::get('/settings', [SettingController::class, 'index'])
    ->name('admin.{app_id}.settings');

// API 路由（返回 JSON）
Route::prefix('api')->group(function () {
    Route::get('/settings', [SettingController::class, 'getSettings']);
    Route::put('/settings', [SettingController::class, 'update']);
});
```

> **菜单声明**：在 `manifest.json` 的 `menus` 中为 `/admin/{app_id}/settings` 声明一条菜单项（如"论坛设置"），并配 `code` 字段（如 `admin_cmspro_forum_settings`），否则后台左侧导航不会出现入口。

### 12A.3 Controller 实现规范

`SettingController` 必须包含三个核心方法：`index()`（渲染页面）、`getSettings()`（API 返回当前配置）、`update()`（保存配置）。

#### 配置项 code 前缀

应用配置项 code 统一遵循 `app_{应用id}_{配置项name}` 格式（见第十四章「命名空间与存储规则」），Controller 内应定义常量复用：

```php
class SettingController extends Controller
{
    /**
     * 应用配置项 code 前缀（注意：应用 id 中的点号需转为下划线）
     * 例：应用 id 为 cmspro.forum → 前缀为 app_cmspro_forum_
     */
    private const CONFIG_PREFIX = 'app_cmspro_forum_';
}
```

#### 白名单机制（强制）

`update()` 必须维护 **`ALLOWED_KEYS` 白名单常量**，仅接受明确列出的配置项，防止前端传入任意 code 篡改其他应用配置：

```php
private const ALLOWED_KEYS = [
    'access_mode', 'access_domain', 'access_path',
    'topic_review', 'reply_review',
    'topics_per_page', 'replies_per_page',
    'home_topics_per_page', 'sub_replies_per_page',
    'flood_interval', 'flood_max_per_hour',
    'allow_reward', 'points_enabled', 'banned_words',
    'forum_title', 'forum_description', 'forum_keywords',
];

public function update(Request $request)
{
    $data = $request->only(self::ALLOWED_KEYS);
    // ...后续保存逻辑
}
```

> **⚠️ 禁止**使用 `$request->all()` 或 `$request->except(...)` 接收配置项，必须用白名单显式枚举。

#### 渲染页面（index 方法）

读取配置时优先取 `ConfigItem` 表中的当前值，缺失时回退到 `config()` 默认值，避免首次安装尚未写入数据库时报错：

```php
public function index()
{
    $configKeys = self::ALLOWED_KEYS;

    $configs = [];
    foreach ($configKeys as $key) {
        $item = ConfigItem::where('code', self::CONFIG_PREFIX . $key)->first();
        // 优先取数据库值，回退到 Config/{app}.php 中的默认值
        $configs[$key] = $item ? $item->value : config('apps.cmspro.forum.' . $key, '');
    }

    return view('cmspro.forum::Admin.settings.index', compact('configs'));
}
```

#### 保存配置（update 方法）

写入时 **必须正确指定 `group_id`**（指向 manifest 中声明的配置组），不可写 `0` 或随意写一个不存在的 group，否则会触发第十四章第 9 条「group_code 必须与 manifest 一致」中描述的脏数据问题。

```php
public function update(Request $request)
{
    $data = $request->only(self::ALLOWED_KEYS);

    // 解析配置项所属的 group_id（按 manifest 声明匹配）
    $groupMap = $this->resolveConfigGroupMap();

    foreach ($data as $key => $value) {
        $code = self::CONFIG_PREFIX . $key;
        $groupId = $groupMap[$key] ?? 0;

        ConfigItem::updateOrCreate(
            ['code' => $code],
            [
                'value'    => $value,
                'group_id' => $groupId,
                'name'     => $key,
                'type'     => 'text',
                'status'   => 1,
            ]
        );

        // 清除业务层缓存（如有）
        Cache::forget("forum:config:{$key}");
    }

    // 涉及路由的配置（如 access_mode/access_path）变更后必须清缓存
    Artisan::call('route:clear');
    Artisan::call('config:clear');

    return response()->json(['code' => 0, 'msg' => '配置更新成功', 'data' => null]);
}
```

> **⚠️ 踩坑提醒**：CmsproForum 早期版本的 `SettingController::update()` 直接写 `'group_id' => 0`，导致配置项脱离 manifest 声明的 group，升级时可能触发 `config_items_group_code_unique` 唯一键冲突。新开发的应用应通过 `resolveConfigGroupMap()` 查询 `config_groups` 表得到正确的 `group_id`。

### 12A.4 视图实现规范

设置页面视图位于 `Views/Admin/settings/index.blade.php`，使用 **完整 HTML 结构**（不继承 `layouts.admin`），由后台菜单 iframe 加载。

#### 完整模板

```blade
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{应用名}设置</title>
    <link rel="stylesheet" href="{{ asset('CmsProUi/component/pear/css/pear.css') }}">
    <link rel="stylesheet" href="{{ asset('CmsProUi/font-awesome/4.7.0/css/font-awesome.min.css') }}">
    <link rel="stylesheet" href="{{ asset('Admin/css/admin.css') }}">
    <link rel="stylesheet" href="{{ asset('Admin/css/variables.css') }}">
    <link rel="stylesheet" href="{{ asset('Admin/css/reset.css') }}">
    <style>
        /* 分组标题样式 */
        .settings-group-title { font-size: 15px; font-weight: 600; color: #1e293b;
            padding: 12px 0 8px; border-bottom: 1px solid #f1f5f9; margin-bottom: 16px; }
        .settings-group-title i { margin-right: 6px; color: #2563eb; }
        /* 表单标签宽度统一 */
        .layui-form-label { width: 140px; }
        .layui-input-block { margin-left: 170px; }
        .layui-form-item .layui-input-inline { width: 200px; }
    </style>
</head>
<body>
<div class="pear-container">
    <form class="layui-form" lay-filter="settings-form">

        {{-- 配置分组1（按 manifest 的 config_groups 划分） --}}
        <div class="layui-card">
            <div class="layui-card-header"><i class="fa fa-eye"></i> 显示设置</div>
            <div class="layui-card-body">
                <div class="layui-form-item">
                    <label class="layui-form-label">每页条数</label>
                    <div class="layui-input-block">
                        <input type="number" name="topics_per_page"
                               value="{{ $configs['topics_per_page'] ?? 20 }}"
                               min="5" max="100" class="layui-input" style="width:120px;">
                        <div class="layui-form-mid layui-word-aux">帖子列表每页显示条数</div>
                    </div>
                </div>

                {{-- 开关字段：使用 lay-skin="switch" --}}
                <div class="layui-form-item">
                    <label class="layui-form-label">发帖审核</label>
                    <div class="layui-input-block">
                        <input type="checkbox" name="topic_review" lay-skin="switch"
                               lay-text="开启|关闭"
                               {{ ($configs['topic_review'] ?? false) ? 'checked' : '' }}>
                        <div class="layui-form-mid layui-word-aux">开启后新帖需审核才能显示</div>
                    </div>
                </div>

                {{-- 下拉框 --}}
                <div class="layui-form-item">
                    <label class="layui-form-label">访问模式</label>
                    <div class="layui-input-block">
                        <select name="access_mode">
                            <option value="path" {{ ($configs['access_mode'] ?? 'path') === 'path' ? 'selected' : '' }}>路径前缀</option>
                            <option value="domain" {{ ($configs['access_mode'] ?? 'path') === 'domain' ? 'selected' : '' }}>域名绑定</option>
                        </select>
                    </div>
                </div>

                {{-- 多行文本 --}}
                <div class="layui-form-item">
                    <label class="layui-form-label">违禁词列表</label>
                    <div class="layui-input-block">
                        <textarea name="banned_words" class="layui-textarea"
                                  placeholder="每行一个违禁词">{{ $configs['banned_words'] ?? '' }}</textarea>
                    </div>
                </div>
            </div>
        </div>

        {{-- 提交按钮 --}}
        <div style="padding: 20px 0; text-align: center;">
            <button type="button" class="layui-btn layui-btn-lg" id="save-settings">
                <i class="layui-icon layui-icon-ok"></i> 保存设置
            </button>
        </div>
    </form>
</div>

<script src="{{ asset('CmsProUi/component/layui/layui.js') }}"></script>
<script src="{{ asset('CmsProUi/component/pear/pear.js') }}"></script>
<script>
layui.use(['form', 'jquery', 'common'], function() {
    var form = layui.form;
    var $ = layui.jquery;
    var layer = layui.layer;

    // CSRF Token 全局配置（所有 AJAX 自动携带）
    $.ajaxSetup({
        headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}' }
    });

    form.render();

    // 开关字段名列表（checkbox 提交时不会出现在 serialize 中，需单独收集）
    var switchFields = ['topic_review', 'reply_review', 'allow_reward', 'points_enabled'];

    $('#save-settings').on('click', function() {
        var formData = {};

        // 收集 input/textarea/select
        $('.layui-form input[type="text"], .layui-form input[type="number"], '
          + '.layui-form textarea, .layui-form select').each(function() {
            var name = $(this).attr('name');
            if (name) formData[name] = $(this).val();
        });

        // 单独收集开关字段，转为 '1' / '0'
        switchFields.forEach(function(field) {
            var checked = $('input[name="' + field + '"]').is(':checked');
            formData[field] = checked ? '1' : '0';
        });

        var loadIdx = layer.load(2);
        $.ajax({
            url: '/admin/{app_id}/api/settings',
            type: 'PUT',
            contentType: 'application/json',
            data: JSON.stringify(formData),
            success: function(res) {
                layer.close(loadIdx);
                if (res.code === 0) {
                    layer.msg('保存成功', { icon: 1, time: 1500 });
                } else {
                    layer.msg(res.msg || '保存失败', { icon: 2 });
                }
            },
            error: function(xhr) {
                layer.close(loadIdx);
                if (xhr.status === 401) {
                    layer.msg('登录已过期，请刷新页面', { icon: 2 });
                } else {
                    layer.msg('网络错误，请重试', { icon: 2 });
                }
            }
        });
    });
});
</script>
</body>
</html>
```

### 12A.5 关键实现要点

| 要点 | 说明 |
| ---- | ---- |
| **完整 HTML 结构** | 设置页面是独立 iframe 入口，必须包含 `<!DOCTYPE html>`、`<head>`、`<body>`，不继承 `layouts.admin` |
| **资源引用** | 必须用 `{{ asset() }}` 引用 layui/pear/font-awesome 等系统资源，禁止 CDN（见 6.4 节） |
| **CSRF Token** | 在 `$.ajaxSetup` 中统一注入 `X-CSRF-TOKEN` 头，避免每个请求重复配置 |
| **开关字段单独收集** | `lay-skin="switch"` 的 checkbox 不会被 jQuery `serialize` 收集，必须在 `switchFields` 数组中显式列出并用 `:checked` 判断转为 `'1'/'0'` |
| **value 字符串化** | 后端 `ConfigItem.value` 字段为字符串类型，前端提交的数字、布尔值都应转为字符串（`'1'`/`'0'`/`'20'`） |
| **401 处理** | AJAX 错误回调必须判断 `xhr.status === 401` 提示「登录已过期」，与项目其他 AJAX 保持一致 |
| **分组展示** | 用 `layui-card` 包裹同一 `config_group` 下的配置项，卡片标题用 `<i class="fa fa-xxx"></i>` 配图标 |
| **默认值兜底** | 视图中所有 `{{ $configs['key'] ?? '默认值' }}` 必须带默认值，避免首次安装数据库无记录时显示空白 |
| **缓存清理** | `update()` 保存后必须执行 `Artisan::call('route:clear')` 和 `Artisan::call('config:clear')`，否则涉及路由的配置（如 `access_mode`）不会生效 |
| **业务缓存清理** | 若应用在 Service 层对配置做了缓存（如 `Cache::forget("forum:config:{$key}")`），保存时必须同步清除 |
| **密钥字段明文回显** | 设置表单中的密钥/口令/Key/密码等凭据字段，保存后必须通过 `value="{{ $configs['xxx'] ?? '' }}"` **直接明文回显**已保存的值。**禁止**用 `placeholder="已配置（留空保持不变）"` 等占位符方式隐藏已存值，也**无需**加密保存后再解密回显。需修改凭据时，直接在文本框内输入新值覆盖保存即可 |

### 12A.6 manifest.json 与设置页面的字段对应

设置页面表单中的 `name` 属性必须与 `manifest.json` 中 `config_groups[].items[].name` 完全一致，系统安装时会按 manifest 注册到 `config_items` 表，code 为 `app_{应用id}_{name}`：

```json
// manifest.json
{
    "config_groups": [{
        "name": "post_settings",
        "title": "发帖设置",
        "items": [{
            "name": "topic_review",        // ← 与下方 input name 一致
            "title": "发帖审核",
            "type": "switch",
            "value": "0",
            "tips": "开启后新帖需审核后才能显示"
        }]
    }]
}
```

```blade
{{-- Views/Admin/settings/index.blade.php --}}
<input type="checkbox" name="topic_review" lay-skin="switch"
       lay-text="开启|关闭"
       {{ ($configs['topic_review'] ?? false) ? 'checked' : '' }}>
```

> **字段对应检查清单**：
> 1. 视图 `name` 属性 ↔ manifest `items[].name` ↔ `ALLOWED_KEYS` 常量 ↔ `CONFIG_PREFIX . $key` 拼接的 code
> 2. 任一环节字段名不一致都会导致：保存成功但实际未写入 / 读取时取不到值 / 升级时被识别为新配置项而清空用户已设值

### 12A.7 与系统内置配置管理界面的关系

系统在 `/admin/config` 提供了通用的配置管理界面，会自动列出所有 `config_groups` 下的配置项并按 `type` 渲染表单。应用是否还需要开发独立的设置页面，取决于：

- **简单场景**：配置项 ≤ 3 项、无分组需求、无副作用 → 可直接复用 `/admin/config`，无需开发
- **复杂场景**：配置项多、需分组卡片展示、需自定义说明文案、保存后需清缓存或同步外部 → 按本节规范开发独立设置页面

两种方式 **共享同一份 `config_items` 数据**，互不冲突；用户从任一入口修改都会写入同一行记录。

### 12A.8 常见问题

> 配置设置页常见问题（保存后不刷新、开关存为 `on`、升级唯一键冲突、修改模式路由不生效、AJAX 419、无菜单入口、无配置记录报错等）详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 9 章。

***

## 十五、权限声明

在 `manifest.json` 中声明权限，**推荐使用对象格式**（支持中文名称）：

### 对象格式（推荐）

```json
{
    "permissions": [
        { "code": "blog.manage", "name": "博客管理" },
        { "code": "blog.post.create", "name": "创建文章" },
        { "code": "blog.post.edit", "name": "编辑文章" },
        { "code": "blog.post.delete", "name": "删除文章" },
        { "code": "blog.category.manage", "name": "分类管理" }
    ]
}
```

### 字段说明

| 字段   | 类型     | 必填 | 说明                                    |
| ---- | ------ | -- | ------------------------------------- |
| code | string | 是  | 权限标识码，格式为 `{app_id}.{功能点}`，用于代码中的权限判断 |
| name | string | 是  | 权限中文名称，显示在角色管理的权限列表中。未指定时降级使用 code 值  |

### 命名规范

- **code 值**：仅允许小写字母、数字和点号，格式为 `{app_id}.{模块}.{操作}`
- **name 值**：必须使用中文，简洁明了地描述权限含义

### 示例对照表

| code                        | name  | 说明       |
| --------------------------- | ----- | -------- |
| `versionmgr.manage`         | 版本管理  | 最高管理权限   |
| `versionmgr.check`          | 版本检查  | 查看版本信息   |
| `versionmgr.upgrade`        | 执行升级  | 执行系统升级操作 |
| `versionmgr.package.upload` | 上传升级包 | 上传升级包文件  |
| `payment.order.view`        | 查看订单  | 只读查看订单列表 |
| `payment.channel.create`    | 创建渠道  | 新增支付渠道   |

### 兼容说明

系统同时兼容旧版字符串格式（向后兼容），但新应用应统一使用对象格式：

```json
// 旧格式（仍可正常工作，但不推荐）
"permissions": ["blog.manage", "blog.post.create"]

// 新格式（推荐）
"permissions": [
    { "code": "blog.manage", "name": "博客管理" },
    { "code": "blog.post.create", "name": "创建文章" }
]
```

权限会在安装时自动注册到 `admin_permissions` 表（`name` 字段写入中文），卸载时自动清除。管理员需要在角色管理中分配权限后才能生效。

### 代码中使用权限

```php
// 控制器或中间件中判断权限
if (!auth('admin')->user()->can('blog.post.create')) {
    abort(403, '无权操作');
}

// 路由定义时绑定权限
Route::post('/posts', [PostController::class, 'store'])
    ->middleware('can:blog.post.create');
```

### 前端按钮权限控制

除了后端中间件校验，系统提供了前端按钮权限控制机制，用于在 UI 层隐藏/拦截无权限的操作按钮，提升用户体验。

#### 权限脚本注入

后台列表页（独立 HTML 页面，通过 iframe 加载）**必须**在 `</head>` 之前注入权限脚本：

```html
@include('admin.partials.permission-script')
```

该片段会注入 `window.CMSPRO_PERMISSIONS`（当前用户权限列表，超管为 `['*']`）和 `window.hasPermission(code)` 函数。

> **重要**：子页面（iframe）不会继承父页面的 `window` 变量，必须自行注入权限脚本，否则 `window.hasPermission` 为 `undefined`，所有权限检查都会失败（按钮被错误隐藏）。

#### 工具栏按钮权限控制

给操作按钮添加 `data-permission` 属性：

```html
<button class="layui-btn layui-btn-sm" lay-event="add" data-permission="admin.role.store">
    <i class="layui-icon layui-icon-add-1"></i> 新增
</button>
```

JS 中遍历隐藏无权限按钮：

```javascript
var hidePermButtons = function() {
    $('button[data-permission]').each(function() {
        if (!window.hasPermission || !window.hasPermission($(this).data('permission'))) {
            $(this).hide();
        }
    });
};
hidePermButtons();
```

#### dropdown 菜单权限过滤

给 dropdown 菜单项添加 `permission` 属性并过滤：

```javascript
dropdown.render({
    data: [
        { title: '编辑', id: 'Edit', permission: 'admin.role.update' },
        { title: '删除', id: 'Delete', permission: 'admin.role.destroy' }
    ].filter(function(item) {
        return !item.permission || !window.hasPermission || window.hasPermission(item.permission);
    }),
    click: function(menuData) { /* ... */ }
});
```

#### 操作拦截

在执行操作前检查权限：

```javascript
if (!window.hasPermission || !window.hasPermission('admin.role.destroy')) {
    layer.msg('无操作权限', { icon: 2, time: 1000 });
    return;
}
```

> **注意**：前端权限控制仅为 UX 优化，不能替代后端 `CheckPermission` 中间件校验。后端校验是安全兜底，前端控制是体验优化。

***

## 十五A、用户扩展字段

系统提供用户扩展字段机制，允许应用为后台用户（`admin_users`）和前台用户（`users`）动态添加自定义字段，无需修改用户主表结构。

### 数据表结构

| 表名 | 用途 |
|------|------|
| `admin_user_ext_fields` | 后台用户扩展字段定义 |
| `admin_user_ext_data` | 后台用户扩展字段数据 |
| `user_ext_fields` | 前台用户扩展字段定义 |
| `user_ext_data` | 前台用户扩展字段数据 |

### 支持的字段类型

| field_type | 说明 | 渲染方式 |
|------------|------|----------|
| text | 文本输入 | `<input type="text">` |
| number | 数字输入 | `<input type="number">` |
| select | 下拉选择（支持多选） | 单选渲染 `<select>`，多选渲染 checkbox 组（选项由 `field_options` 定义，支持静态选项和动态数据源，详见下方多选模式） |
| textarea | 多行文本 | `<textarea>` |
| switch | 开关 | `<input type="checkbox" lay-skin="switch">` |
| date | 日期选择 | `<input>` + layui.laydate |
| json | JSON数据 | `<textarea>`（JSON编辑） |

### `field_options` 配置

`select` 类型字段的 `field_options` 支持两种形式：

#### 1. 静态选项（数组）

```php
'field_options' => [
    ['label' => '选项1', 'value' => '1'],
    ['label' => '选项2', 'value' => '2'],
]
```

#### 2. 动态数据源（推荐用于选项会变化的场景）

适用于选项来源于应用业务数据（如医院列表、部门列表等）的场景。新增业务数据后下拉选项自动更新，无需同步维护。

```php
'field_options' => [
    'source' => [
        'url' => '/api/admin/your-app/items',   // 数据源 API 地址
        'label_key' => 'name',                   // 显示文本对应的字段名
        'value_key' => 'id',                     // 选项值对应的字段名
    ],
]
```

**数据源 API 要求**：
- 必须是 GET 请求，返回 JSON 格式 `{code: 0, data: [...]}`
- `data` 可以是数组（如 `[{"id":1,"name":"医院A"}]`），也可以是分页对象（`{data: {items: [...]}}`）
- API 复用应用已有的列表接口，无需额外开发
- 鉴权：用户编辑表单在管理员登录态下发起，天然带 Session，无需额外处理

**渲染流程**：
1. 表单加载时先渲染空的 select 占位
2. 前端根据 `source.url` 发起 AJAX 拉取数据
3. 用 `label_key`/`value_key` 映射生成 `<option>` 并填充
4. 若是编辑模式，自动选中当前用户的字段值

#### 3. 多选模式

`select` 类型字段支持多选，通过在 `field_options` 中设置 `multiple: true` 启用。

多选模式兼容上述两种选项来源：

```php
// 静态选项 + 多选
'field_options' => [
    'multiple' => true,
    'options' => [                          // 注意：静态多选时选项放在 options 键下
        ['label' => '标签1', 'value' => '1'],
        ['label' => '标签2', 'value' => '2'],
        ['label' => '标签3', 'value' => '3'],
    ],
]

// 动态数据源 + 多选
'field_options' => [
    'multiple' => true,
    'source' => [
        'url' => '/api/admin/your-app/items',
        'label_key' => 'name',
        'value_key' => 'id',
    ],
]
```

**多选行为说明**：
- **前端渲染**：多选字段渲染为 checkbox 组（layui primary 风格），而非 `<select multiple>`
- **数据存储**：多选值以 JSON 数组形式存入 `field_value` 字段（如 `["1","2","3"]`），TEXT 列兼容
- **读取回填**：`getAdminUserExtData()` / `getUserExtData()` 返回数组（如 `["1", "2"]`），详情页展示为 `、` 分隔的文本
- **向后兼容**：已有的单选字段数据不受影响，未启用 `multiple` 的字段保持之前的行为

**管理界面操作**：
- 在扩展字段管理弹窗中，`select` 类型字段会显示「多选」开关
- 开启后，字段定义的 `field_options` 自动写入 `multiple: true`
- 编辑已有字段时，多选开关根据 `field_options.multiple` 自动回填

### 应用安装时注册扩展字段

在 `Install.php` 的 `install()` 方法中创建扩展字段：

```php
use App\Models\AdminUserExtField;

protected function seedExtFields(): void
{
    $fields = [
        ['field_name' => 'staff_no', 'field_label' => '工号', 'field_type' => 'text', 'sort' => 1],
        ['field_name' => 'specialty', 'field_label' => '专长', 'field_type' => 'textarea', 'sort' => 2],
        // 动态数据源示例：所属医院下拉框
        [
            'field_name' => 'hospital_id',
            'field_label' => '所属医院',
            'field_type' => 'select',
            'field_options' => [
                'source' => [
                    'url' => '/api/admin/your-app/hospitals',
                    'label_key' => 'name',
                    'value_key' => 'id',
                ],
            ],
            'sort' => 3,
        ],
        // 多选动态数据源示例：服务项目下拉框（可多选）
        [
            'field_name' => 'service_items',
            'field_label' => '服务项目',
            'field_type' => 'select',
            'field_options' => [
                'multiple' => true,
                'source' => [
                    'url' => '/api/admin/your-app/services',
                    'label_key' => 'name',
                    'value_key' => 'id',
                ],
            ],
            'sort' => 4,
        ],
        // 多选静态选项示例：兴趣标签
        [
            'field_name' => 'interests',
            'field_label' => '兴趣标签',
            'field_type' => 'select',
            'field_options' => [
                'multiple' => true,
                'options' => [
                    ['label' => '运动', 'value' => 'sports'],
                    ['label' => '音乐', 'value' => 'music'],
                    ['label' => '阅读', 'value' => 'reading'],
                ],
            ],
            'sort' => 5,
        ],
    ];

    foreach ($fields as $field) {
        AdminUserExtField::firstOrCreate(
            ['field_name' => $field['field_name']],
            array_merge($field, [
                'app_id' => 'YourAppId',  // 标记来源应用
                'status' => 1,
            ])
        );
    }
}
```

> **注意**：`firstOrCreate` 只在字段不存在时创建，不会更新已有字段定义。如需升级已有字段的类型或 options，需要手动 `$field->update([...])` 或在卸载重装流程中处理。

### 应用卸载时清理扩展字段

在 `Install.php` 的 `uninstall()` 方法中清理：

```php
use App\Services\UserExtFieldService;

protected function removeExtFields(): void
{
    app(UserExtFieldService::class)->cleanAdminExtByApp('YourAppId');
}
```

### 读取和保存扩展数据

```php
use App\Services\UserExtFieldService;

$extService = app(UserExtFieldService::class);

// 读取后台用户扩展数据（返回 field_name => field_value 形式）
$extData = $extService->getAdminUserExtData($adminUserId);

// 保存后台用户扩展数据
$extService->saveAdminUserExtData($adminUserId, [
    'staff_no' => 'GH001',
    'specialty' => '运动康复',
]);

// 读取前台用户扩展数据
$extData = $extService->getUserExtData($userId);

// 保存前台用户扩展数据
$extService->saveUserExtData($userId, [
    'max_bind_patients' => '5',
]);

// 卸载应用时清理
$extService->cleanAdminExtByApp('YourAppId');
$extService->cleanUserExtByApp('YourAppId');
```

> **多选字段的读写**：当字段启用了多选模式时，`saveAdminUserExtData()` / `saveUserExtData()` 的 `$extData` 中对应字段的值应为数组（如 `['1', '2', '3']`），服务层会自动 JSON 编码后存入 `field_value`；读取时自动 JSON 解码为数组返回。单选字段保持原有的字符串值格式，不受影响。

### 后台管理界面

系统用户管理页面已内置扩展字段管理功能：

- **扩展管理按钮**：后台用户管理和前台用户管理页面的搜索栏右侧，点击可管理扩展字段定义（新增/编辑/删除/排序/启用禁用）
- **选项来源配置**：`select` 类型字段支持在扩展管理弹窗中切换"静态选项"或"动态数据源"两种模式
  - 静态选项：直接编辑 JSON 数组
  - 动态数据源：填写结构化表单（URL、显示字段、值字段），无需手写 JSON
- **多选开关**：`select` 类型字段在扩展管理弹窗中显示「多选」开关，开启后字段支持多选，前端渲染为 checkbox 组
- **自动渲染**：用户编辑表单会自动渲染已启用的扩展字段
  - 静态选项：直接渲染
  - 动态数据源：先渲染占位 select，再 AJAX 拉取选项填充
  - 多选模式：渲染为 checkbox 组（layui primary 风格），选中值以数组形式提交
- **API 接口**：
  - 后台用户扩展字段：`GET/POST/PUT/DELETE /api/admin/admin-user-ext-fields`
  - 前台用户扩展字段：`GET/POST/PUT/DELETE /api/admin/user-ext-fields`
- **用户接口返回扩展数据**：系统用户管理接口已内置扩展字段输出，编辑用户时可直接获取已保存的扩展值
  - `GET /api/admin/users/{id}` 返回的 user 对象包含 `ext_fields` 字段（`field_name => field_value` 形式）
  - 多选字段的值以数组形式输出（如 `"service_items": ["1", "2"]`），单选字段保持字符串格式
  - `GET /api/admin/front-users/{id}` 同理返回 `ext_fields` 字段
  - 编辑表单加载时会自动回填这些值（含动态数据源 select 的默认选中）

### 统一权限模型（角色与扩展字段联动）

应用的业务角色应使用系统的 `AdminRole`，通过 `code` 字段标识角色类型（如 `doctor`、`nurse`），不再在应用内单独维护角色体系。角色的权限通过系统权限管理分配，应用只需：

1. 在 `Install.php` 中创建业务角色（`AdminRole::firstOrCreate`）
2. 为角色分配对应权限（`$role->permissions()->syncWithoutDetaching($permissionIds)`）
3. 应用卸载时清理角色（`$role->delete()` 并解除关联）

用户的业务属性（如工号、职称）通过扩展字段存储，实现账号/角色/权限/业务属性的统一管理。

***

## 十六、应用打包

### 包结构

将应用目录打包为 `.zip` 文件：

```
blog-1.0.0.zip
├── manifest.json
├── ServiceProvider.php
├── Hooks.php
├── Install.php
├── Routes/
├── Controllers/
├── Models/
├── Services/
├── Migrations/
├── Views/
├── Config/
└── Assets/
```

### 打包命令

```bash
cd app/Apps/Blog
zip -r ../../../storage/app_packages/blog-1.0.0.zip ./*
```

### 上传安装校验

通过后台上传 `.zip` 安装时，系统会在安装前对包内容做结构校验，**校验不通过直接拒绝安装**，错误信息在弹窗中展示：

| 校验项 | 规则 |
|--------|------|
| manifest.json 位置 | 必须位于压缩包根目录；兼容单一顶层目录包装的包（安装时自动上移内容），但**标准包必须根目录直放** |
| 安全检查 | 包内不允许出现 `../` 相对路径穿越、绝对路径条目 |
| manifest 必填字段 | `id`、`name`、`version`、`providers` 缺一不可 |
| app_id 格式 | 正则 `/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)?$/`，长度 ≤ 64；**新应用必须为 `开发者标识.应用标识` 两段式格式**，单段式仅限存量应用升级 |
| providers 类文件 | manifest 中声明的每个 Provider 类文件必须存在于包内（如 `providers: ["ServiceProvider"]` → 包内须有 `ServiceProvider.php`） |
| 命名空间一致性 | Provider 文件的 `namespace` 必须位于 `App\Apps\{目录名}` 下，目录名由 `app_id_to_class_name(app_id)` 精确生成，**大小写必须完全一致**（Linux 大小写敏感，不一致会导致 Laravel 启动失败、全站 500） |
| hooks / install 类文件 | manifest 声明了 `hooks` 或非默认 `install` 类名时，对应类文件（如 `Hooks.php`）必须存在于包内 |
| 结构字段类型 | `providers`/`menus`/`user_menus`/`home_menus`/`config_groups`/`permissions`/`runtime_files` 必须为数组，`require`/`dependencies`/`home_routes` 必须为对象，`dependencies.app_ids` 必须为字符串数组 |

> **打包自查清单**：发布前请逐项确认 —— manifest.json 在根目录、声明过的 Provider/Hooks/Install 类文件齐全、所有 PHP 文件的 `namespace` 与 `app_id` 生成的目录名一致（用 `php -r "echo app_id_to_class_name('你的app_id');" ` 验证）、app_id 为两段式格式。

### 包命名规则

`{app_id}-{version}.zip`，例如 `blog-1.0.0.zip`

### 排除规则（.exportignore）

导出和打包时，系统会自动读取应用根目录下的 `.exportignore` 配置文件，**排除不应打包的文件**（如虚拟环境、编译缓存、本地配置等）。

> **规范要求：**
> 1. **每个应用根目录下都必须提供 `.exportignore` 文件**（应用开发完成后、发布打包前必须创建，未创建的视为不符合发布规范）。
> 2. **测试用例目录必须加入排除**：各应用目录下的测试用例文件夹（如 `Tests/`、`tests/`）属于开发期产物，不应随应用打包分发，**必须**在 `.exportignore` 中配置 `Tests/` 排除项。
> 3. **版本控制目录必须加入排除**：应用目录下的 `.git/` 目录属于本地版本库数据（`.git/objects` 内对象文件为只读），**必须**在 `.exportignore` 中配置 `.git/` 排除项；若随包分发，安装/升级解压时会因只读文件导致 `ZipArchive::extractTo(): Permission denied` 失败。

**格式说明：**

- 每行一个路径模式，相对于应用根目录
- 以 `#` 开头的行视为注释，空行自动跳过
- 以 `/` 结尾为目录模式，匹配路径中任意位置的同名目录
- 不以 `/` 结尾为文件模式，匹配精确文件名

**匹配规则：**

| 模式 | 类型 | 匹配示例 | 不匹配 |
|------|------|----------|--------|
| `venv/` | 目录 | `venv/bin/python`、`PythonAsr/venv/bin/python` | `venv_backup/readme` |
| `__pycache__/` | 目录 | `__pycache__/app.cache`、`PythonAsr/__pycache__/app.cache` | — |
| `.git/` | 目录 | `.git/config`、`Sub/.git/objects/xx` | `.gitignore`、`.gitattributes` |
| `.env` | 文件 | `.env`、`PythonAsr/.env` | `.env.example` |

**示例（CmsproVideoanalysis 应用）：**

```ignore
# 应用根目录 .exportignore
# 版本控制（必须排除）
.git/
PythonAsr/venv/
PythonAsr/__pycache__/
PythonAsr/.env
```

**示例（含测试用例排除，Laravel 应用）：**

```ignore
# 应用根目录 .exportignore
# 版本控制（必须排除）
.git/

# 测试用例（必须排除）
Tests/
```

***

## 十七、应用生命周期

### 状态流转

```
安装 → INSTALLED（已安装，未启用）
  ↓ enable()
ENABLED（已启用，运行中）
  ↓ disable()
DISABLED（已禁用，暂停运行）
  ↓ enable()
ENABLED
  ↓ uninstall()
删除
```

### 启用/禁用的影响

| 操作 | 路由 | 菜单 | 钩子 | 数据 |
| ---- | ---- | ---- | ---- | ---- |
| 启用 | 注册 | 显示 | 注册 | 保留 |
| 禁用 | 移除 | 隐藏 | 移除 | 保留 |
| 卸载 | 移除 | 删除 | 移除 | 删除 |

***

## 十八、错误码

| 错误码   | 说明                    |
| ----- | --------------------- |
| 50001 | 应用包格式无效               |
| 50002 | manifest.json 缺失或格式错误 |
| 50003 | 系统要求不满足               |
| 50004 | 依赖应用未安装               |
| 50005 | 应用已安装                 |
| 50006 | 应用未安装                 |
| 50007 | 应用状态不允许此操作            |
| 50008 | 安装过程失败                |
| 50009 | 卸载过程失败                |
| 50010 | 升级过程失败                |
| 50011 | 签名验证失败                |
| 50012 | 市场服务不可用               |
| 50013 | 应用下载失败                |
| 50014 | 系统应用不可卸载              |
| 50015 | 有其他应用依赖此应用            |
| 50017 | 依赖应用未启用               |
| 50019 | 前台路由冲突               |

***

## 十九、完整示例：博客应用

### manifest.json

```json
{
    "id": "blog",
    "name": "博客",
    "description": "博客应用，支持文章发布、分类、标签管理",
    "version": "1.0.0",
    "author": "CmsPro",
    "require": {
        "php": ">=8.1",
        "cmspro": ">=5.0.0"
    },
    "providers": ["ServiceProvider"],
    "hooks": "Hooks",
    "install": "Install",
    "menus": [
        {
            "title": "博客管理",
            "icon": "fa fa-book",
            "order": 100,
            "children": [
                { "title": "文章管理", "icon": "fa fa-file-text", "path": "/admin/blog/posts", "order": 1 },
                { "title": "分类管理", "icon": "fa fa-folder", "path": "/admin/blog/categories", "order": 2 }
            ]
        }
    ],
    "config_groups": [
        {
            "name": "blog_settings",
            "title": "博客设置",
            "items": [
                { "name": "posts_per_page", "title": "每页文章数", "type": "number", "value": "10", "tips": "每页显示的文章数量" },
                { "name": "allow_comments", "title": "允许评论", "type": "switch", "value": "1", "tips": "关闭后文章将不显示评论区" },
                { "name": "default_category", "title": "默认分类", "type": "select", "value": "1", "options": [
                    { "label": "技术", "value": "1" },
                    { "label": "生活", "value": "2" },
                    { "label": "随笔", "value": "3" }
                ]}
            ]
        }
    ],
    "permissions": [
        { "code": "blog.manage", "name": "博客管理" },
        { "code": "blog.post.create", "name": "创建文章" },
        { "code": "blog.post.edit", "name": "编辑文章" },
        { "code": "blog.post.delete", "name": "删除文章" }
    ]
}
```

### ServiceProvider.php

```php
<?php

namespace App\Apps\Blog;

use App\Services\HookManager;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider as BaseServiceProvider;

class ServiceProvider extends BaseServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(
            base_path('app/Apps/Blog/Config/blog.php'),
            'apps.blog'
        );
    }

    public function boot(): void
    {
        $this->registerRoutes();
        $this->loadViews();
        $this->registerHooks();
    }

    protected function registerRoutes(): void
    {
        Route::prefix('admin/blog')
            ->namespace('App\Apps\Blog\Controllers')
            ->middleware(['auth:admin'])
            ->group(base_path('app/Apps/Blog/Routes/web.php'));
    }

    protected function loadViews(): void
    {
        $this->loadViewsFrom(
            base_path('app/Apps/Blog/Views'),
            'blog'
        );
    }

    protected function registerHooks(): void
    {
        $hooks = $this->app->make(HookManager::class);
        $hooksInstance = new Hooks();
        $hooksInstance->register($hooks);
    }
}
```

### Install.php

```php
<?php

namespace App\Apps\Blog;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class Install
{
    public function install(): void
    {
        $this->runMigrations();
        // 创建默认分类等种子数据...
    }

    public function uninstall(): void
    {
        // 仅做非数据库清理（如缓存）
    }

    public function upgrade(string $fromVersion, string $toVersion): void
    {
        $this->runMigrations();
    }

    protected function runMigrations(): void
    {
        $migrationsPath = __DIR__ . '/Migrations';
        $migrationFiles = glob($migrationsPath . '/*.php');

        foreach ($migrationFiles as $file) {
            $migrationName = pathinfo($file, PATHINFO_FILENAME);

            if (DB::table('migrations')->where('migration', $migrationName)->exists()) {
                continue;
            }

            $migration = require $file;
            if (method_exists($migration, 'up')) {
                try {
                    $migration->up();

                    DB::table('migrations')->insert([
                        'migration' => $migrationName,
                        'batch' => DB::table('migrations')->max('batch') + 1,
                    ]);
                } catch (\Throwable $e) {
                    Log::error('应用迁移执行失败', [
                        'app' => 'blog',
                        'file' => basename($file),
                        'error' => $e->getMessage(),
                    ]);
                }
            }
        }
    }
}
```

### Hooks.php

```php
<?php

namespace App\Apps\Blog;

use App\Services\HookManager;

class Hooks
{
    public function register(HookManager $hooks): void
    {
        $hooks->registerAction('content.after_create', [$this, 'onContentCreated'], 10, 'blog');
        $hooks->registerFilter('content.list.query', [$this, 'filterContentQuery'], 10, 'blog');
    }

    public function onContentCreated($content): void
    {
        // 同步到博客文章表
    }

    public function filterContentQuery($query)
    {
        return $query;
    }
}
```

### Migrations/2026\_05\_22\_000001\_create\_app\_blog\_posts\_table.php

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('app_blog_posts')) {
            return;
        }

        Schema::create('app_blog_posts', function (Blueprint $table) {
            $table->bigIncrements('id')->comment('主键ID');
            $table->string('title')->comment('文章标题');
            $table->text('content')->nullable()->comment('文章内容');
            $table->unsignedBigInteger('category_id')->nullable()->comment('分类ID，关联app_blog_categories表');
            $table->unsignedTinyInteger('status')->default(0)->comment('状态：0-草稿 1-已发布 2-已下架');
            $table->timestamp('create_time')->nullable()->comment('创建时间');
            $table->timestamp('update_time')->nullable()->comment('更新时间');

            $table->index('category_id');
            $table->index('status');
        });

        DB::statement("ALTER TABLE `app_blog_posts` COMMENT '博客文章表'");
    }

    public function down(): void
    {
        Schema::dropIfExists('app_blog_posts');
    }
};
```

### Routes/web.php

```php
<?php

use App\Apps\Blog\Controllers\PostController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('blog::index');
});
Route::get('/posts', [PostController::class, 'index']);
Route::get('/posts/create', [PostController::class, 'create']);
Route::post('/posts', [PostController::class, 'store']);
Route::get('/posts/{id}/edit', [PostController::class, 'edit']);
Route::put('/posts/{id}', [PostController::class, 'update']);
Route::delete('/posts/{id}', [PostController::class, 'destroy']);
```

***

## 二十、注意事项

1. **禁止修改系统核心文件**：应用代码不应修改 `app/Services/`、`app/Models/`、`config/` 等系统目录中的文件
2. **数据库表必须加前缀**：应用创建的表必须使用 `app_{app_id}_` 前缀
3. **钩子注册必须传 app\_id**：确保应用禁用时钩子能被正确移除
4. **视图使用命名空间**：避免与系统视图或其他应用视图冲突
5. **配置使用前缀键**：通过 `apps.{app_id}` 访问，避免与系统配置冲突
6. **卸载必须可逆**：迁移的 `down()` 方法必须正确回滚
7. **遵循系统规范**：时间字段使用 `create_time/update_time`，状态字段使用枚举类型
8. **表和字段必须添加备注**：迁移文件中每个字段必须使用 `->comment()` 添加备注，每张表必须使用 `DB::statement("ALTER TABLE ... COMMENT '...'")` 添加表备注。无备注的迁移文件不予合并
9. **目录名与 app\_id 严格对应**：应用目录名必须是 `ucfirst(app_id)` 的结果（如 `versionmgr` → `Versionmgr`，而非 `VersionManager`）。系统通过此规则自动构造命名空间和文件路径，不一致将导致路由 404
10. **安装后检查 path 字段**：安装完成后需确认 `apps` 表中该应用的 `path` 字段为相对路径（如 `app/Apps/Versionmgr`）。若为绝对路径需手动修正，否则路由加载失败
11. **权限 name 必须使用中文**：`manifest.json` 中 `permissions` 推荐使用对象格式 `{ "code": "xxx", "name": "中文名称" }`，`name` 字段写入 `admin_permissions` 表后显示在角色管理的权限列表中
12. **Install.php 建议增加迁移兜底**：由于系统迁移执行依赖路径解析，Windows 等环境下可能失败。建议在 `install()` 方法中通过 `require` 迁移文件并调用 `$migration->up()` 作为兜底，确保表一定能被创建
13. **用户端菜单使用 user\_menus 声明**：应用如需在用户端（`/user/`）展示菜单，必须使用 `user_menus` 字段声明，不可将用户端菜单放在 `menus` 字段中
14. **迁移 up()/down() 必须幂等**：`up()` 中建表前检查 `Schema::hasTable()`，加列前检查 `Schema::hasColumn()`；`down()` 中删列前检查表和列是否存在。缺少幂等检查会导致安装/卸载/升级流程中报 `Table already exists` 或 `Table not found` 错误
15. **uninstall() 必须包含迁移回滚兜底**：卸载时系统会自动调用 `rollbackMigrations()` 执行迁移的 `down()` 方法，但该方法依赖 `Artisan::call('migrate:rollback')` 在 Windows 等环境下可能因路径解析失败导致 `down()` 未执行。因此 `uninstall()` 中必须增加 `rollbackMigrations()` 兜底方法，直接 `require` 迁移文件并调用 `down()` 确保表被清理，同时删除 `migrations` 表记录避免系统后续重复执行。禁止在 `uninstall()` 中使用 `Schema::dropIfExists()` 手动删表（绕过了 `down()` 的幂等检查），应统一通过迁移的 `down()` 方法删除
16. **runMigrations() 必须写入 migrations 表记录**：兜底执行迁移后，必须向 `migrations` 表插入记录，否则 `php artisan migrate` 会重复执行已跑过的迁移
17. **用户端视图禁止继承 layouts.user**：PearAdmin 用户端采用 iframe 多标签页模式，子页面通过 iframe 加载到 `layui-body` 区域。用户端视图必须是独立完整 HTML 页面（有自己的 `<head>`/`<body>`/CSS/JS），使用 `@extends('layouts.user')` 会导致布局嵌套显示。详见第二十二章 20.6 节
18. **Blade 与 Layui 语法冲突**：Blade 视图中 Layui 模板语法 `{{# }}` 的 `{{` 会被 Blade 解析为 PHP 表达式，导致 `syntax error, unexpected token ";"` 错误。必须用 `@verbatim` / `@endverbatim` 包裹包含 Layui `{{# }}` 语法的 `<script type="text/html">` 块。详见第二十二章 20.6 节
19. **依赖外部服务的应用应提供未配置友好提示**：应用如依赖外部服务（如支付服务端），应在控制器中检查配置状态，未配置时显示友好提示页面（而非空白或报错），API 接口返回明确错误码和提示信息。详见第二十二章 20.6 节
20. **禁止在 Install.php 中创建 public/apps/{appId}/ 下的目录**：安装流程先执行 `Install::install()`，再执行 `createAssetSymlink()` 发布 `Assets/` 资源。如果在 `install()` 中提前创建了 `public/apps/{appId}/` 下的目录，`createAssetSymlink()` 检测到目标路径已存在后会跳过，导致 `Assets/` 下的文件不会被复制。详见第六章「Assets 静态资源发布机制」
21. **自定义用户接口须声明 ext_fields 验证规则**：Laravel 的 `FormRequest::validated()` 只返回 rules 中声明的字段。如果应用自定义用户管理接口（如 `StoreUserRequest`/`UpdateUserRequest`），必须在 `rules()` 中显式声明 `'ext_fields' => 'nullable|array'`，否则提交的扩展字段会被 `validated()` 静默过滤，导致扩展数据无法保存。同理，若应用使用 `$request->validate([...])` 内联验证，也需要在规则数组中加入 `ext_fields`。详见第十五章A「用户扩展字段」
22. **配置同步 seedDefaultConfigs 必须遵守三向同步规则**：`seedDefaultConfigs()` 以 `manifest.json` 为唯一基准，新增配置项写入默认值，已有配置项保留用户设置的 value（仅更新结构），已从 manifest 移除的配置项必须清理 DB 残留。禁止使用 `updateOrCreate` 全覆盖写入 value。该方法必须在 `install()` 和 `upgrade()` 中同时调用。详见第十二章「配置同步规范」
23. **菜单声明推荐使用 code 字段**：`menus`/`user_menus`/`home_menus` 中每个菜单项推荐声明 `code` 字段（如 `"code": "blog_posts"`），作为菜单稳定标识符。升级时系统按 `(app_id, code, terminal_type)` 匹配旧菜单，保留菜单 ID 和角色关联，避免 path 调整或菜单重组时角色权限丢失。code 字段为可选，未声明时系统按 path 自动 slug 化生成兜底，但自动生成的 code 在 path 变化时也会变化，无法保证稳定。一旦声明 code，后续版本不要修改 code 值。详见第十三章「菜单 code 字段」
24. **菜单目录不声明 path 且 code 全局唯一（硬性规范）**：`menus` / `user_menus` 中含 `children` 的目录（顶级分组菜单）不得声明 `path` 字段，禁止写 `"path": "/"`；目录（父级）的 `code` 不得与任何子菜单的 `code` 相同，同一 `menus` 结构内 code 必须全局唯一。`home_menus` 为扁平结构、无目录层级，每个菜单项均为叶子导航，必须声明 `path`。详见第十三章「菜单声明」

***

## 二十一、应用文档规范

### 19.1 doc/ 目录

每个应用创建后，必须在应用根目录创建 `doc/` 目录，用于存放当前应用的文档。该目录与 `manifest.json` 同级，属于应用不可分割的一部分。

**目录结构示例：**

```
code/app/Apps/Blog/
├── manifest.json
├── ServiceProvider.php
├── doc/                           # 应用文档目录
│   ├── CmsPro-博客应用-特性清单.md   # 应用信息文档（特性清单）
│   ├── CmsPro-博客应用-使用指南.md   # 应用使用文档（使用指南）
│   └── CmsPro-博客应用-扩展指南.md   # 应用拓展文档（扩展指南）
├── Controllers/
├── Models/
├── Views/
└── ...
```

> **三类应用文档**：每个应用创建后，必须在 `doc/` 目录下交付三类文档——**应用信息文档（特性清单）**、**应用使用文档（使用指南）**、**应用拓展文档（扩展指南）**。三类文档共同构成应用的完整文档体系，是应用不可分割的一部分。

### 19.2 文档编写要求

| 项目 | 说明 |
|------|------|
| 文件命名 | `CmsPro-{应用名称}-{文档类型}.md`，如 `CmsPro-博客应用使用指南.md` |
| 文档格式 | Markdown 格式，使用 `#` 标题层级，代码块标注语言 |
| 存放位置 | 应用根目录下的 `doc/` 文件夹，与 `manifest.json` 同级 |
| 文档语言 | 中文 |

### 19.3 文档内容规范

每个应用须交付三类文档，各自内容定位如下：

| 文档类型 | 命名规范 | 内容定位 |
|----------|----------|----------|
| 应用信息文档（特性清单） | `CmsPro-{应用名称}-特性清单.md` | 系统整理应用覆盖的框架特性，标注对应实现位置，作为应用开发参考 |
| 应用使用文档（使用指南） | `CmsPro-{应用名称}-使用指南.md` | 帮助使用者安装、配置、运行、验证应用 |
| 应用拓展文档（扩展指南） | `CmsPro-{应用名称}-扩展指南.md` | 说明其他应用如何调用本应用的 Service 层、钩子点、辅助函数等扩展接口 |

**应用使用文档（使用指南）建议至少包含以下内容**：

1. **应用概述**：应用的功能定位、适用场景
2. **功能说明**：核心功能点及操作步骤
3. **配置说明**：填写后台配置项的说明和注意事项
4. **依赖关系**：依赖的其他应用及版本要求
5. **注意事项**：使用中的常见问题、限制条件、踩坑记录

### 19.4 文档同步更新（强制）

**应用开发或调整时，必须同步更新 `doc/` 目录下对应的文档，确保文档与代码保持一致。**

#### 触发场景

以下情况必须同步更新文档：

| 场景 | 必须更新的文档内容 |
|------|-------------------|
| 新增功能 | 补充功能说明、操作步骤、配置项说明 |
| 修改功能 | 更新功能描述、操作流程、接口变化 |
| 删除功能 | 从文档中移除对应说明，或标记为废弃 |
| 新增配置项 | 补充配置项名称、类型、默认值、说明 |
| 修改依赖 | 更新依赖版本、兼容性说明 |
| 新增路由/接口 | 补充接口地址、参数、返回格式 |
| 修改数据库表 | 更新表结构、字段说明 |

#### 禁止行为

- 创建应用后不建立 `doc/` 目录
- 对应用代码做了修改，但不更新对应文档（导致文档与代码不一致）
- 文档内容与代码实际行为不符（误导使用者）

#### 文档检查清单（应用开发/调整完成前自检）

- [ ] `doc/` 目录是否存在？
- [ ] 文档中功能描述是否与当前代码一致？
- [ ] 新增/修改的配置项是否已在文档中说明？
- [ ] 新增/修改的接口是否已在文档中记录？
- [ ] 依赖关系是否有变更？
- [ ] 是否有需要提醒使用者的注意事项？

***

## 二十二、用户端扩展

CmsPro v5 支持应用同时扩展后台管理和用户端两个终端。用户端地址为 `/user/`，使用 `auth:web` Guard 认证前台用户，界面与后台管理完全一致（Pear Admin + Layui + iframe 多标签页）。

### 20.1 用户端与后台对比

| 维度       | 后台管理                    | 用户端                    |
| -------- | ----------------------- | ---------------------- |
| 入口路径     | `/admin/`               | `/user/`               |
| 认证 Guard | `auth:admin`            | `auth:web`             |
| 用户模型     | `AdminUser`             | `User`                 |
| 菜单终端     | `terminal_type='admin'` | `terminal_type='user'` |
| 菜单声明     | `manifest.menus`        | `manifest.user_menus`  |
| 路由前缀     | `admin/{appId}`         | `user/{appId}`         |
| API 前缀   | `api/admin/`            | `api/user/`            |
| 布局模板     | `layouts.admin`         | `layouts.user`         |
| 权限控制     | RBAC 角色权限               | 无（所有启用用户可见）            |

### 19.2 manifest.json 声明

在 `manifest.json` 中使用 `user_menus` 字段声明用户端菜单：

```json
{
    "id": "blog",
    "name": "博客",
    "menus": [
        {
            "title": "博客管理",
            "icon": "fa fa-book",
            "order": 100,
            "children": [
                { "title": "文章管理", "icon": "fa fa-file-text", "path": "/admin/blog/posts", "order": 1 }
            ]
        }
    ],
    "user_menus": [
        {
            "title": "我的博客",
            "icon": "fa fa-book",
            "order": 50,
            "children": [
                { "title": "我的文章", "icon": "fa fa-file-text", "path": "/user/blog/posts", "order": 1 },
                { "title": "写文章", "icon": "fa fa-pencil", "path": "/user/blog/create", "order": 2 }
            ]
        }
    ]
}
```

### 19.3 ServiceProvider 注册用户端路由

在 ServiceProvider 中注册用户端路由组，使用 `user/{appId}` 前缀和 `auth:web` 中间件：

```php
protected function registerRoutes(): void
{
    // 后台路由
    Route::prefix('admin/blog')
        ->namespace('App\Apps\Blog\Controllers\Admin')
        ->middleware(['web', 'auth:admin'])
        ->group(base_path('app/Apps/Blog/Routes/admin.php'));

    // 用户端视图路由
    Route::prefix('user/blog')
        ->namespace('App\Apps\Blog\Controllers\User')
        ->middleware(['web', 'auth:web'])
        ->group(base_path('app/Apps/Blog/Routes/user.php'));

    // 用户端 API 路由（可选）
    Route::prefix('api/user/blog')
        ->namespace('App\Apps\Blog\Controllers\User')
        ->middleware(['web', 'auth:web'])
        ->group(base_path('app/Apps/Blog/Routes/user_api.php'));
}
```

### 19.4 目录结构

支持用户端的应用推荐目录结构：

```
app/Apps/Blog/
├── manifest.json
├── ServiceProvider.php
├── Controllers/
│   ├── Admin/                  # 后台控制器
│   │   └── PostController.php
│   └── User/                   # 用户端控制器
│       └── PostController.php
├── Routes/
│   ├── admin.php               # 后台路由
│   ├── user.php                # 用户端路由
│   └── user_api.php            # 用户端 API 路由（可选）
├── Views/
│   ├── Admin/                  # 后台视图
│   │   └── posts/
│   └── User/                   # 用户端视图
│       └── posts/
├── Models/                     # 共用模型
├── Services/                   # 共用服务
├── Tests/                      # 应用测试（强制放应用目录，禁止放框架 tests/）
└── Migrations/                 # 共用迁移
```

### 19.5 用户端路由文件

`Routes/user.php` — 用户端视图路由：

```php
<?php

use App\Apps\Blog\Controllers\User\PostController;
use Illuminate\Support\Facades\Route;

Route::get('/', [PostController::class, 'index']);
Route::get('/create', [PostController::class, 'create']);
Route::post('/', [PostController::class, 'store']);
Route::get('/{id}/edit', [PostController::class, 'edit']);
Route::put('/{id}', [PostController::class, 'update']);
Route::delete('/{id}', [PostController::class, 'destroy']);
```

`Routes/user_api.php` — 用户端 API 路由（可选，用于 AJAX 请求）：

```php
<?php

use App\Apps\Blog\Controllers\User\PostController;
use Illuminate\Support\Facades\Route;

Route::get('/posts', [PostController::class, 'apiIndex']);
Route::post('/posts', [PostController::class, 'apiStore']);
```

### 19.6 视图开发（后台与用户端）

> **⚠️ 重要：后台和用户端视图都必须为独立完整 HTML 页面，禁止继承 `layouts.admin` 或 `layouts.user` 布局**

PearAdmin 后台和用户端框架均采用 **iframe 多标签页** 模式：`layouts.admin` / `layouts.user` 是外层框架页面（包含顶部导航、侧边菜单、标签栏），点击菜单时通过 iframe 加载子页面到 `layui-body` 区域。因此，后台和用户端的子页面都必须是独立完整的 HTML 页面（有自己的 `<head>`/`<body>`/CSS/JS），**不能**使用 `@extends('layouts.admin')` 或 `@extends('layouts.user')` 继承布局，否则会导致页面嵌套显示——外层渲染了完整框架布局，内层又渲染了一遍框架+内容，表现为"上半部分是框架首页，下半部分才是正常内容"。

#### ❌ 错误写法（会导致布局嵌套）

后台和用户端都**禁止**使用 `@extends` 继承布局：

```html
{{-- ❌ 后台视图错误写法 --}}
@extends('layouts.admin')

@section('content')
<div class="pear-container">
    <!-- 内容 -->
</div>
@endsection

@section('script')
layui.use(['table', 'form', 'jquery'], function(){
    // JavaScript 逻辑
});
@endsection
```

```html
{{-- ❌ 用户端视图错误写法 --}}
@extends('layouts.user')

@section('content')
<div class="pear-container">
    <!-- 内容 -->
</div>
@endsection

@section('script')
layui.use(['table', 'form', 'jquery'], function(){
    // JavaScript 逻辑
});
@endsection
```

#### ✅ 正确写法（独立完整 HTML 页面）

后台和用户端视图的正确写法完全一致——都是独立完整 HTML 页面，自行引入 CSS/JS，唯一区别是 API 前缀和页面导航方式：

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>页面标题</title>
    <link rel="stylesheet" href="{{ asset('CmsProUi/component/pear/css/pear.css') }}">
    <link rel="stylesheet" href="{{ asset('CmsProUi/font-awesome/4.7.0/css/font-awesome.min.css') }}">
    <link rel="stylesheet" href="{{ asset('Admin/css/admin.css') }}">
    <link rel="stylesheet" href="{{ asset('Admin/css/variables.css') }}">
    <link rel="stylesheet" href="{{ asset('Admin/css/reset.css') }}">
</head>
<body>
<div class="pear-container">
    <div class="layui-card">
        <div class="layui-card-body">
            <!-- 页面内容 -->
        </div>
    </div>
</div>

<script src="{{ asset('CmsProUi/component/layui/layui.js') }}"></script>
<script src="{{ asset('CmsProUi/component/pear/pear.js') }}"></script>
<script>
layui.use(['table', 'form', 'jquery'], function(){
    var $ = layui.jquery;

    var layer = layui.layer;

    $.ajaxSetup({
        headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}' },
        statusCode: {
            401: function() {
                layer.msg('登录已过期，请重新登录', {icon: 2, time: 1500}, function() {
                    window.location.href = '/admin/login?redirect=' + encodeURIComponent(window.location.pathname + window.location.search);
                });
            }
        }
    });

    // JavaScript 逻辑
});
</script>
</body>
</html>
```

> **⚠️ UI 资源引用本地化规范**：系统已内置 layui、pear、font-awesome 等 UI 框架，统一存放在 `public/CmsProUi/` 目录下。应用视图中引用这些系统级资源时，**必须使用 `{{ asset() }}` 引用本地路径，禁止通过 CDN 远程加载**。如需使用额外的第三方库（如 echarts、qrcodejs、highlight.js 等），应下载到应用自身的 `Assets/` 目录中，通过 `public/apps/{appId}/` 访问，禁止直接引用 CDN。

#### 视图开发要点

| 要点 | 说明 |
| ---- | ---- |
| 禁止继承布局 | 不要使用 `@extends('layouts.admin')` 或 `@extends('layouts.user')`，页面必须是独立完整 HTML |
| 自行引入 CSS | 引入 pear.css、font-awesome、admin.css、variables.css、reset.css 等样式文件 |
| 自行引入 JS | 引入 layui.js、pear.js，并使用 `layui.use()` 初始化组件 |
| CSRF Token | 必须通过 `$.ajaxSetup({ headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}' } })` 设置，否则 AJAX POST 请求会被 Laravel 拦截返回 419 错误 |
| 登录超时处理 | 必须在 `$.ajaxSetup` 中配置 `statusCode: { 401: function(){...} }`，当 Session 过期时提示用户并跳转登录页，避免请求无响应或只弹"请求失败"（详见下方说明） |
| 后台页面导航 | 后台子页面运行在 iframe 中，使用 `window.location.href` 或 `parent.PearAdmin.changePage()` 跳转均可 |
| 用户端页面导航 | 用户端子页面运行在 iframe 中，必须使用 `parent.PearAdmin.changePage({ id, title, url, type: '_iframe', close: true })` 跳转，不要使用 `window.location.href` |
| Layui 模板语法 | Layui 的 `{{# }}` 语法会被 Blade 解析为 PHP 表达式导致语法错误，必须用 `@verbatim` / `@endverbatim` 包裹（详见下方说明） |

**关键差异**：

| 项目     | 后台视图                                                  | 用户端视图                                                  |
| ------ | ------------------------------------------------------ | ------------------------------------------------------ |
| 布局方式   | **独立完整 HTML 页面**（禁止继承 `layouts.admin`）                 | **独立完整 HTML 页面**（禁止继承 `layouts.user`）                 |
| 当前用户   | `auth()->user()` → `AdminUser`                         | `auth()->user()` → `User`                              |
| API 前缀 | `/api/admin/`                                          | `/api/user/`                                           |
| 用户名字段  | `auth()->user()->name`                                 | `auth()->user()->nickname ?? auth()->user()->username` |
| 页面导航   | `window.location.href` 或 `parent.PearAdmin.changePage()` | `parent.PearAdmin.changePage()`                        |

#### 登录超时（401）处理

后台和用户端使用 Session 认证，Session 过期后 AJAX 请求会返回 401 状态码。如果不统一处理，用户看到的是"请求失败"或无任何响应，体验极差。

**必须在 `$.ajaxSetup` 中配置 `statusCode: { 401: ... }`**，让所有 jQuery AJAX 请求（`$.ajax`、`$.get`、`$.post`）在收到 401 时自动提示并跳转登录页：

```javascript
layui.use(['table', 'form', 'jquery'], function(){
    var $ = layui.jquery;
    var layer = layui.layer;

    $.ajaxSetup({
        headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}' },
        statusCode: {
            401: function() {
                layer.msg('登录已过期，请重新登录', {icon: 2, time: 1500}, function() {
                    window.location.href = '/admin/login?redirect=' + encodeURIComponent(window.location.pathname + window.location.search);
                });
            }
        }
    });
});
```

**用户端视图**需将跳转路径改为 `/user/login`：

```javascript
window.location.href = '/user/login?redirect=' + encodeURIComponent(window.location.pathname + window.location.search);
```

**注意事项**：

1. `statusCode: { 401: ... }` 仅对 jQuery AJAX 方法生效，**XMLHttpRequest 原生调用不受影响**，需在 `xhr.onload` 中手动判断 `xhr.status === 401`
2. 如果某个 `$.ajax` 的 `error` 回调已解析 `xhr.responseText`，需在回调开头加 `if (xhr.status === 401) return;`，避免与全局 401 处理重复弹窗
3. `redirect` 参数确保用户登录后能返回原页面，**不可省略**

#### AJAX 错误处理：显示服务端返回的错误信息

后台 API 返回非 2xx 状态码（400、422、500 等）时，jQuery 会进入 `error` 回调。**禁止在 `error` 回调中硬编码"请求失败"**，应解析 `xhr.responseText` 中的 `message` 字段显示给用户：

```javascript
// ❌ 错误：硬编码错误信息，丢失了服务端的具体错误原因
error: function() {
    layer.close(loadIdx);
    layer.msg('请求失败', {icon:2});
}

// ✅ 正确：解析服务端返回的 message 字段
error: function(jqXHR) {
    layer.close(loadIdx);
    var msg = '请求失败';
    try {
        var res = JSON.parse(jqXHR.responseText);
        if (res.message) msg = res.message;
    } catch(e) {}
    layer.msg(msg, {icon:2});
}
```

> **说明**：CmsPro 后端统一响应格式为 `{ code, message, data, timestamp }`，所有非 2xx 响应（参数校验失败 400/422、服务器内部错误 500 等）均会携带 `message` 字段描述具体错误原因。`error` 回调必须通过 `jqXHR.responseText` 获取该信息。此规则适用于所有应用的所有 AJAX 请求。

#### ⚠️ Blade 与 Layui 语法冲突

后台和用户端视图虽然是独立 HTML 页面，但文件扩展名仍为 `.blade.php`，Blade 引擎会解析其中的 `{{ }}` 语法。Layui 的模板语法（如 `{{# if(d.status == 0){ }}`）恰好使用了 `{{` 前缀，会被 Blade 误解析为 PHP 表达式，导致 `syntax error, unexpected token ";"` 错误。

**解决方案**：使用 `@verbatim` / `@endverbatim` 包裹 Layui 模板块，告诉 Blade 不处理其中的内容：

```html
<!-- ❌ 错误：Layui 模板语法被 Blade 解析导致报错 -->
<script type="text/html" id="status-tpl">
{{# if(d.status == 0){ }}
    <span class="layui-badge layui-bg-blue">待支付</span>
{{# } }}
</script>

<!-- ✅ 正确：用 @verbatim 包裹，Blade 不处理其中的内容 -->
<script type="text/html" id="status-tpl">
@verbatim
{{# if(d.status == 0){ }}
    <span class="layui-badge layui-bg-blue">待支付</span>
{{# } }}
@endverbatim
</script>
```

> **适用范围**：所有包含 Layui `{{# }}` 模板语法的 `<script type="text/html">` 块都需要 `@verbatim` 包裹。普通的 `<script>` 标签中的 JavaScript 代码不受影响（因为 JS 中不会出现 `{{` 语法）。

#### ⚠️ Blade 注释中禁止出现 `@verbatim` 关键字

> 注释含 `@verbatim` 关键字导致 Layui 表格操作列按钮被静默移除的问题现象、复现与排查方法详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 10 章。核心规则见下。

Blade 注释（`{{-- ... --}}`）中**禁止**出现 `@verbatim`、`@endverbatim`、`@section`、`@yield`、`@extends` 等任何 Blade 指令关键字，否则可能引发指令匹配错乱（被静默当作 verbatim 内容而移除）。需要说明某段代码用了 `@verbatim` 时，注释中写中文「原样输出」「不解析」即可，不要写指令原文。

#### 未配置时友好提示

应用依赖外部服务（如支付服务端）时，如果用户在未完成配置的情况下访问功能页面，应给出友好提示而非直接报错。推荐做法：

1. **在 ConfigService 中提供配置检查方法**：

```php
public function isConfigured(): bool
{
    $appId = $this->get('app_id');
    $appSecret = $this->get('app_secret');

    return !empty($appId) && !empty($appSecret);
}
```

2. **在用户端控制器中检查配置状态**：

```php
public function index()
{
    if (!$this->configService->isConfigured()) {
        return view('payclient::User.not-configured');
    }

    return view('payclient::User.orders');
}
```

3. **在 API 控制器中返回明确错误**：

```php
public function orderList(Request $request)
{
    if (!$this->configService->isConfigured()) {
        return response()->json([
            'code' => 1001,
            'message' => '支付服务未配置，请联系管理员完成对接'
        ], 403);
    }
    // ...
}
```

4. **创建友好提示视图**（如 `Views/User/not-configured.blade.php`），说明配置步骤和操作指引，避免用户看到空白页面或技术错误信息。

### 19.7 用户端控制器

用户端控制器位于 `Controllers/User/` 目录，使用 `auth:web` Guard 获取当前用户：

```php
<?php

namespace App\Apps\Blog\Controllers\User;

use App\Apps\Blog\Models\Post;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function index()
    {
        $user = auth()->user();
        $posts = Post::where('user_id', $user->id)->orderBy('create_time', 'desc')->get();

        return view('blog::User.posts.index', compact('posts'));
    }

    public function create()
    {
        return view('blog::User.posts.create');
    }
}
```

### 19.8 用户端 API 调用

用户端的 AJAX 请求调用 `/api/user/` 前缀的接口：

```javascript
// 后台
$.ajax({ url: '/api/admin/blog/posts', type: 'GET', ... });

// 用户端
$.ajax({ url: '/api/user/blog/posts', type: 'GET', ... });
```

### 19.9 完整示例：博客应用（双终端）

#### manifest.json

```json
{
    "id": "blog",
    "name": "博客",
    "description": "博客应用，支持文章发布、分类、标签管理",
    "version": "1.0.0",
    "author": "CmsPro",
    "require": {
        "php": ">=8.1",
        "cmspro": ">=5.0.0"
    },
    "providers": ["ServiceProvider"],
    "menus": [
        {
            "title": "博客管理",
            "icon": "fa fa-book",
            "order": 100,
            "children": [
                { "title": "文章管理", "icon": "fa fa-file-text", "path": "/admin/blog/posts", "order": 1 },
                { "title": "分类管理", "icon": "fa fa-folder", "path": "/admin/blog/categories", "order": 2 }
            ]
        }
    ],
    "user_menus": [
        {
            "title": "我的博客",
            "icon": "fa fa-book",
            "order": 50,
            "children": [
                { "title": "我的文章", "icon": "fa fa-file-text", "path": "/user/blog/posts", "order": 1 },
                { "title": "写文章", "icon": "fa fa-pencil", "path": "/user/blog/create", "order": 2 }
            ]
        }
    ],
    "permissions": [
        { "code": "blog.manage", "name": "博客管理" },
        { "code": "blog.post.create", "name": "创建文章" },
        { "code": "blog.post.edit", "name": "编辑文章" },
        { "code": "blog.post.delete", "name": "删除文章" }
    ]
}
```

#### ServiceProvider.php

```php
<?php

namespace App\Apps\Blog;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider as BaseServiceProvider;

class ServiceProvider extends BaseServiceProvider
{
    public function boot(): void
    {
        $this->registerRoutes();
        $this->loadViews();
    }

    protected function registerRoutes(): void
    {
        Route::prefix('admin/blog')
            ->namespace('App\Apps\Blog\Controllers\Admin')
            ->middleware(['web', 'auth:admin'])
            ->group(base_path('app/Apps/Blog/Routes/admin.php'));

        Route::prefix('user/blog')
            ->namespace('App\Apps\Blog\Controllers\User')
            ->middleware(['web', 'auth:web'])
            ->group(base_path('app/Apps/Blog/Routes/user.php'));

        Route::prefix('api/user/blog')
            ->namespace('App\Apps\Blog\Controllers\User')
            ->middleware(['web', 'auth:web'])
            ->group(base_path('app/Apps/Blog/Routes/user_api.php'));
    }

    protected function loadViews(): void
    {
        $this->loadViewsFrom(
            base_path('app/Apps/Blog/Views'),
            'blog'
        );
    }
}
```

#### Routes/user.php

```php
<?php

use App\Apps\Blog\Controllers\User\PostController;
use Illuminate\Support\Facades\Route;

Route::get('/', [PostController::class, 'index']);
Route::get('/create', [PostController::class, 'create']);
Route::post('/', [PostController::class, 'store']);
Route::get('/{id}/edit', [PostController::class, 'edit']);
Route::put('/{id}', [PostController::class, 'update']);
Route::delete('/{id}', [PostController::class, 'destroy']);
```

#### Views/User/posts/index.blade.php

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>我的文章</title>
    <link rel="stylesheet" href="{{ asset('CmsProUi/component/pear/css/pear.css') }}">
    <link rel="stylesheet" href="{{ asset('CmsProUi/font-awesome/4.7.0/css/font-awesome.min.css') }}">
    <link rel="stylesheet" href="{{ asset('Admin/css/admin.css') }}">
    <link rel="stylesheet" href="{{ asset('Admin/css/variables.css') }}">
    <link rel="stylesheet" href="{{ asset('Admin/css/reset.css') }}">
</head>
<body>
<div class="pear-container">
    <div class="layui-card">
        <div class="layui-card-header">我的文章</div>
        <div class="layui-card-body">
            <table id="postTable" lay-filter="postTable"></table>
        </div>
    </div>
</div>

<script src="{{ asset('CmsProUi/component/layui/layui.js') }}"></script>
<script src="{{ asset('CmsProUi/component/pear/pear.js') }}"></script>
<script>
layui.use(['table', 'jquery'], function(){
    var table = layui.table;
    var $ = layui.jquery;
    var layer = layui.layer;

    $.ajaxSetup({
        headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}' },
        statusCode: {
            401: function() {
                layer.msg('登录已过期，请重新登录', {icon: 2, time: 1500}, function() {
                    window.location.href = '/user/login?redirect=' + encodeURIComponent(window.location.pathname + window.location.search);
                });
            }
        }
    });

    table.render({
        elem: '#postTable',
        url: '/api/user/blog/posts',
        cols: [[
            {field: 'id', title: 'ID', width: 80},
            {field: 'title', title: '标题'},
            {field: 'status', title: '状态', width: 100},
            {field: 'create_time', title: '创建时间', width: 180}
        ]]
    });
});
</script>
</body>
</html>
```

### 19.10 注意事项

1. **路由前缀区分**：后台路由使用 `admin/{appId}` 前缀 + `auth:admin` 中间件，用户端路由使用 `user/{appId}` 前缀 + `auth:web` 中间件，两者不可混用
2. **叶子菜单 path 必须匹配**：`user_menus` 中**叶子菜单**的 `path` 必须以 `/user/` 开头，与用户端路由前缀对应；**含 `children` 的目录不得声明 `path` 字段**（硬性规范，同 `menus`）
3. **控制器命名空间隔离**：后台控制器放 `Controllers/Admin/`，用户端控制器放 `Controllers/User/`，避免类名冲突
4. **视图目录隔离**：后台视图放 `Views/Admin/`，用户端视图放 `Views/User/`，共用视图命名空间
5. **模型和服务可共用**：`Models/` 和 `Services/` 目录下的代码在两个终端间共享
6. **用户对象差异**：后台 `auth()->user()` 返回 `AdminUser`，用户端返回 `User`，注意字段差异（如后台有 `name`，用户端有 `nickname`）
7. **API 前缀区分**：用户端 AJAX 请求使用 `/api/user/` 前缀，后台使用 `/api/admin/` 前缀
8. **仅声明需要的终端**：应用可以只声明 `menus`（仅后台）或只声明 `user_menus`（仅用户端），不必同时声明两者
9. **⚠️ 后台和用户端视图均禁止继承布局**：PearAdmin 后台和用户端均采用 iframe 多标签页模式，`layouts.admin` / `layouts.user` 是外层框架页面，子页面通过 iframe 加载。后台和用户端视图都必须是独立完整 HTML 页面（有自己的 `<head>`/`<body>`/CSS/JS），使用 `@extends('layouts.admin')` 或 `@extends('layouts.user')` 会导致布局嵌套——页面同时渲染外层框架和内层内容，表现为"上半部分是框架首页，下半部分才是正常内容"。正确做法参照 19.6 节
10. **用户端页面导航使用 parent.PearAdmin.changePage()**：用户端子页面运行在 iframe 中，`window.location.href` 跳转仅在 iframe 内生效。需要切换页面时应使用 `parent.PearAdmin.changePage({ id: '唯一标识', title: '页面标题', url: '/user/xxx', type: '_iframe', close: true })` 通知外层框架切换标签页
11. **后台和用户端视图必须设置 CSRF Token 和登录超时处理**：独立 HTML 页面不继承布局的 CSRF 设置，必须在 `<script>` 中通过 `$.ajaxSetup` 同时设置 `headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}' }` 和 `statusCode: { 401: function(){...} }`，否则 AJAX POST 请求会被 Laravel 拦截返回 419 错误，Session 过期时请求无响应或只弹"请求失败"。详见 19.6 节
12. **⚠️ Layui 模板语法必须用 @verbatim 包裹**：Blade 视图中 Layui 的 `{{# }}` 模板语法会被 Blade 解析为 PHP 表达式导致语法错误，所有 `<script type="text/html">` 中包含 `{{# }}` 的内容必须用 `@verbatim` / `@endverbatim` 包裹。后台和用户端视图均适用。详见 19.6 节
13. **依赖外部服务的应用应提供未配置友好提示**：控制器中检查配置状态（如 `ConfigService::isConfigured()`），未配置时返回友好提示视图而非空白或报错，API 返回明确错误码和提示信息

***

## 二十三、前端终端（Home）开发

CmsPro v5 支持三种终端类型：后台管理（`admin`）、用户端（`user`）、**前端（`home`）**。其中前端终端面向公开访问用户，无需认证，任何应用都可以注册自己的前端路由和页面，实现独立的前端展示能力。

系统内置「CMSPRO官网」应用（`cmsprohome`）作为默认的官网前端实现，同时其他应用（如 Payclient）也可以注册自己的前端页面。

### 20.1 三种终端对比

| 维度 | 后台管理 | 用户端 | 前端（Home） |
| ---- | ------- | ------ | ------------ |
| 入口路径 | `/admin/` | `/user/` | 自定义（通常根路径或 `/{appId}`） |
| 认证 Guard | `auth:admin` | `auth:web` | 无（公开访问） |
| 菜单终端 | `terminal_type='admin'` | `terminal_type='user'` | `terminal_type='home'` |
| 菜单声明 | `manifest.menus` | `manifest.user_menus` | `manifest.home_menus` |
| 路由前缀 | `admin/{appId}` | `user/{appId}` | 应用自定义 |
| API 前缀 | `api/admin/` | `api/user/` | 应用自定义 |
| 布局模板 | 系统级 `layouts.admin` | 系统级 `layouts.user` | **应用自带** |
| 权限控制 | RBAC 角色权限 | 无 | 无 |

### 20.2 前端终端架构

#### 核心原则

1. **应用自带布局**：每个应用的前端页面使用自己目录下的布局模板，不依赖系统级或其他应用的布局
2. **路由自注册**：前端路由在应用的 ServiceProvider 中注册，启用时自动加载，禁用时自动移除
3. **菜单自动管理**：通过 `manifest.json` 的 `home_menus` 字段声明导航菜单，安装/卸载时自动注册/清理
4. **完全独立**：禁用或卸载某个应用不影响其他应用的前端页面

#### 目录结构（以一个典型前端应用为例）

```
app/Apps/{AppName}/
├── manifest.json                  # 应用声明（含 home_menus）
├── ServiceProvider.php            # 服务注册（含前端路由）
├── Controllers/
│   ├── Home/                     # 前端视图控制器（可选）
│   │   └── ProductController.php # 前端页面控制器
│   └── Api/                      # 前端API控制器（可选）
│       └── ProductApiController.php
├── Routes/
│   ├── web.php                   # 后台+用户端路由
│   ├── admin.php                 # 后台管理路由
│   ├── user.php                  # 用户端路由
│   ├── api.php                   # 后台/用户端 API
│   ├── home.php                  # ★ 前端页面路由（新增）
│   └── front-api.php             # ★ 前端 API 路由（可选）
└── Views/
    ├── Admin/                    # 后台视图
    ├── User/                     # 用户端视图
    ├── layouts/
    │   └── home.blade.php        # ★ 前端布局（应用自带）
    └── Home/                     # ★ 前端页面视图（可选）
        └── index.blade.php
```

#### 已有示例

系统中已有两个实现前端终端的应用：

| 应用 | app_id | 前端路径 | 说明 |
| ---- | ------ | -------- | ---- |
| **CMSPRO官网** | `cmsprohome` | `/` | 系统内置官网，包含首页、新闻、帮助等完整页面 |
| **聚合支付客户端** | `payclient` | `/payclient/` | 产品介绍页和接入指南页 |

### 20.3 注册前端路由

在应用的 `ServiceProvider::registerRoutes()` 中添加前端路由注册：

```php
protected function registerRoutes(): void
{
    // 后台管理路由
    Route::prefix('admin/{appId}')
        ->middleware(['web', 'auth:admin'])
        ->group(base_path('app/Apps/{AppName}/Routes/admin.php'));

    // 用户端路由
    Route::prefix('user/{appId}')
        ->middleware(['web', 'auth:web'])
        ->group(base_path('app/Apps/{AppName}/Routes/user.php'));

    // ★ 前端路由（无需认证）
    Route::prefix('{appId}')                          // 自定义前缀，可为空字符串表示根路径
        ->middleware(['web'])                           // 仅 web 中间件，无认证
        ->group(base_path('app/Apps/{AppName}/Routes/home.php'));

    // ★ 前端 API（可选）
    Route::prefix('api/{appId}')
        ->middleware(['throttle:60,1'])
        ->group(base_path('app/Apps/{AppName}/Routes/front-api.php'));
}
```

> **重要**：前端路由必须放在最后注册，确保不会覆盖其他应用的路由。如果需要占用根路径 `/`，建议只允许一个应用（如 cmsprohome）这样做。

#### 路由文件示例

**Routes/home.php** — 前端页面路由：

```php
use App\Apps\{AppName}\Controllers\Home\ProductController;
use Illuminate\Support\Facades\Route;

Route::get('/', [ProductController::class, 'index']);
Route::get('/guide', [ProductController::class, 'guide']);
```

### 20.4 前端控制器与视图

#### 控制器

前端控制器继承 `Illuminate\Routing\Controller`（非系统的 `App\Http\Controllers\Controller`），渲染应用内的视图：

```php
<?php

namespace App\Apps\{AppName}\Controllers\Home;

use Illuminate\Routing\Controller;

class ProductController extends Controller
{
    public function index()
    {
        return view('{appId}::Home.index');      // 使用应用视图命名空间
    }

    public function guide()
    {
        return view('{appId}::Home.guide');
    }
}
```

#### 视图继承应用自带布局

```html
{{-- Views/Home/index.blade.php --}}
@extends('{appId}::layouts.home')

@section('title', '产品首页')

@section('content')
<div class="hero-section">
    <h1>产品名称</h1>
    <p>产品描述</p>
</div>
@endsection
```

#### 加载视图

在 ServiceProvider 中注册视图命名空间：

```php
protected function loadViews(): void
{
    $this->loadViewsFrom(
        base_path('app/Apps/{AppName}/Views'),
        '{appId}'                                    // 视图命名空间，如 'cmsprohome'
    );
}
```

### 20.5 前端布局

每个应用的前端布局完全自主控制。以下是 Payclient 应用的简化布局示例：

```html
{{-- Views/layouts/home.blade.php --}}
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', '应用名称')</title>
    <link rel="stylesheet" href="{{ asset('Home/css/home.css') }}">
</head>
<body>
<header class="app-header">
    <nav>@yield('nav')</nav>
</header>

<main>@yield('content')</main>

<footer class="app-footer">@yield('footer')</footer>

@php $siteAnalytics = \App\Models\ConfigItem::where('code', 'site_analytics')->value('value'); @endphp
@if($siteAnalytics)
{!! $siteAnalytics !!}
@endif
@yield('script')
@stack('page_scripts')
</body>
</html>
```

#### 系统统计代码接入

系统后台「基础配置」中提供了「统计代码」配置项（`site_analytics`），管理员可在此填入百度统计、Google Analytics 等第三方统计代码。应用前端布局**必须**接入此配置，确保统计代码在所有前台页面生效。

**接入方式**：在布局文件（或独立前端页面）的 `</body>` 标签前添加以下代码：

```html
@php $siteAnalytics = \App\Models\ConfigItem::where('code', 'site_analytics')->value('value'); @endphp
@if($siteAnalytics)
{!! $siteAnalytics !!}
@endif
```

> **注意**：使用 `{!! !!}` 而非 `{{ }}` 输出，因为统计代码通常包含 `<script>` 标签，需要原样输出不被转义。

**不同场景的接入方式**：

| 场景 | 接入方式 | 示例 |
| ---- | -------- | ---- |
| 有统一布局文件 | 在布局文件 `</body>` 前添加代码 | `Views/layouts/home.blade.php` |
| 无统一布局（独立页面） | 创建 partial 文件，每个页面 `@include` 引入 | `@include('boxcode::front.partials.analytics')` |

partial 文件内容示例（`Views/front/partials/analytics.blade.php`）：

```html
@php $siteAnalytics = \App\Models\ConfigItem::where('code', 'site_analytics')->value('value'); @endphp
@if($siteAnalytics)
{!! $siteAnalytics !!}
@endif
```

#### 布局设计要点

- **独立性**：布局文件位于应用内部，不依赖 `resources/views/layouts/`
- **样式引用**：可复用 `public/Home/css/home.css` 中的 CSS 变量体系，也可引入自定义样式
- **View Composer**：如需动态数据（如菜单），在 ServiceProvider 中注册 View Composer：

```php
View::composer('{appId}::layouts.home', function ($view) {
    $menus = AdminMenu::where('status', 1)
        ->where('visible', 1)
        ->where('terminal_type', 'home')
        ->where('app_id', '{appId}')              // 仅查询本应用的菜单
        ->orderBy('sort', 'asc')
        ->get();

    $view->with('homeMenus', $menus);
});
```

### 20.6 home\_menus 菜单声明

应用可以在 `manifest.json` 中使用 `home_menus` 字段声明前端导航菜单（详见第十三章）：

```json
{
    "id": "myapp",
    "name": "我的应用",
    "home_menus": [
        { "code": "myapp_home", "title": "首页", "path": "/myapp", "order": 1 },
        { "code": "myapp_features", "title": "功能介绍", "path": "/myapp/features", "order": 2 },
        { "code": "myapp_docs", "title": "使用文档", "path": "/myapp/docs", "order": 3 }
    ]
}
```

`home_menus` 与 `menus` / `user_menus` 的区别：

| 维度 | `menus` | `user_menus` | `home_menus` |
| ---- | ------- | ------------ | ------------ |
| 终端类型 | `admin` | `user` | `home` |
| 认证要求 | 需登录 | 需登录 | 公开访问 |
| 支持子菜单 | 是（children） | 是（children） | 否（扁平结构） |
| 支持父级挂载 | 是（parent） | 是（parent） | 否 |
| 支持 code 字段 | 是（推荐） | 是（推荐） | 是（推荐） |
| 菜单归属 | 按 `app_id` 过滤 | 按 `app_id` 过滤 | 按 `app_id` 过滤 |

> **注意**：`home_menus` 为扁平结构，不支持 `children` 和 `parent` 字段。安装应用时自动创建 `terminal_type='home'` 且 `app_id` 匹配的菜单记录，卸载时自动清除。

### 20.7 静态资源

前端页面的静态资源统一存放在 `public/Home/` 目录下，所有前端应用共享：

```
public/Home/
├── css/
│   └── home.css               # 官网样式（CSS 变量体系）
├── logo.png                   # Logo
├── logo-nav.png              # 导航栏 Logo
├── Default/                   # 首页粒子动画资源
│   ├── Views.js
│   └── Index.js
└── admin.png                  # 后台截图等图片
```

视图中的引用方式：

```html
<link rel="stylesheet" href="{{ asset('Home/css/home.css') }}">
<img src="{{ asset('Home/logo-nav.png') }}" alt="Logo">
```

如需应用专属静态资源，可在 `public/` 下创建子目录（如 `public/{appId}/`），并在视图中引用。

### 20.8 CSS 样式规范

共享样式文件 `public/Home/css/home.css` 采用 CSS 变量体系，所有前端应用均可使用：

| 变量 | 用途 | 默认值 |
| ---- | --- | ----- |
| `--primary` | 主色调 | `#2563eb` |
| `--text` | 正文色 | `#1e293b` |
| `--bg` | 背景色 | `#ffffff` |
| `--bg-gray` | 灰色背景 | `#f8fafc` |
| `--border` | 边框色 | `#e2e8f0` |
| `--radius` | 圆角 | `8px` |
| `--max-width` | 内容最大宽度 | `1200px` |

常用样式类：`.section`、`.section-inner`、`.section-title`、`.features-grid`、`.feature-card`、`.page-banner`、`.btn`、`.btn-primary`、`.pagination`、`.empty-state` 等。

### 20.9 为应用添加前端页面的步骤

1. **创建前端控制器**：在 `Controllers/Home/` 下创建控制器，返回应用视图
2. **创建前端布局**：在 `Views/layouts/home.blade.php` 创建自有布局
3. **创建前端视图**：在 `Views/Home/` 下创建 Blade 模板，继承 `'{appId}::layouts.home'`
4. **创建前端路由文件**：在 `Routes/home.php` 定义前端路由
5. **注册前端路由**：在 `ServiceProvider::registerRoutes()` 中注册 `Routes/home.php`
6. **声明菜单**（可选）：在 `manifest.json` 的 `home_menus` 中添加菜单项
7. **注册 View Composer**（可选）：如需动态菜单数据，在 ServiceProvider 中注册
8. **重新安装应用**：使 `home_menus` 生效

### 20.10 前台路由冲突检测

当多个应用都需要注册前台路由时（尤其是根路径 `/`），会产生路由覆盖冲突。Laravel 后注册的同路径路由会覆盖先注册的，导致其中一个应用的前台页面无法访问，且结果取决于 ServiceProvider 的 boot 执行顺序，行为不可预测。

#### home\_routes 声明

在 `manifest.json` 中使用 `home_routes` 字段声明应用占用的前台路由，系统在安装和启用时会自动检测冲突：

```json
{
    "id": "cmsprohome",
    "name": "CMSPRO官网",
    "home_routes": {
        "/": "首页",
        "/about": "系统介绍",
        "/news": "新闻动态",
        "/news/{id}": "新闻详情",
        "/apps": "应用市场",
        "/license": "授权查询",
        "/help": "帮助中心"
    }
}
```

**字段格式**：

| 维度 | 说明 |
| ---- | ---- |
| 键 | 路由路径，如 `/`、`/about`、`/news/{id}` |
| 值 | 路由中文名称，用于冲突提示中展示，如 "首页"、"系统介绍" |

> `home_routes` 与 `home_menus` 的区别：`home_menus` 声明导航菜单项（写入 `admin_menus` 表），`home_routes` 声明路由占用（仅用于冲突检测，不写入数据库）。两者路径可能重叠，但职责不同。

#### 冲突检测时机

| 时机 | 检测范围 | 行为 |
| ---- | -------- | ---- |
| **安装应用时** | 所有已启用应用（ENABLED） | 拒绝安装，返回错误码 50019 |
| **启用应用时** | 所有已启用应用（ENABLED） | 拒绝启用，返回错误码 50019 |

两个时机均仅检测已启用的应用（框架由 `App\Services\AppRouteConflictDetector` 统一实现），因为只有已启用应用的路由才会实际注册；未启用应用的冲突在其实际启用时再行检测。

> **注意**：`home_routes` 冲突检测会结合每个应用实际配置的访问模式（`access_mode`）解析真实路由占用，而非直接比对 manifest 静态声明：
>
> - **root 模式**：`home_routes` 即站点根路径下的绝对路由（如 `/`、`/about`），与其他应用的绝对路由求交集；
> - **path 模式**：`home_routes` 映射为 `/{access_path}` 前缀下的绝对路由（如前缀 `forum` 时 `/` → `/forum`、`/rank` → `/forum/rank`）后再求交集，因此默认 path 模式的应用不会被误判与根路径应用冲突；
> - **domain 模式**：路由注册在绑定子域名下，与主站路径空间隔离，仅与其他 domain 应用绑定的相同域名判定冲突。
>
> 访问配置优先读取 `config_items` 中已保存的值（`app_{app_id}_access_mode` / `access_path` / `access_domain`），未保存时回退 manifest `config_groups` 访问设置组中的默认值。设置页**保存切换访问模式的瞬间**不属于安装/启用时机，框架检测不覆盖，仍需应用级校验，见下节 20.10.1。

#### 20.10.1 访问模式切换时的 root 冲突校验

应用在后台「设置页」将访问模式切换为 **root（根路径模式）** 时，会在站点根路径 `/` 下注册前台路由（如 `/`、`/projects`、`/about`）。若此时已有其他**已启用**应用通过无前缀路由占用这些根路径（如官网应用 Cmsprohome 注册了 `/`、`/about`），将产生路由覆盖冲突。设置页**保存切换访问模式的瞬间**不属于安装/启用时机，框架的 `home_routes` 冲突检测不覆盖，因此必须由应用自行校验。

因此，**在设置页 `SettingController::update()` 中必须增加 root 模式冲突校验**，与 path/domain 模式的必填校验并列：

```php
// 根路径模式冲突检测：若已有其他启用应用占用根路径，则拒绝保存
if ($validated['access_mode'] === 'root') {
    $conflict = $this->findRootPathConflict();
    if ($conflict !== null) {
        return response()->json(ApiResponse::error(40002, $conflict['message'], ['conflicts' => $conflict['paths']]));
    }
}
```

校验逻辑（`findRootPathConflict()`）要点：

| 要点 | 说明 |
| ---- | ---- |
| 本应用 root 模式路由清单 | 硬编码与 `Routes/home.php` 一致的路径，如 `/`、`/projects`、`/projects/{id}`、`/about` |
| 检测范围 | 仅遍历**已启用**应用（`AppStatus::ENABLED`），因为只有已启用应用的路由才会实际注册 |
| 排除自身 | 跳过 `app_id === 本应用` 的记录 |
| 比对依据 | 读取其他应用 manifest 的 `home_routes`，与自身 root 路由清单求交集 |
| 冲突处理 | 有交集则**拒绝保存**并返回错误码 40002 及冲突明细，提示先禁用/卸载冲突应用 |

```php
protected function findRootPathConflict(): ?array
{
    // 本应用 root 模式下会注册的前端路由（与 Routes/home.php 保持一致）
    $myRoutes = ['/' => '演示首页', '/projects' => '项目展示', '/about' => '关于演示'];

    $conflicts = [];
    $enabledApps = AppModel::where('status', AppStatus::ENABLED)->get();

    foreach ($enabledApps as $app) {
        if ($app->app_id === self::APP_ID) {
            continue; // 跳过自身
        }
        $otherRoutes = ($app->manifest ?? [])['home_routes'] ?? [];
        foreach ($myRoutes as $path => $title) {
            if (isset($otherRoutes[$path])) {
                $conflicts[] = ['path' => $path, 'app' => $app->name ?: $app->app_id, 'title' => $otherRoutes[$path]];
            }
        }
    }

    if (empty($conflicts)) {
        return null;
    }

    $lines = array_map(fn ($c) => "路由 {$c['path']} 已被「{$c['app']}」占用（{$c['title']}）", $conflicts);

    return [
        'message' => '根路径模式与已启用应用冲突，无法保存：' . implode('；', $lines) . '。请先禁用或卸载冲突应用后再切换为根路径模式。',
        'paths' => $conflicts,
    ];
}
```

同时建议在设置页前端（`index.blade.php`）做**双层防护**：

1. **列表接口附带冲突结果**：`getSettings()` 返回 `root_conflict` 字段，前端在用户切换到 root 模式时动态展示红色冲突提示区，列出占用应用及冲突路径，避免用户提交后被驳回的困惑。
2. **前端提交前拦截**：当 `access_mode === 'root'` 且存在冲突时，直接 `layer.msg()` 提示并阻止 AJAX 提交，减少一次无谓请求。

> **适用场景**：任何支持 root 访问模式、且可能与其他已启用应用争夺根路径的应用，都应在设置页保存时加入此校验（可参考 Demo示例应用 `CmsproDemo` 的 `SettingController` 实现）。

#### 冲突提示示例

```
检测到前台路由冲突：
1. 路由 /：已被「CMSPRO官网」占用（首页），与「企业官网」冲突（首页）
2. 路由 /about：已被「CMSPRO官网」占用（系统介绍），与「企业官网」冲突（关于我们）
3. 路由 /news：已被「CMSPRO官网」占用（新闻动态），与「企业官网」冲突（新闻动态）
请先禁用或卸载冲突应用后再安装。
```

#### 处理方式

| 场景 | 处理方式 |
| ---- | -------- |
| 仅一个应用占用根路径 `/` | 推荐 cmsprohome 作为唯一根路径应用 |
| 多个应用各有前缀 | 各应用使用不同前缀，如 `/payclient/`、`/boxcode/` |
| 需要替换前台应用 | 先禁用/卸载当前前台应用，再安装/启用新应用 |
| 根路径被占用时的兜底 | 系统在 `routes/web.php` 中保留兜底路由，显示「暂未开放」提示 |

#### 根路径兜底

当 cmsprohome 应用被禁用时，系统根路径 `/` 显示兜底页面：

```php
// routes/web.php 中的兜底路由
Route::get('/', function () {
    return response()->view('home-disabled', [], 503);
})->name('home.disabled');
```

由于应用路由在 ServiceProvider 中动态注册，禁用应用后路由自动不注册，系统兜底路由生效。

### 20.11 注意事项

1. **公开访问**：前端页面无需认证，所有内容应对公开用户可见，**不应返回敏感数据**
2. **布局独立性**：每个应用必须自带前端布局，禁止依赖其他应用的布局文件
3. **路由顺序**：前端路由应在 ServiceProvider 中最后注册，避免覆盖其他应用的路由
4. **命名空间隔离**：视图使用 `{appId}::` 命名空间前缀，避免与其他应用冲突
5. **API 安全**：前端 API 接口应设置合理的频率限制（throttle），防止滥用
6. **菜单隔离**：`home_menus` 通过 `app_id` 字段自动过滤，各应用只能看到自己的菜单
7. **静态资源**：公共样式存放于 `public/Home/`，应用专属资源建议存放于 `public/{appId}/`
8. **生命周期一致**：启用应用 → 路由生效 → 菜单可见；禁用应用 → 路由移除 → 菜单隐藏
9. **声明 home\_routes 避免路由冲突**：注册前台路由的应用必须在 `manifest.json` 中声明 `home_routes` 字段，系统会在安装和启用时自动检测路由冲突并提示。未声明 `home_routes` 的应用不会参与冲突检测，但可能导致路由覆盖而无法访问
10. **接入系统统计代码**：应用前端布局必须在 `</body>` 前接入 `site_analytics` 系统配置，确保管理员在后台「基础配置→统计代码」中填写的第三方统计代码（百度统计、Google Analytics 等）能在所有前台页面生效。详见 20.5 节

***

## 二十四、应用域名绑定

CmsPro v5 支持应用前端通过**子域名**或**路径前缀**两种方式访问。应用可在 `manifest.json` 的 `config_groups` 中声明访问模式配置，ServiceProvider 根据配置动态选择 `Route::domain()` 或 `Route::prefix()` 注册前端路由，实现配置驱动的双模式访问。

### 22.1 两种访问模式对比

| 维度 | 路径前缀模式 | 子域名绑定模式 |
| ---- | ------------ | -------------- |
| 访问地址 | `example.com/forum/` | `forum.example.com/` |
| 路由注册 | `Route::prefix('forum')` | `Route::domain('forum.example.com')` |
| 配置复杂度 | 低（开箱即用） | 高（需 DNS + Web 服务器 + Session 配置） |
| SEO 友好度 | 一般 | 优（独立域名） |
| Session 共享 | 自动（同域） | 需配置 `SESSION_DOMAIN` |
| 适用场景 | 大多数应用 | 需要独立品牌域名的应用 |

### 22.2 配置项声明

在 `manifest.json` 的 `config_groups` 中声明以下三个配置项：

```json
{
    "config_groups": [
        {
            "name": "access_settings",
            "title": "访问设置",
            "items": [
                {
                    "name": "access_mode",
                    "title": "访问模式",
                    "type": "select",
                    "value": "path",
                    "options": [
                        { "label": "路径前缀", "value": "path" },
                        { "label": "子域名绑定", "value": "domain" }
                    ],
                    "tips": "路径前缀模式：通过 /forum/ 访问；子域名模式：通过 forum.example.com 访问"
                },
                {
                    "name": "access_domain",
                    "title": "绑定域名",
                    "type": "text",
                    "value": "",
                    "tips": "子域名模式下生效，支持多域名绑定，以英文逗号分隔，如 forum.example.com,bbs.example.com。需在 DNS 中添加解析并在 .env 中设置 SESSION_DOMAIN=.example.com"
                },
                {
                    "name": "access_path",
                    "title": "路径前缀",
                    "type": "text",
                    "value": "forum",
                    "tips": "路径前缀模式下生效，如设置为 forum 则通过 /forum/ 访问"
                }
            ]
        }
    ]
}
```

配置项存储到数据库后，code 格式为 `app_{应用id}_{name}`，如 `app_cmspro_forum_access_mode`。

### 22.3 ServiceProvider 路由注册

在 ServiceProvider 中根据配置动态注册前端路由：

```php
protected function registerHomeRoutes(): void
{
    $accessMode = $this->getConfigValue('access_mode', 'path');

    if ($accessMode === 'domain') {
        $domainConfig = $this->getConfigValue('access_domain', '');
        if (empty($domainConfig)) {
            return; // 未配置域名则不注册前端路由
        }

        // 支持逗号分隔的多域名，如 "forum.example.com,bbs.example.com"
        $domains = array_map('trim', explode(',', $domainConfig));
        $domains = array_filter($domains);

        foreach ($domains as $domain) {
            // 子域名模式：前端页面路由
            Route::domain($domain)
                ->middleware(['web'])
                ->namespace('App\Apps\{AppName}\Controllers\Home')
                ->group(base_path('app/Apps/{AppName}/Routes/home.php'));

            // 子域名模式：应用 API 路由
            Route::domain($domain)
                ->prefix('api/{appId}')
                ->middleware(['throttle:60,1'])
                ->namespace('App\Apps\{AppName}\Controllers\HomeApi')
                ->group(base_path('app/Apps/{AppName}/Routes/home-api.php'));

            // ★ 子域名模式：其他公开 API 路由也必须在 foreach 内注册
            // 应用中如有除 home-api 外还需要在子域名上公开访问的 API 路由
            // （如直播源 API、数据上报 API、第三方接口等），必须在此处使用
            // Route::domain($domain) 包裹后注册。如果只在 boot() 中无 domain
            // 约束注册，子域名上的请求会被 catch-all 路由拦截返回 404。
            // 反例（子域名上不可访问）：
            //   Route::prefix('api/cmspro/{module}')
            //       ->group(base_path('.../Routes/some-api.php'));
            // 正例（子域名上可访问）：
            Route::domain($domain)
                ->prefix('api/cmspro/{module}')
                ->middleware(['web', 'throttle:60,1'])
                ->namespace('App\Apps\{AppName}\Controllers\Api')
                ->group(base_path('app/Apps/{AppName}/Routes/public-api.php'));
        }
    } else {
        // 路径前缀模式
        $path = $this->getConfigValue('access_path', '{appId}');
        Route::prefix($path)
            ->middleware(['web'])
            ->namespace('App\Apps\{AppName}\Controllers\Home')
            ->group(base_path('app/Apps/{AppName}/Routes/home.php'));

        Route::prefix('api/{appId}')
            ->middleware(['throttle:60,1'])
            ->namespace('App\Apps\{AppName}\Controllers\HomeApi')
            ->group(base_path('app/Apps/{AppName}/Routes/home-api.php'));
    }
}

/**
 * 从数据库读取配置值
 */
protected function getConfigValue(string $name, string $default = ''): string
{
    try {
        $value = \App\Models\ConfigItem::where('code', 'app_{应用id}_' . $name)->value('value');
        return $value ?? $default;
    } catch (\Throwable $e) {
        return $default;
    }
}
```

### 22.4 不影响 home 的保证

| 模式 | 应用访问 | home 访问 | 隔离机制 |
| ---- | -------- | --------- | -------- |
| 子域名 | `forum.example.com/*` | `www.example.com/*` | `Route::domain()` 仅匹配指定域名 |
| 路径前缀 | `example.com/forum/*` | `example.com/*`（根路径） | `Route::prefix()` 仅匹配指定前缀 |

两种模式下，home 模块（cmsprohome）的路由均不受影响：
- 子域名模式：`Route::domain('forum.example.com')` 仅响应 `forum.example.com` 域名的请求，`www.example.com` 的请求由 home 模块处理
- 路径前缀模式：`Route::prefix('forum')` 仅响应 `/forum/` 前缀的请求，根路径 `/` 由 home 模块处理

### 22.4.1 子域名路由隔离

> **重要规则**：绑定子域名的应用，子域名上**只能访问该应用注册的路由**，其他所有路径一律返回 404。

#### 设计原理

Laravel 的 `Route::domain($domain)` 是**添加**该域名下的路由，**不会限制**未指定 domain 的路由在该域名上不可访问。未指定 domain 的全局路由（如 `/admin/*`、`/user/*`、`/api/admin/*`）会在所有域名上响应，导致子域名能访问到后台管理、用户中心等非本应用的路由，存在安全隐患。

CmsPro v5 通过**子域名 catch-all 路由**实现隔离：在 `AppServiceProvider::registerDomainRoutesEarly()` 中为每个子域名注册一个 catch-all 路由（`ANY {any}`），匹配所有未被应用路由覆盖的请求并返回 404。

#### 隔离机制

子域名上的路由匹配顺序：

| 顺序 | 路由来源 | 示例 |
| ---- | -------- | ---- |
| 1 | AppServiceProvider 提前注册的子域名前端路由 | `/`、`/t/{id}`、`/login` |
| 2 | 应用 ServiceProvider 在 registerHomeRoutes() 或 boot() 中通过 Route::domain() 注册的子域名 API 路由 | `/api/forum/*`、`/api/cmspro/{module}/*` |
| 3 | 子域名 catch-all 路由（未匹配的请求返回 404） | 其他所有路径 |

catch-all 路由通过 `booted` 回调延迟注册，确保晚于应用 API 路由注册，不拦截应用自身的 API。

> **注意**：404 页面返回 HTTP 200 状态码而非 404。这是因为部分 Nginx 生产环境启用了 `fastcgi_intercept_errors on`，Laravel 返回 404 状态码时会被 Nginx 拦截并替换为 Nginx 默认 404 页面，导致无法显示 Laravel 的 404 视图。使用 200 状态码可确保 404 页面内容正常渲染，同时页面仍展示明确的"页面不存在"错误信息。此决策不影响 API 请求的 404 响应（API 请求仍然返回标准的 HTTP 404 状态码）。

#### 行为预期

| 请求 | 行为 |
| ---- | ---- |
| `bbs.example.com/` | 应用首页 ✓ |
| `bbs.example.com/t/123` | 应用页面 ✓ |
| `bbs.example.com/api/forum/topics` | 应用 API ✓ |
| `bbs.example.com/admin/login` | **404**（子域名不可访问后台） |
| `bbs.example.com/user/login` | **404**（子域名不可访问用户中心） |
| `bbs.example.com/api/admin/users` | **404**（子域名不可访问管理 API） |
| 主域名 `example.com/admin/login` | 后台登录页 ✓（主域名不受影响） |

#### 应用开发约束

由于子域名路由隔离的存在，**子域名模式下应用必须自包含**：

1. **应用必须有独立的登录流程**：不能依赖全局 `/user/login` 或 `/admin/login`，应在应用前端路由中提供自己的登录页和认证逻辑
2. **应用 API 路由必须在子域名下注册**：API 路由需要使用 `Route::domain($domain)` 包裹，否则在子域名上不可访问。已在 ServiceProvider 中通过域名模式注册 API 路由的应用自动满足此要求

> **⚠️ 重要：`auth:web` 未登录跳转陷阱**（应用自定义前台路由必须注意）
>
> 系统在 `bootstrap/app.php` 中全局渲染了 `AuthenticationException`（未登录异常），逻辑如下：
> ```php
> $exceptions->render(function (AuthenticationException $e, $request) {
>     if ($request->expectsJson()) {
>         return response()->json(ApiResponse::error(40003, '登录已过期，请重新登录'), 401);
>     }
>     return redirect()->guest(
>         (str_starts_with($request->path(), 'user') || str_starts_with($request->path(), 'boxcode'))
>             ? '/user/login'
>             : route('admin.login')
>     );
> });
> ```
> 它**只识别以 `user` 或 `boxcode` 开头**的路径会跳前台登录 `/user/login`，**其余路径一律跳转后台登录页 `admin.login`**。因此，应用自定义前台路由（如 `/shop/user`、`/shop/user/orders`）若直接使用 `auth:web` 中间件，未登录时会被误跳转到后台登录页。
>
> **正确做法**：应用自定义前台受保护路由时，应提供一个**应用级认证中间件**，未登录时跳转到应用自己的登录页（而非触发全局 `AuthenticationException`）：
>
> ```php
> // Middleware/FrontAuthMiddleware.php
> namespace App\Apps\{AppName}\Middleware;
>
> use Closure;
> use Illuminate\Http\Request;
>
> class FrontAuthMiddleware
> {
>     public function handle(Request $request, Closure $next): mixed
>     {
>         if (! auth('web')->check()) {
>             // JSON/AJAX 请求返回 401，跳转交给前端处理
>             if ($request->expectsJson() || $request->ajax()) {
>                 return response()->json([
>                     'code' => 40003,
>                     'message' => '登录已过期，请重新登录',
>                     'data' => null,
>                 ], 401);
>             }
>             // 页面请求重定向到应用自己的登录页
>             return redirect()->guest(应用自己的前台登录URL);
>         }
>         return $next($request);
>     }
> }
> ```
>
> 然后在 `ServiceProvider::boot()` 注册中间件别名，并在受保护路由组中使用它：
> ```php
> // ServiceProvider::boot()
> $this->app['router']->aliasMiddleware('{appId}.auth', \App\Apps\{AppName}\Middleware\FrontAuthMiddleware::class);
>
> // Routes/home.php（页面路由）
> Route::middleware('{appId}.auth')->group(function () {
>     Route::get('/user', 'UserController@index');
>     Route::get('/user/orders', 'UserController@orders');
> });
> ```
> 该中间件同时处理页面与 JSON 请求：页面未登录跳应用登录页，AJAX 未登录返回 401（由前端 `window.location` 统一跳转登录页）。

   以下是一个完整的路由注册示例，展示了**正确的做法**和**常见的错误**：

   ```php
   // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   // ServiceProvider.php - registerRoutes() 和 registerHomeRoutes()
   // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   public function boot(): void
   {
       $this->registerRoutes();
       // ...
   }

   protected function registerRoutes(): void
   {
       // 后台管理路由（无 domain 约束，始终通过主域名访问）
       Route::prefix('admin/cmspro/{module}')
           ->middleware(['web', 'auth:admin'])
           ->group(base_path('.../Routes/admin.php'));

       // ⚠️ 以下路由在未绑定子域名时有效，但在子域名上不可访问
       // 它们的注册是正确的（供路径前缀模式使用），但子域名模式下需要额外处理
       Route::prefix('api/cmspro/{module}/public')
           ->middleware(['web', 'throttle:60,1'])
           ->group(base_path('.../Routes/public-api.php'));

       // ★ 前端路由（子域名/路径前缀双模式）
       $this->registerHomeRoutes();
   }

   protected function registerHomeRoutes(): void
   {
       $accessMode = $this->getConfigValue('access_mode', 'path');

       if ($accessMode === 'domain') {
           $domains = array_filter(array_map('trim', explode(',', $this->getConfigValue('access_domain', ''))));

           foreach ($domains as $domain) {
               // 前端页面路由
               Route::domain($domain)
                   ->middleware(['web'])
                   ->group(base_path('.../Routes/home.php'));

               // 应用 API
               Route::domain($domain)
                   ->prefix('api/{appId}')
                   ->middleware(['throttle:60,1'])
                   ->group(base_path('.../Routes/home-api.php'));

               // ✅ 正确的做法：其他公开 API 路由也必须在此用 Route::domain() 注册
               // 否则子域名上访问时会被 catch-all 路由拦截返回 404
               Route::domain($domain)
                   ->prefix('api/cmspro/{module}/public')
                   ->middleware(['web', 'throttle:60,1'])
                   ->group(base_path('.../Routes/public-api.php'));
           }
       } else {
           // 路径前缀模式（无 domain 约束，主域名下通过路径前缀访问）
           $path = $this->getConfigValue('access_path', '{appId}');
           Route::prefix($path)
               ->middleware(['web'])
               ->group(base_path('.../Routes/home.php'));

           Route::prefix('api/{appId}')
               ->middleware(['throttle:60,1'])
               ->group(base_path('.../Routes/home-api.php'));

           // 路径前缀模式下，公开 API 路由已在 registerRoutes() 中注册，此处不需要重复
       }
   }
   ```

   > **容易踩坑的地方**：公开 API 路由（如直播源列表、数据上报等非 admin 路由）如果只在 `registerRoutes()` 中用 `Route::prefix()` 注册了一次，在**路径前缀模式**下正常，但切换到**子域名模式**后，这些路由在子域名上会返回 404。根本原因是 catch-all 路由拦截了所有未用 `Route::domain($domain)` 注册的路由。修复方法就是在 `registerHomeRoutes()` 的 domain 模式分支中，用 `Route::domain($domain)` 再注册一次。
3. **视图中不可硬编码其他模块路径**：所有链接必须使用应用自身的辅助函数（如 `forum_url()`）生成，不可硬编码 `/admin/*`、`/user/*` 等全局路径
4. **静态资源由 Web 服务器直接处理**：生产环境中 Nginx 直接响应静态资源请求，不到达 Laravel；开发环境 `php artisan serve` 下静态资源若被 catch-all 拦截返回 404，需配置 Nginx 代理或后续扩展白名单

##### 4.1 跨应用链接标准方案

子域名上不能访问全局路由（如 `/user` 返回 404），因此跨其他应用的页面链接、iframe 嵌入、AJAX 请求需分场景处理：

| 场景 | 方案 | 示例 |
| ---- | ---- | ---- |
| **页面链接** | 使用 `main_url()` 辅助函数生成指向主域名的绝对 URL | `<a href="{{ main_url('user') }}">用户中心</a>` |
| **iframe 嵌入** | iframe src 直接指向主域名页面，不需要 CORS | `<iframe src="{{ main_url('user/cmspro/signin') }}">` |
| **AJAX 请求** | **优先服务端注入数据**（View Composer 查询后 `@json` 输出到 JS 变量）；必须 AJAX 时，请求主域名 API + CORS 中间件 | 见下方详情 |

> **说明**：`main_url()` 是系统提供的辅助函数（位于 `app/helpers.php`），在绑定子域名上返回主域名绝对 URL（`http://主域名/path`），在非绑定域名上返回相对路径（`/path`）。主域名从 `.env` 的 `APP_URL` 动态读取，不硬编码。

**服务端注入方案（推荐，避免跨域）：**

```php
// ServiceProvider.php View Composer 中查询数据
View::composer('{appId}::layouts.home', function ($view) {
    $status = null;
    if (auth('web')->check()) {
        try {
            $service = app(\App\Apps\OtherApp\Services\SomeService::class);
            $status = $service->getUserStatus(auth('web')->id());
        } catch (\Throwable $e) {
            // 异常时静默处理，JS 端降级显示默认值
        }
    }
    $view->with('crossAppStatus', $status);
});
```

```html
{{-- 视图中注入到 JS 变量 --}}
<script>
window.crossAppStatus = @json($crossAppStatus);
</script>
```

```javascript
// JS 中优先使用服务端注入数据，避免跨域请求
if (window.crossAppStatus) {
    applyStatus(window.crossAppStatus);
} else {
    // fallback：AJAX 请求主域名 API（需配合 CORS 中间件）
}
```

**iframe 嵌入方案（浏览器原生支持跨域）：**

子域名页面通过 iframe 嵌入主域名页面时，浏览器对 `SameSite=Lax` 的处理规则：用户从子域名页面**点击操作**触发的 iframe 导航，浏览器视为顶层导航，会携带主域名的 session cookie。因此 iframe 嵌入**不需要** CORS 支持。

```html
{{-- 子域名上嵌入签到页面：点击触发 iframe 弹窗，src 指向主域名 --}}
<button onclick="openIframe('{{ main_url('user/cmspro/signin') }}')">签到</button>
```

但 iframe 内页面完成操作后**调用父页面 JS 刷新状态**时（如签到成功后通知父页面），需使用 `parent.postMessage()` 通信，而非直接 AJAX 请求（跨域限制）。父页面通过 `window.addEventListener('message', handler)` 接收消息。

##### 4.2 CORS 中间件规范

当必须通过 AJAX 从子域名请求主域名 API 时（如上方案的 fallback 场景），需要配合 CORS 中间件处理跨域。CORS 中间件的开发需遵循以下规范：

1. **路径白名单**：仅对指定的 API 路径放行，不可全局开放 CORS
2. **Origin 校验**：检查请求 `Origin` 是否在已绑定的子域名列表（`AppServiceProvider::getBoundDomains()`）中，仅允许已知子域名
3. **OPTIONS 预检拦截**：OPTIONS 请求必须在中间件中直接返回 204 + 完整 CORS 头，**不得进入路由层**（否则被 `auth:web` 中间件重定向导致 CORS 失败）
4. **中间件注册方式**：必须使用 `prepend()` 注册到全局中间件列表，**不可使用 `append()`**。因 Laravel 11 默认注册了 `HandleCors` 全局中间件，`append()` 会将自定义中间件加到末尾，OPTIONS 请求被 `HandleCors` 处理后直接返回（不调用 `$next`），自定义中间件不会被执行

```php
// ❌ 错误：自定义 CORS 中间件在 HandleCors 之后执行，永远不会处理 OPTIONS
$middleware->append(AllowSubdomainCors::class);

// ✅ 正确：自定义 CORS 中间件在 HandleCors 之前执行，先处理 OPTIONS
$middleware->prepend(AllowSubdomainCors::class);
```

5. **`withCredentials: true` 的限制**：设置 `withCredentials: true` 时，`Access-Control-Allow-Origin` 不能为 `*`，必须为请求来源的具体 origin；同时必须设置 `Access-Control-Allow-Credentials: true`

### 22.5 Session 域名配置

子域名模式下，主站和子域名需要共享 Session，否则用户在主站登录后访问子域名仍为未登录状态。

在 `.env` 中设置：

```
SESSION_DOMAIN=.example.com
```

> **注意**：`SESSION_DOMAIN` 前面的点号（`.`）表示 Cookie 对所有子域名生效。设置后主站和所有子域名共享同一 Session。

### 22.6 URL 生成辅助函数

由于前端路由的域名/前缀是动态配置的，不能硬编码 URL。建议在 ServiceProvider 的 `register()` 方法中注册辅助函数，根据当前配置自动生成正确的 URL：

```php
if (!function_exists('{appId}_url')) {
    function {appId}_url(string $path = ''): string
    {
        $accessMode = \App\Models\ConfigItem::where('code', 'app_{应用id}_access_mode')->value('value') ?? 'path';

        if ($accessMode === 'domain') {
            $domainConfig = \App\Models\ConfigItem::where('code', 'app_{应用id}_access_domain')->value('value') ?? '';
            $domains = array_map('trim', explode(',', $domainConfig));
            $domains = array_filter($domains);

            // 优先使用当前请求匹配的域名，否则取第一个
            $currentHost = request()->getHost();
            $domain = in_array($currentHost, $domains) ? $currentHost : ($domains[0] ?? '');

            if (!empty($domain)) {
                $scheme = request()->isSecure() ? 'https' : 'http';
                return rtrim("{$scheme}://{$domain}", '/') . '/' . ltrim($path, '/');
            }
        }

        $prefix = \App\Models\ConfigItem::where('code', 'app_{应用id}_access_path')->value('value') ?? '{appId}';
        return '/' . trim($prefix, '/') . '/' . ltrim($path, '/');
    }
}
```

视图中使用：

```html
<a href="{{ forum_url('t/' . $topic->id) }}">{{ $topic->title }}</a>
```

### 22.7 子域名模式部署前置条件

使用子域名模式前，需完成以下配置：

| 步骤 | 说明 |
| ---- | ---- |
| DNS 解析 | 添加子域名 A 记录或 CNAME 记录，如 `forum.example.com → 服务器IP` |
| Web 服务器 | 配置虚拟主机，将子域名指向 CmsPro 入口文件（`code/public/index.php`） |
| Session 域名 | 在 `.env` 中设置 `SESSION_DOMAIN=.example.com` |
| 应用配置 | 在后台论坛设置中选择"子域名绑定"并填写绑定域名 |
| 缓存清除 | 修改配置后执行 `php artisan route:clear && php artisan config:clear` |

**【硬性要求】配置一致性约束（必须遵循）**：

当应用配置了 `access_domain`（绑定域名）时，`access_mode` **必须**同时设置为 `domain`。若 `access_mode` 为空字符串或 `path`，系统不会将该子域名识别为"已绑定应用子域名"，将导致以下严重后果：

1. **子域名不注册域名路由**：`AppServiceProvider::registerDomainRoutesEarly()` 在检查 `access_mode !== 'domain'` 时会跳过该应用，不为该子域名注册 `Route::domain()` 路由。用户访问该子域名不会进入应用，只会进入主站兜底路由（显示主站首页或 404）。
2. **子域名被强制跳转**：开启"非WWW跳转"（`force_www_redirect` 配置项）后，`ForceWwwRedirect` 中间件会通过 `AppServiceProvider::getBoundDomains()` 判断子域名是否已绑定应用。`access_mode` 非 `domain` 的子域名不在该列表中，会被 301 跳转到 www 主域名，用户无法访问。

**应用开发约束**：

- 应用 `manifest.json` 中 `access_mode` 配置项必须设置明确的默认值（`path` 或 `domain`），**禁止留空**
- 应用安装/升级脚本必须确保 `access_mode` 配置项的 value 不为空字符串
- 用户在后台修改 `access_domain` 时，应用 ServiceProvider 应同步校验 `access_mode` 是否为 `domain`，否则提示用户

**Nginx 配置示例**：

```nginx
server {
    listen 80;
    server_name forum.example.com;
    root /path/to/cmspro/code/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### 21.8 多域名绑定

`access_domain` 配置项支持绑定多个域名，以英文逗号分隔：

```
forum.example.com,bbs.example.com,community.example.com
```

#### 路由注册

ServiceProvider 会将配置中的域名拆分后逐个注册 `Route::domain()`，每个域名都绑定完整的前端路由和 API 路由，用户通过任意一个域名均可正常访问。

#### URL 生成策略

辅助函数（如 `forum_url()`）在多域名场景下按以下策略选择域名：

1. **当前请求域名在配置列表中**：使用当前请求的域名，保持用户访问的域名一致性
2. **当前请求域名不在配置列表中**：使用配置中的第一个域名作为默认值

例如用户通过 `bbs.example.com` 访问时，`forum_url('t/1')` 生成 `https://bbs.example.com/t/1`，而非 `https://forum.example.com/t/1`，避免域名跳转导致 Session 丢失。

#### 性能影响

多域名拆分使用 `explode(',', $domainConfig)`，开销约 0.001ms，远小于已有的数据库查询开销（0.5-2ms），对整体性能无影响。

#### 部署要求

每个绑定的域名都需要完成 DNS 解析和 Web 服务器配置，详见 22.7 节。

### 22.9 注意事项

1. **模式互斥**：`access_mode` 只能为 `path` 或 `domain`，不可同时启用两种模式
2. **域名切换需清除缓存**：修改访问模式后需执行 `php artisan route:clear` 和 `php artisan config:clear`，或在后台设置页面自动清除
3. **API 路由前缀固定**：前端 API 路由（`api/{appId}`）不随访问模式变化，始终使用路径前缀
4. **配置值从数据库读取**：ServiceProvider 中读取配置使用 `ConfigItem` 模型直接查询数据库，不使用 `config()` 函数（应用配置存储在数据库中，`config()` 可能读到缓存旧值）
5. **未配置域名时不注册路由**：子域名模式下如果 `access_domain` 为空，ServiceProvider 应跳过前端路由注册，避免注册无效的域名路由
6. **视图链接使用辅助函数**：视图中所有指向应用内页面的链接必须使用辅助函数（如 `forum_url()`）生成，不可硬编码路径
7. **home_menus 路径适配**：`manifest.json` 中 `home_menus` 的 `path` 字段应使用路径前缀模式的路径（如 `/forum`），子域名模式下导航菜单由应用自带布局渲染
8. **多域名绑定**：`access_domain` 支持逗号分隔的多个域名（如 `forum.example.com,bbs.example.com`），每个域名都会注册完整路由和 catch-all 隔离路由。辅助函数优先使用当前请求匹配的域名，保持用户访问一致性。详见 22.8 节
9. **子域名路由隔离**：绑定子域名的应用，子域名上只能访问该应用注册的路由，其他所有路径返回 404。应用必须提供独立的登录流程、API 路由需在子域名下注册、视图中不可硬编码全局路径。详见 22.4.1 节
10. **跨应用链接使用 `main_url()`**：子域名上指向其他应用的页面链接必须使用 `main_url()` 辅助函数生成主域名绝对 URL；iframe 嵌入直接指向主域名（不需要 CORS）；AJAX 优先使用服务端注入数据（View Composer），必须 AJAX 时配合 CORS 中间件。详见 22.4.1 节
11. **CORS 中间件必须 `prepend()` 注册**：当开发子域名跨域 API 中间件时，必须在 `bootstrap/app.php` 中使用 `$middleware->prepend()` 而非 `$middleware->append()`。Laravel 11 默认注册了 `HandleCors` 全局中间件，`append()` 会将自定义中间件加到最后，OPTIONS 预检请求在 `HandleCors` 中直接返回（不调用 `$next`），自定义中间件不会被执行。详见 22.4.1 节第 4.2 条
12. **`HandleCors` 默认注册**：Laravel 11 默认注册了 `HandleCors` 全局中间件（位于 `getGlobalMiddleware()` 列表），所有请求都会经过它。若 `config/cors.php` 不存在，`config->get('cors', [])` 返回空数组，`HandleCors` 不处理任何请求。若创建了 `config/cors.php` 文件且配置了 `paths`，子域名上所有 AJAX 都会被 `HandleCors` 的 `*` 策略覆盖（`withCredentials: true` 时不允许 `*`）。如需自定义 CORS，应使用 `prepend()` 注册中间件在 `HandleCors` 之前拦截
13. **路由缓存限制**：子域名 catch-all 路由通过 booted 回调延迟注册，不会被 `php artisan route:cache` 缓存。若启用路由缓存，catch-all 将失效，子域名隔离机制失效。**本项目不应启用 `route:cache`**
14. **所有公开 API 路由必须在 registerHomeRoutes() 的域名模式中注册**：子域名模式下，仅在 `registerRoutes()` 中用 `Route::prefix()` 注册的公开 API 路由（非 admin 路由），在子域名上会被 catch-all 路由拦截返回 404。必须同时在 `registerHomeRoutes()` 的 `foreach ($domains as $domain)` 循环中，使用 `Route::domain($domain)` 注册这些 API 路由。判断依据：如果该 API 需要在子域名上被第三方（如 TVBox 客户端、外部应用）访问，就必须在域名模式分支中注册。详见 22.4.1 节第 2 条的应用开发约束和代码示例。
15. **`access_mode` 与 `access_domain` 配置一致性（硬性约束）**：当应用配置了 `access_domain`（绑定域名非空）时，`access_mode` **必须**为 `domain`。若 `access_mode` 为空字符串或 `path`，`AppServiceProvider::registerDomainRoutesEarly()` 会跳过该应用，导致子域名既不注册域名路由，也不被 `getBoundDomains()` 收录，进而被 `ForceWwwRedirect` 中间件 301 跳转到 www 主域名。应用 `manifest.json` 中 `access_mode` 必须设置明确默认值（`path` 或 `domain`），**禁止留空**；应用安装/升级时必须确保该配置项 value 不为空字符串。详见 21.7 节"配置一致性约束"

### 22.10 三种访问模式（frontend / path / domain）相互兼容

> 除 22.1-22.9 介绍的 `path`（路径前缀）与 `domain`（子域名）两种模式外，CmsPro 还支持 **`frontend`（前端/根路径）模式**。三种模式可在后台设置页切换，且相互兼容。参考实现：`CmsproBlog`、`NiurenDistributor` 应用。

#### 22.10.1 三种模式对比

| 模式 | 访问地址 | 路由注册 | 适用场景 |
| ---- | -------- | -------- | -------- |
| `path`（路径前缀，默认） | `example.com/shop/` | `Route::prefix('shop')` | 大多数应用，开箱即用 |
| `frontend`（前端/根路径） | `example.com/` | 无 prefix 无 domain | 站点主应用，占用根路径 |
| `domain`（子域名绑定） | `shop.example.com/` | `Route::domain('shop.example.com')` | 需要独立品牌域名的应用 |

#### 22.10.2 manifest.json 配置项声明

`access_mode` 的 `options` 需包含三种模式，默认值建议为 `path`（除非应用明确作为站点主应用）：

```json
{
    "name": "access_settings",
    "title": "访问设置",
    "items": [
        {
            "name": "access_mode",
            "title": "访问模式",
            "type": "select",
            "value": "path",
            "options": [
                { "label": "路径前缀", "value": "path" },
                { "label": "前端模式（根路径）", "value": "frontend" },
                { "label": "子域名绑定", "value": "domain" }
            ],
            "tips": "路径前缀模式：通过 /shop/ 访问；前端模式：占用根路径 /（站点主应用）；子域名模式：通过 shop.example.com 访问。切换后需刷新路由缓存"
        },
        {
            "name": "access_domain",
            "title": "绑定域名",
            "type": "text",
            "value": "",
            "tips": "子域名模式下生效，支持多域名绑定，以英文逗号分隔"
        },
        {
            "name": "access_path",
            "title": "路径前缀",
            "type": "text",
            "value": "shop",
            "tips": "路径前缀模式下生效，如设置为 shop 则通过 /shop/ 访问"
        }
    ]
}
```

#### 22.10.3 ServiceProvider 三模式路由注册

```php
protected function registerHomeRoutes(): void
{
    $accessMode = $this->getConfigValue('access_mode', 'path');

    if ($accessMode === 'domain') {
        // 子域名模式：前台页面和 API 均在子域名下注册
        $domainConfig = $this->getConfigValue('access_domain', '');
        if (empty($domainConfig)) {
            return; // 未配置域名则不注册前台路由
        }
        $domains = array_filter(array_map('trim', explode(',', $domainConfig)));
        foreach ($domains as $domain) {
            Route::domain($domain)
                ->middleware(['web'])
                ->namespace('App\Apps\{AppName}\Controllers\Home')
                ->group(base_path('app/Apps/{AppName}/Routes/home.php'));

            Route::domain($domain)
                ->prefix('api/{appId}')
                ->middleware(['web', 'throttle:60,1'])
                ->namespace('App\Apps\{AppName}\Controllers\HomeApi')
                ->group(base_path('app/Apps/{AppName}/Routes/home-api.php'));
        }
    } elseif ($accessMode === 'path') {
        // 路径前缀模式：前台页面路由加 prefix
        $path = $this->getConfigValue('access_path', '{appId}');
        Route::prefix($path)
            ->middleware(['web'])
            ->namespace('App\Apps\{AppName}\Controllers\Home')
            ->group(base_path('app/Apps/{AppName}/Routes/home.php'));

        // API 路由保持全局前缀（不跟随 path）
        Route::prefix('api/{appId}')
            ->middleware(['web', 'throttle:60,1'])
            ->namespace('App\Apps\{AppName}\Controllers\HomeApi')
            ->group(base_path('app/Apps/{AppName}/Routes/home-api.php'));
    } else {
        // 前端模式：根路径 /，无 prefix 无 domain
        Route::middleware(['web'])
            ->namespace('App\Apps\{AppName}\Controllers\Home')
            ->group(base_path('app/Apps/{AppName}/Routes/home.php'));

        Route::prefix('api/{appId}')
            ->middleware(['web', 'throttle:60,1'])
            ->namespace('App\Apps\{AppName}\Controllers\HomeApi')
            ->group(base_path('app/Apps/{AppName}/Routes/home-api.php'));
    }
}
```

#### 22.10.4 前台 URL 辅助函数（三模式兼容）

应用内所有指向前台页面的链接（分享链接、支付回调、视图内部链接）必须通过辅助函数生成，根据 `access_mode` 自动适配：

```php
public static function frontUrl(string $path): string
{
    $accessMode = (string) config('apps.{appId}.access_mode', 'path');

    if ($accessMode === 'domain') {
        $domain = (string) config('apps.{appId}.access_domain', '');
        $firstDomain = trim(explode(',', $domain)[0] ?? '');
        if ($firstDomain !== '') {
            $scheme = request()->isSecure() ? 'https' : 'http';
            return $scheme . '://' . $firstDomain . '/' . ltrim($path, '/');
        }
    }

    if ($accessMode === 'frontend') {
        return url('/' . ltrim($path, '/'));
    }

    // path 模式
    $prefix = trim((string) config('apps.{appId}.access_path', '{appId}'), '/');
    return url('/' . ($prefix !== '' ? $prefix . '/' : '') . ltrim($path, '/'));
}
```

前端 JS 中拼接内部链接时，可在布局中注入基础路径变量：

```blade
<script>
    // 前台基础路径（兼容三种访问模式）
    // path 模式：/shop；frontend 模式：/；domain 模式：/（同域相对路径）
    window.SHOP_BASE = @json(\App\Apps\{AppName}\Services\ShareService::frontUrl('/'));
</script>
```

#### 22.10.5 frontend（根路径）模式冲突校验

`frontend` 模式会在站点根路径 `/` 下注册前台路由，若已有其他**已启用**应用占用这些根路径，将产生路由覆盖冲突。**安装时的 `home_routes` 检测无法拦截**（因为声明路径与 root 模式实际注册路径不一致），因此必须在设置页 `SettingController::update()` 中增加冲突校验：

```php
// 根路径模式冲突检测：若已有其他启用应用占用根路径，则拒绝保存
if ($validated['access_mode'] === 'frontend') {
    $conflict = $this->findRootPathConflict();
    if ($conflict !== null) {
        return response()->json([
            'success' => false,
            'message' => $conflict['message'],
            'data'    => ['conflicts' => $conflict['paths']],
        ], 400);
    }
}
```

```php
protected function findRootPathConflict(): ?array
{
    // 本应用 frontend 模式下会注册的前端路由（与 Routes/home.php 保持一致）
    $myRoutes = ['/' => '首页', '/product/{id}' => '商品详情', '/order/result' => '支付结果'];

    $conflicts = [];
    $enabledApps = AppModel::where('status', AppStatus::ENABLED)->get();

    foreach ($enabledApps as $app) {
        if ($app->app_id === self::APP_ID) {
            continue; // 跳过自身
        }
        $otherRoutes = ($app->manifest ?? [])['home_routes'] ?? [];
        foreach ($myRoutes as $path => $title) {
            if (isset($otherRoutes[$path])) {
                $conflicts[] = ['path' => $path, 'app' => $app->name ?: $app->app_id, 'title' => $otherRoutes[$path]];
            }
        }
    }

    if (empty($conflicts)) {
        return null;
    }

    $lines = array_map(fn ($c) => "路由 {$c['path']} 已被「{$c['app']}」占用（{$c['title']}）", $conflicts);

    return [
        'message' => '前端模式与已启用应用冲突，无法保存：' . implode('；', $lines) . '。请先禁用或卸载冲突应用后再切换为前端模式。',
        'paths'   => $conflicts,
    ];
}
```

同时建议在设置页前端做**双层防护**：
1. `index()` 返回 `root_conflict` 字段，前端在用户切换到 `frontend` 模式时动态展示红色冲突提示区
2. 前端提交前拦截：当 `access_mode === 'frontend'` 且存在冲突时，直接 `layer.msg()` 提示并阻止 AJAX 提交

#### 22.10.6 三模式兼容注意事项

1. **API 路由前缀固定**：三种模式下 API 路由均保持 `api/{appId}`，不随访问模式变化（domain 模式下在子域名内注册）
2. **home_menus 路径适配**：`manifest.json` 中 `home_menus` 的 `path` 使用路径前缀模式的路径（如 `/shop`），`frontend`/`domain` 模式下导航菜单由应用自带布局渲染
3. **home_routes 声明**：`home_routes` 声明路径前缀模式的路径（如 `/shop/*`），用于安装/启用时的冲突检测；`frontend` 模式的实际根路径冲突由 22.10.5 的运行时校验处理
4. **视图链接不可硬编码**：所有指向应用内页面的链接必须使用辅助函数（如 `frontUrl()`）或注入的基础路径变量生成，禁止硬编码 `/shop/...`
5. **切换后清缓存**：修改访问模式后必须执行 `php artisan route:clear && php artisan config:clear`
6. **domain 模式自包含**：子域名模式下应用必须自包含（独立登录、API 在子域名注册、视图不硬编码全局路径），详见 22.4.1 节

#### 22.10.7 配置存储一致性（重要踩坑）

> 切换访问模式（子域名/前端模式）后不生效的问题现场与根因详见 [CMSPRO-v5-应用开发常见问题.md](./CMSPRO-v5-应用开发常见问题.md) 第 11 章；以下为双表同步写入的规范。

> **症状**：后台将访问模式切换为「子域名」或「前端模式」并保存后，访问子域名/根路径仍是首页（path 模式），切换不生效。

**根因**：CmsPro 应用的配置可能同时存储在两处，而**路由注册读取的配置表**与**设置页写入的配置表**不一致：

| 存储 | 表 | 作用 |
|------|-----|------|
| 框架配置表 | `config_items`（code 前缀 `app_{应用id}_`） | 应用安装时由 manifest 的 `config_groups` 自动创建；`ServiceProvider::getConfigValue()` 从这里读取 `access_mode` 决定**路由注册方式** |
| 应用配置表 | `app_{应用id}_settings`（应用自定义） | 应用自己的设置页读写、运行时 `overrideConfigFromDatabase()` 覆盖 `config()` |

**问题**：若 `SettingController::save()` 只写入应用配置表（`app_{应用id}_settings`），而 `ServiceProvider` 注册路由时从框架配置表（`config_items`）读取 `access_mode`，则保存后路由仍按旧模式注册，导致切换不生效。

**正确做法**：设置页保存时，**必须同步写入两个表**，保持两者一致：

```php
// SettingController::save() 中，写入应用配置表的同时同步框架配置表
foreach ($data as $code => $value) {
    $this->settingService->set($code, $value); // 写入 app_{应用id}_settings

    // 同步写入框架 config_items 表（code 前缀 app_{应用id}_）
    $configItemCode = 'app_' . str_replace('.', '_', self::APP_ID) . '_' . $code;
    if (\App\Models\ConfigItem::where('code', $configItemCode)->exists()) {
        \App\Models\ConfigItem::where('code', $configItemCode)->update(['value' => (string) $value]);
    }
}
```

**其他注意点**：
1. **`frontUrl()` 等辅助函数读取 `config('apps.{appId}.access_mode')`**，该值由 `overrideConfigFromDatabase()` 从应用配置表覆盖。若应用配置表与应用实际模式不一致，生成的链接也会错误（如 frontend 模式仍生成 `/shop/...`）。因此**两个表必须始终一致**。
2. **直接改数据库时**：若手动修改 `config_items` 表切换模式，必须同步修改应用配置表，否则路由变了但链接生成仍按旧模式。
3. **切换后清缓存**：修改访问模式后必须执行 `php artisan route:clear && php artisan config:clear && php artisan cache:clear`。
4. **自测建议**：切换每种模式后，分别验证「路由注册」（`php artisan route:list`）、「页面访问」（首页/商品详情/登录页）、「链接生成」（`frontUrl()` 输出）三项，确保三模式均正常。

