# CMSPRO UI 开发规范

> **版本**：v1.4.0
> **更新日期**：2026-08-14
> **适用范围**：CmsPro v5.0.0+ 后台管理、用户中心、前台展示及所有应用（`app/Apps/{AppName}/`）的视图开发
> **文档定位**：本规范是 CMSPRO 产品界面开发的强制性标准，用于统一视觉风格、规范图标使用、消除"AI 味"界面，确保产品界面的专业性与一致性。所有视图开发、代码审查、质量验收均须以此为准。

***

## 目录

1. [总则与设计理念](#一总则与设计理念)
2. [图标资源使用规范](#二图标资源使用规范)
3. [禁止使用 emoji 替代图标](#三禁止使用-emoji-替代图标)
4. [视觉一致性要求](#四视觉一致性要求)
5. [组件样式标准](#五组件样式标准)
6. [设计语言统一规范](#六设计语言统一规范)
7. [资源本地化要求](#七资源本地化要求)
8. [实施细则与检查标准](#八实施细则与检查标准)
9. [附录：图标速查表](#九附录图标速查表)
10. [前台 H5 应用设计规范](#十前台-h5-应用设计规范)
11. [动效与交互反馈规范](#十一动效与交互反馈规范)
12. [可访问性（无障碍）规范](#十二可访问性无障碍规范)
13. [前台 PC 官网（门户）应用设计规范](#十三前台-pc-官网门户应用设计规范)

***

## 一、总则与设计理念

### 1.1 规范目的

CMSPRO 是面向企业级用户的专业管理系统。本规范旨在解决以下核心问题：

1. **消除"AI 味"界面**：AI 生成代码时倾向于直接使用 emoji（如 ✅、🚀、📌、🔧）替代专业图标，导致界面风格轻浮、不统一、缺乏专业感。本规范明确禁止此类行为。
2. **统一图标标准**：规定图标必须来自系统内置的 FontAwesome / Layui 图标库，统一引用方式与尺寸。
3. **保证视觉一致性**：统一色彩、字体、间距、组件样式，使所有页面呈现一致的品牌观感。
4. **确保可检查性**：提供明确的检查清单与验收标准，便于开发自检与质量团队验证。

### 1.2 设计理念

- **专业克制**：界面服务于业务效率，避免装饰性元素堆砌。图标用于辅助理解，不喧宾夺主。
- **统一一致**：同一语义的图标、颜色、组件在全局范围内保持一致，不因页面不同而随意变化。
- **清晰高效**：信息层级分明，操作路径直观，减少用户认知负担。
- **本地可靠**：所有资源完全本地化，不依赖外部网络，保证内网/离线环境下的稳定运行。

### 1.3 适用范围

| 场景 | 是否适用 |
|------|---------|
| 后台管理页面（`Admin/`） | ✅ 强制 |
| 用户中心页面（`User/`） | ✅ 强制 |
| 前台展示页面（`Home/`） | ✅ 强制 |
| 应用视图（`app/Apps/{AppName}/Views/`） | ✅ 强制 |
| 应用图标（`manifest.json` / `icon.svg`） | ✅ 强制 |
| 系统级框架页面 | ✅ 参照执行 |

***

## 二、图标资源使用规范

### 2.1 官方图标库

CMSPRO 系统内置两套官方图标库，**所有界面图标必须从这两套库中选取**，禁止使用 emoji、Unicode 符号、自绘图片或其他来源的图标。

| 图标库 | 版本 | 本地路径 | 引用 CSS | 类名前缀 |
|--------|------|---------|---------|---------|
| FontAwesome | 4.7.0 | `public/CmsProUi/font-awesome/4.7.0/` | `font-awesome.min.css` | `fa fa-xxx` |
| Layui 图标 | 内置 | `public/CmsProUi/component/layui/` | `layui.css` | `layui-icon layui-icon-xxx` |

### 2.2 图标库获取方式

两套图标库均已随系统内置，**无需额外下载或引入**。开发时直接引用本地 CSS 即可：

```html
<!-- FontAwesome 图标库 -->
<link rel="stylesheet" href="{{ asset('CmsProUi/font-awesome/4.7.0/css/font-awesome.min.css') }}">

<!-- Layui 图标库（随 layui.css 一并加载） -->
<link rel="stylesheet" href="{{ asset('CmsProUi/component/layui/css/layui.css') }}">
```

> **注意**：`layui.css` 已包含 Layui 图标字体（`iconfont`），引入 layui.css 后即可直接使用 `layui-icon` 类名，无需额外引入字体文件。

### 2.3 图标引用方法

#### 2.3.1 FontAwesome 图标

```html
<!-- 基础用法 -->
<i class="fa fa-plus"></i>
<i class="fa fa-edit"></i>
<i class="fa fa-trash"></i>

<!-- 带颜色（用于状态/语义强调） -->
<i class="fa fa-check-circle" style="color: #16b777;"></i>
<i class="fa fa-times-circle" style="color: #ff5722;"></i>
```

#### 2.3.2 Layui 图标

```html
<!-- 基础用法 -->
<i class="layui-icon layui-icon-add-1"></i>
<i class="layui-icon layui-icon-edit"></i>
<i class="layui-icon layui-icon-delete"></i>

<!-- 按钮内图标 -->
<button class="layui-btn layui-btn-sm">
    <i class="layui-icon layui-icon-add-1"></i> 新增
</button>
```

#### 2.3.3 应用图标（manifest.json）

应用图标支持三种方式（按优先级从高到低）：

1. **图标文件**（推荐）：应用根目录放置 `icon.svg`（推荐）或 `icon.png`，建议 120×120 像素，系统通过 `/api/app/{appId}/icon` 自动提供访问。
2. **FontAwesome 类名**：`"icon": "fa fa-book"`
3. **Layui 图标类名**：`"icon": "layui-icon layui-icon-app"`

```json
{
    "id": "cmspro.blog",
    "name": "博客",
    "icon": "fa fa-book"
}
```

### 2.4 图标尺寸规范

| 使用场景 | 推荐字号 | 说明 |
|---------|---------|------|
| 按钮内图标（`layui-btn-sm`） | 14px | 与按钮文字同高，垂直居中 |
| 按钮内图标（`layui-btn`） | 16px | 标准按钮 |
| 表格行内操作图标 | 14px | 与行内文字对齐 |
| 导航/菜单图标 | 16px | 侧边栏菜单项 |
| 卡片标题图标 | 16px | 卡片头部 |
| 状态/徽标图标 | 12px | 状态指示 |
| 空状态大图标 | 48px | 居中展示，弱化颜色 |

**尺寸原则**：图标字号应与相邻文字字号一致或略小，保持视觉协调。禁止图标过大或过小导致失衡。

### 2.5 图标使用原则

1. **语义匹配**：图标必须与所表达的业务语义一致。例如"新增"用 `fa-plus` / `layui-icon-add-1`，"删除"用 `fa-trash` / `layui-icon-delete`。
2. **图标+文字**：功能按钮建议"图标 + 文字"组合，避免纯图标按钮造成理解歧义（除非是全局公认的图标如搜索、关闭）。
3. **一致性**：同一功能在全局使用同一图标，禁止同一功能在不同页面使用不同图标。
4. **颜色克制**：图标默认继承文字颜色，仅在状态强调时使用语义色（成功绿、危险红、警告橙）。
5. **禁止混用**：同一页面内 FontAwesome 与 Layui 图标可混用，但同一语义的图标应保持一致来源，避免视觉风格割裂。

### 2.6 SVG 图标创建规范

当业务所需的图标在 FontAwesome 与 Layui 图标库中**均不存在**时，允许使用 **SVG 图标**进行补充创建。SVG 是矢量格式，可精确控制尺寸与颜色，且完全本地化，是官方图标库之外唯一允许的图标来源。

#### 2.6.1 使用前提（优先级）

图标选择优先级从高到低：

1. **FontAwesome 图标库**（`fa fa-xxx`）—— 优先使用
2. **Layui 图标库**（`layui-icon layui-icon-xxx`）—— 次选
3. **SVG 图标** —— 仅当上述两库均无对应图标时使用

> **【强制】** 禁止在官方图标库已有对应图标的情况下，仍创建 SVG 图标。创建 SVG 前必须先确认两套图标库中确实不存在所需图标。

#### 2.6.2 SVG 图标存放位置

SVG 图标文件统一存放于应用自身的 `Assets/` 目录下，通过 `public/apps/{appId}/` 访问：

```
app/Apps/{AppName}/Assets/
├── icons/
│   ├── workflow.svg
│   ├── approval.svg
│   └── ...
```

> 系统在应用安装/升级时自动将 `Assets/` 发布为 `public/apps/{appId}/` 符号链接，应用无需自行处理资源复制。

#### 2.6.3 SVG 图标引用方法

```html
<!-- 方式一：img 标签引用（推荐，简单可靠） -->
<img src="{{ asset('apps/cmspro.blog/icons/workflow.svg') }}" alt="工作流" class="app-icon">

<!-- 方式二：内联 SVG（需控制颜色时使用） -->
<svg class="app-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
    <path d="M..."/>
</svg>
```

**推荐原则**：
- 仅需展示、无需动态变色时，用 `<img>` 引用。
- 需要跟随文字/主题变色（`currentColor`）时，用内联 SVG。

#### 2.6.4 SVG 图标规范

| 项目 | 规范 |
|------|------|
| 画布尺寸 | `viewBox="0 0 24 24"`（统一 24×24 网格） |
| 描边风格 | 线性图标，`stroke-width="2"`，`fill="none"` |
| 颜色 | 默认 `stroke="currentColor"`，继承文字颜色 |
| 圆角 | 线条端点 `stroke-linecap="round"`、`stroke-linejoin="round"` |
| 尺寸 | 通过 CSS 控制（`width`/`height`），遵循 2.4 节尺寸规范 |
| 命名 | 语义化小写命名，如 `workflow.svg`、`approval.svg` |

**标准 SVG 模板**：

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="2"
     stroke-linecap="round" stroke-linejoin="round">
    <!-- 图标路径 -->
</svg>
```

#### 2.6.5 SVG 图标样式控制

```css
/* 统一图标尺寸与颜色 */
.app-icon {
    width: 16px;
    height: 16px;
    vertical-align: middle;
    color: inherit;   /* 继承文字颜色 */
}
```

- 图标颜色默认继承文字颜色，需要语义色时通过 `color` 指定（如 `color: #ff5722`）。
- 禁止在 SVG 内部硬编码固定颜色（除非是品牌多色图标），以保证主题一致性。

#### 2.6.6 SVG 图标检查要点

- [ ] 创建 SVG 前已确认 FontAwesome 与 Layui 图标库中无对应图标。
- [ ] SVG 文件存放于应用 `Assets/` 目录，通过 `public/apps/{appId}/` 访问。
- [ ] 使用统一 `viewBox="0 0 24 24"` 网格。
- [ ] 线性风格，`stroke-width="2"`，`fill="none"`。
- [ ] 颜色使用 `currentColor`，未硬编码固定色。
- [ ] 未使用外部 SVG 链接（如 iconfont 在线地址）。

### 2.7 FontAwesome 4.7 版本兼容性说明

**系统当前使用 FontAwesome 4.7.0**，部分常见图标在 4.7 版本中**不存在**，使用前必须验证。以下是 FA 5+ 才有、但 FA 4.7 中**不可用**的图标：

#### 2.7.1 FA 4.7 不可用图标清单

| 图标类名 | 说明 | FA 4.7 替代方案 |
|---------|------|-----------------|
| `fa fa-coffee` | 咖啡杯 | `fa fa-cutlery`（餐具）或自定义 SVG |
| `fa fa-tools` | 工具组 | `fa fa-wrench`（扳手）或 `fa fa-cog`（齿轮） |
| `fa fa-mug-hot` | 热饮杯 | `fa fa-glass`（玻璃杯）或自定义 SVG |
| `fa fa-utensils` | 餐具组 | `fa fa-cutlery`（餐具） |
| `fa fa-hamburger` | 汉堡 | 自定义 SVG 图标 |
| `fa fa-pizza-slice` | 披萨 | 自定义 SVG 图标 |
| `fa fa-bowl-food` | 碗装食物 | 自定义 SVG 图标 |

#### 2.7.2 FA 4.7 餐别图标推荐

针对订餐签到等餐饮场景，推荐使用以下 FA 4.7 兼容图标：

| 餐别 | 推荐图标 | 说明 |
|------|---------|------|
| 早餐 | `fa fa-sun-o` | 太阳（象征早晨） |
| 午餐 | `fa fa-cutlery` | 餐具 |
| 晚餐 | `fa fa-moon-o` | 月亮（象征夜晚） |
| 下午茶 | `fa fa-glass` | 玻璃杯 |

#### 2.7.3 图标验证方法

开发时不确定图标是否在 FA 4.7 中可用时：

1. **查阅速查表**：参考第九章图标速查表
2. **浏览器测试**：直接在页面中测试图标类名是否正常渲染
3. **控制台检查**：打开 DevTools Elements 面板，检查 `<i>` 元素是否有实际渲染内容

**【强制】禁止仅凭 AI 知识判断图标可用性**，必须以实际测试为准。

### 2.8 动态图标渲染规范

#### 2.8.1 正确渲染方式

当图标类名从后端获取或由 JavaScript 动态生成时，**必须使用 `<i>` 标签包裹**，将类名作为 `class` 属性值，禁止直接输出字符串：

```html
<!-- ✅ 正确：使用 <i> 标签渲染 -->
<i class="fa fa-user"></i>

<!-- ❌ 错误：直接输出类名字符串（显示为文字而非图标） -->
<div>fa fa-user</div>
```

#### 2.8.2 JavaScript 动态渲染示例

```javascript
// ❌ 错误：直接将图标类名作为文本内容
var html = '<div class="icon">' + meal.icon + '</div>';
// 结果：页面显示 "fa fa-coffee" 文字，而非图标

// ✅ 正确：使用 <i> 标签包裹
var iconClass = meal.icon || 'fa fa-cutlery';
var html = '<i class="' + iconClass + ' meal-icon"></i>';
// 结果：正确渲染为 FontAwesome 图标
```

#### 2.8.3 图标动态渲染检查要点

- [ ] 后端返回的图标类名（如 `fa fa-xxx`）被正确解析为 `<i>` 标签
- [ ] 图标类名未被作为纯文本输出
- [ ] 图标尺寸通过 CSS class 控制（如 `.meal-icon { font-size: 28px; }`）
- [ ] 图标颜色支持通过 `style="color: xxx"` 动态设置

***

## 三、禁止使用 emoji 替代图标

### 3.1 核心禁令

> **【强制】** 在 CMSPRO 所有界面中，**禁止使用任何 emoji 字符（如 ✅、🚀、📌、🔧、⭐、⚠️、❌、➕、➖、🔍、📊、💾、🔄 等）替代专业图标**。

emoji 在不同操作系统、浏览器、字体环境下渲染差异巨大，且风格轻浮、色彩杂乱，严重破坏企业级产品的专业形象与一致性。所有需要图标的位置必须使用 FontAwesome 或 Layui 图标库。

### 3.2 禁止使用 emoji 的具体场景

以下界面元素和交互场景**一律禁止**使用 emoji，必须替换为官方图标库图标：

| 场景 | 禁止示例（emoji） | 正确做法（官方图标） |
|------|------------------|---------------------|
| **按钮** | `<button>✅ 保存</button>` | `<i class="layui-icon layui-icon-ok"></i> 保存` |
| **导航栏/菜单** | `📁 文章管理` | `<i class="fa fa-folder"></i> 文章管理` |
| **功能图标** | `🔧 设置` | `<i class="fa fa-cog"></i> 设置` |
| **状态指示** | `✅ 已启用` / `❌ 已禁用` | `<span class="layui-badge layui-bg-green">启用</span>` |
| **表格操作列** | `✏️ 编辑` / `🗑️ 删除` | `<i class="fa fa-edit"></i> 编辑` / `<i class="fa fa-trash"></i> 删除` |
| **搜索框** | `🔍 搜索` | `<i class="layui-icon layui-icon-search"></i>` |
| **弹窗标题/提示** | `⚠️ 确认删除？` | `layer.confirm('确认删除？', { icon: 3 })` |
| **空状态** | `📭 暂无数据` | `<i class="layui-icon layui-icon-face-smile"></i> 暂无数据` |
| **卡片标题** | `📊 数据统计` | `<i class="fa fa-bar-chart"></i> 数据统计` |
| **面包屑/路径** | `🏠 首页` | `<i class="fa fa-home"></i> 首页` |
| **表单标签/说明** | `📌 必填项` | 使用 `lay-verify="required"` 或文字说明 |
| **加载/进度** | `⏳ 加载中` | `layer.load()` / `layui-icon-loading` |
| **成功/失败提示** | `✅ 操作成功` | `layer.msg('操作成功', { icon: 1 })` |
| **开关/勾选** | `✔️` | `layui-form-onswitch` / `layui-icon-ok` |
| **用户头像/占位** | `👤` | `<i class="fa fa-user"></i>` 或图片 |
| **消息/通知** | `🔔 通知` | `<i class="fa fa-bell"></i> 通知` |
| **导出/下载** | `📥 导出` | `<i class="fa fa-download"></i> 导出` |
| **排序/筛选** | `↕️` | `layui-icon-sort` / `fa fa-sort` |
| **返回/前进** | `⬅️ 返回` | `<i class="fa fa-arrow-left"></i> 返回` |

### 3.3 允许使用 emoji 的例外场景

以下场景**允许**使用 emoji，但需谨慎：

1. **业务内容本身**：用户提交的内容、富文本正文、公告/文章正文中的表情（属于业务数据，非界面元素）。
2. **纯展示性装饰**：前台营销页、欢迎页等非功能性装饰（需经设计评审确认）。
3. **用户头像/昵称**：用户自定义内容。

> **判断标准**：凡是承担"功能指示、状态表达、操作引导"作用的图标，一律禁止 emoji；仅作为业务数据内容展示时方可使用。

### 3.4 emoji 与图标的本质区别

| 维度 | emoji | 官方图标库 |
|------|-------|-----------|
| 渲染一致性 | 跨平台差异大 | 统一字体渲染，完全一致 |
| 视觉风格 | 彩色、卡通、轻浮 | 单色、线性、专业 |
| 尺寸控制 | 受字体影响，难精确控制 | 通过 font-size 精确控制 |
| 语义准确性 | 模糊、易误解 | 语义明确、规范统一 |
| 品牌一致性 | 破坏统一观感 | 保持品牌一致 |

***

## 四、视觉一致性要求

### 4.1 色彩系统

#### 4.1.1 品牌主色

CMSPRO 品牌主色通过 CSS 变量统一管理，定义于 `public/Admin/css/variables.css`：

```css
:root {
    --global-primary-color: #16baaa;   /* 品牌主色（青绿色） */
    --global-border-radius: 4px;        /* 全局圆角 */
}
```

**使用原则**：
- 主色用于品牌强调、主按钮、选中态、链接、导航高亮等。
- 页面中必须通过 `var(--global-primary-color)` 引用主色，**禁止硬编码**主色值（便于全局换肤）。
- 如需在自定义样式中使用主色，统一写 `var(--global-primary-color)`。

#### 4.1.2 语义色板

| 语义 | 色值 | 用途 | 对应 Layui 类 |
|------|------|------|--------------|
| 主色（青绿） | `#16baaa` | 主按钮、品牌强调 | `layui-btn` |
| 信息蓝 | `#1e9fff` | 信息/常规操作按钮 | `layui-btn-normal` |
| 成功绿 | `#16b777` | 成功状态、启用、开关 | `layui-bg-green` / `layui-form-onswitch` |
| 危险红 | `#ff5722` | 删除、禁用、错误 | `layui-btn-danger` / `layui-bg-red` |
| 警告橙 | `#ffb800` | 警告、待处理 | `layui-btn-warm` / `layui-bg-orange` |
| 中性灰 | `#5f5f5f` | 次要文字、禁用 | `layui-btn-primary` |
| 边框灰 | `#e6e6e6` | 分割线、边框 | `layui-border` |
| 背景灰 | `whitesmoke` | 页面背景 | `layui-bg-gray` |

**使用原则**：
- 语义色仅用于表达对应语义，禁止随意挪用（如用红色表示"正常"）。
- 状态色优先使用 Layui 内置类（`layui-badge layui-bg-green` 等），避免自定义色值。
- 自定义颜色必须从上述色板中选取，禁止引入色板外的随机颜色。

#### 4.1.3 状态色使用规范

| 状态 | 颜色 | 推荐写法 |
|------|------|---------|
| 启用/成功 | 绿 `#16b777` | `<span class="layui-badge layui-bg-green">启用</span>` |
| 禁用/失败 | 灰/红 | `<span class="layui-badge layui-bg-gray">禁用</span>` |
| 待处理/警告 | 橙 `#ffb800` | `<span class="layui-badge layui-bg-orange">待审核</span>` |
| 信息/进行中 | 蓝 `#1e9fff` | `<span class="layui-badge layui-bg-blue">处理中</span>` |

### 4.2 字体规范

#### 4.2.1 字体族

系统统一使用以下字体栈（Layui 默认），**禁止自定义字体族**：

```css
font-family: Helvetica Neue, Helvetica, PingFang SC, Tahoma, Arial, sans-serif;
```

- 中文优先使用 `PingFang SC`（苹方），回退到系统默认中文字体。
- 禁止引入外部字体（如 Google Fonts），保证离线可用。

#### 4.2.2 字号规范

| 层级 | 字号 | 用途 |
|------|------|------|
| 页面标题 | 20px | 页面主标题 |
| 区块标题 | 16px | 卡片标题、分组标题 |
| 正文 | 14px | 默认正文、表格内容 |
| 辅助文字 | 12px | 说明、提示、次要信息 |
| 徽标/标签 | 12px | 状态徽标 |

**使用原则**：
- 正文统一 14px，禁止随意放大缩小。
- 标题层级清晰，禁止出现无层级的大字号堆砌。
- 数字/英文与中文混排时保持基线对齐。

### 4.3 间距标准

| 间距 | 值 | 用途 |
|------|-----|------|
| 页面内边距 | 15px | 页面内容与容器边缘 |
| 卡片内边距 | 15px | 卡片内容内边距 |
| 区块间距 | 15px | 卡片之间、区块之间 |
| 表单项间距 | 15px | 表单字段之间 |
| 元素内间距 | 10px | 按钮内图标与文字间距 |
| 紧凑间距 | 5px | 相邻小元素 |

**使用原则**：
- 间距遵循 5px 的倍数体系（5/10/15/20），保持节奏统一。
- 优先使用 Layui 栅格（`layui-col-md*`）与内置间距类，避免自定义魔法数字。
- 禁止在同一页面混用多种间距体系。

### 4.4 布局原则

1. **栅格系统**：使用 Layui 栅格（`layui-row` / `layui-col-md*`）进行响应式布局。
2. **卡片化**：内容以 `layui-card` 组织，搜索区、表格区、表单区各自成卡。
3. **对齐**：表单标签右对齐、输入框左对齐，保持纵向对齐一致。
4. **留白**：保持适度留白，避免内容拥挤；禁止大面积空白或过度堆叠。
5. **圆角统一**：所有卡片、输入框、按钮统一使用 `var(--global-border-radius)`（4px）。

***

## 五、组件样式标准

### 5.1 按钮（Button）

#### 5.1.1 类型与语义

| 类型 | 类名 | 用途 |
|------|------|------|
| 主按钮 | `layui-btn` | 主要操作（提交、保存） |
| 信息按钮 | `layui-btn layui-btn-normal` | 常规操作（新增、编辑） |
| 危险按钮 | `layui-btn layui-btn-danger` | 危险操作（删除） |
| 警告按钮 | `layui-btn layui-btn-warm` | 警告操作 |
| 次要按钮 | `layui-btn layui-btn-primary` | 次要操作（取消、清空） |

#### 5.1.2 尺寸

| 尺寸 | 类名 | 用途 |
|------|------|------|
| 大 | `layui-btn-lg` | 页面级主操作 |
| 默认 | `layui-btn` | 常规 |
| 小 | `layui-btn-sm` | 表格工具栏、行内操作 |
| 超小 | `layui-btn-xs` | 表格行内紧凑操作 |

#### 5.1.3 规范示例

```html
<!-- 工具栏新增按钮（图标+文字） -->
<button class="layui-btn layui-btn-sm" lay-event="add" data-permission="admin.role.store">
    <i class="layui-icon layui-icon-add-1"></i> 新增
</button>

<!-- 表单提交/清空按钮 -->
<button type="submit" class="layui-btn layui-btn-normal layui-btn-sm" lay-submit lay-filter="save">
    <i class="layui-icon layui-icon-ok"></i> 提交
</button>
<button type="reset" class="layui-btn layui-btn-primary layui-btn-sm">
    <i class="layui-icon layui-icon-refresh"></i> 清空
</button>

<!-- 行内操作 -->
<a class="layui-btn layui-btn-xs" lay-event="edit" data-permission="admin.role.update">
    <i class="fa fa-edit"></i> 编辑
</a>
<a class="layui-btn layui-btn-xs layui-btn-danger" lay-event="delete" data-permission="admin.role.destroy">
    <i class="fa fa-trash"></i> 删除
</a>
```

#### 5.1.4 状态与交互

- **默认态**：按类型显示对应底色。
- **悬停态**：Layui 内置加深效果，禁止自定义。
- **禁用态**：`disabled` 属性，Layui 自动置灰。
- **加载态**：`layui-btn` 加 `layui-icon-loading` 图标表示处理中。

**规范**：
- 同一操作区按钮尺寸保持一致。
- 主操作按钮放右侧/首位，次要操作放其后。
- 危险操作（删除）必须二次确认（`layer.confirm`）。

### 5.2 表单（Form）

#### 5.2.1 表单结构

```html
<form class="layui-form" lay-filter="xxxForm">
    <div class="layui-form-item">
        <label class="layui-form-label">名称</label>
        <div class="layui-input-block">
            <input type="text" name="name" lay-verify="required" placeholder="请输入名称" class="layui-input" autocomplete="off">
        </div>
    </div>
</form>
```

#### 5.2.2 表单规范

1. **标签**：使用 `layui-form-label`，长标签通过 `white-space: nowrap` 保持单行（见视图规范 3.3 节）。
2. **必填校验**：使用 `lay-verify="required"`，禁止用 emoji 或星号以外的自定义标记。
3. **占位符**：统一格式"请输入/请选择 + 字段名"。
4. **禁用覆盖**：**禁止覆盖** Layui 表单组件的默认尺寸样式（`.layui-form-label` 的 `width`、`.layui-input-block` 的 `margin-left`），否则会导致 select 下拉面板定位偏移。
5. **输入框**：统一 `layui-input`，圆角由 `var(--global-border-radius)` 控制。

#### 5.2.3 表单控件

| 控件 | 类名 | 说明 |
|------|------|------|
| 文本输入 | `layui-input` | 单行文本 |
| 多行文本 | `layui-textarea` | 多行文本 |
| 下拉选择 | `select` + `layui-form` | 需 `form.render('select')` |
| 单选 | `layui-form-radio` | 单选组 |
| 复选 | `layui-form-checkbox` | 复选组 |
| 开关 | `layui-form-switch` | 布尔开关 |
| 日期 | `laydate` | 日期选择 |

### 5.3 卡片（Card）

```html
<div class="layui-card">
    <div class="layui-card-header">
        <i class="fa fa-bar-chart"></i> 数据统计
    </div>
    <div class="layui-card-body">
        <!-- 内容 -->
    </div>
</div>
```

**规范**：
- 卡片圆角统一 `var(--global-border-radius)`。
- 卡片标题可配图标（`fa fa-xxx`），图标与标题间距 5px。
- 卡片之间间距 15px。

### 5.4 表格（Table）

#### 5.4.1 表格配置规范

```js
table.render({
    elem: '#table',
    url: '/api/xxx/list',
    page: {
        layout: ['count', 'prev', 'page', 'next', 'limit'],
        groups: 5,
        limit: 15,
        limits: [15, 30, 50, 100]
    },
    cols: cols,
    skin: false,   // 取消默认行样式，避免表头与数据列错位
    parseData: function(res) {
        return {
            "code": res.code === 0 ? 0 : 1,
            "msg": res.msg || "",
            "count": res.count || 0,
            "data": res.data || []
        };
    }
});
```

#### 5.4.2 表格规范

1. **弹性列**：至少保留一列不设 `width`（通常为文本较长的列），避免表头与数据列错位。
2. **`skin: false`**：统一 `th`/`td` 盒模型，防止对齐偏差。
3. **完整 `page` 配置**：使用完整配置对象，避免 `page: true` 简写。
4. **状态列**：使用 `layui-badge` 展示状态，禁止用 emoji。
5. **操作列**：使用 `layui-btn-xs` 按钮 + 图标，固定右侧。
6. **权限控制**：操作按钮添加 `data-permission` 属性，实现前端权限隐藏。
7. **行内操作无感知更新**：状态开关、设为默认等仅影响当前行的操作，成功后**禁止整表 `reload`**（会导致滚动位置跳到顶部），应使用 `table.updateRow` 单行更新；失败时回滚界面状态。详见《应用视图规范》2.3 节。

#### 5.4.3 行内操作无感知更新（交互反馈）

**原则：** 行内操作（状态开关、设为默认等）应做到无感知更新，只更新当前行，不重新加载整表，保持滚动位置与表格状态不变。这是提升操作流畅度、避免用户视线丢失的关键交互规范。

**状态开关示例：**

```javascript
// 状态开关切换（无感知更新，仅更新当前行状态，不重新加载表格）
form.on('switch(modelStatus)', function(obj) {
    var id = $(this).data('id');
    var newStatus = obj.elem.checked ? 1 : 0;
    var $tr = $(obj.elem).closest('tr');
    $.ajax({
        url: API.update(id),
        type: 'PUT',
        data: { status: newStatus },
        success: function(res) {
            if (res.code === 0) {
                layer.msg(newStatus === 1 ? '已启用' : '已禁用', { icon: 1, time: 1000 });
                // 更新当前行数据并重渲染，保持滚动位置不变
                var rowData = table.cache['xxxTable'].filter(function(item) { return item.id === id; })[0];
                if (rowData) {
                    rowData.status = newStatus;
                    table.updateRow('xxxTable', { index: $tr.data('index'), data: rowData });
                }
            } else {
                layer.msg(res.message || '操作失败', { icon: 2 });
                // 失败回滚开关状态
                obj.elem.checked = !obj.elem.checked;
                form.render('switch');
            }
        },
        error: function() {
            layer.msg('请求失败', { icon: 2 });
            // 失败回滚开关状态
            obj.elem.checked = !obj.elem.checked;
            form.render('switch');
        }
    });
});
```

**关键要点：**
- 用 `table.cache['xxxTable']` 获取当前表格缓存数据，按 `id` 定位当前行，修改字段后通过 `table.updateRow` 重渲染该行。
- `table.updateRow` 的 `index` 取 `$tr.data('index')`，`data` 为更新后的完整行数据。
- 失败/异常时必须**回滚界面状态**（开关取反 + `form.render('switch')`），避免界面与后端不一致。
- 影响多行的操作（设为默认、删除、批量）才使用 `reload`，且优先用本地缓存 `data`（`table.reload('xxxTable', { data: table.cache['xxxTable'] })`）避免跳滚动。

**检查清单（追加到表格规范审查项）：**
- [ ] 行内状态开关成功后使用 `table.updateRow` 单行更新，未整表 `reload`
- [ ] 行内操作失败/异常时已回滚界面状态
- [ ] 仅影响单行的操作未触发整表重新请求
- [ ] 影响多行的操作才使用 `reload`，且优先用本地缓存 `data` 避免跳滚动

### 5.5 弹窗（Layer）

| 场景 | 用法 | 图标 |
|------|------|------|
| 成功提示 | `layer.msg('操作成功', { icon: 1 })` | 内置成功图标 |
| 失败提示 | `layer.msg('操作失败', { icon: 2 })` | 内置失败图标 |
| 确认删除 | `layer.confirm('确认删除？', { icon: 3 })` | 内置警告图标 |
| 加载中 | `layer.load()` | 内置加载动画 |
| iframe 弹窗 | `layer.open({ type: 2 })` | 标题可配图标 |

**规范**：
- 提示信息使用 `layer.msg` 内置图标（`icon: 1/2/3`），**禁止用 emoji**。
- iframe 弹窗必须指定固定高度（如 `area: ['550px', '450px']`）。
- 表单弹窗遵循"固定底部按钮栏 + 内容区滚动"布局（见视图规范 3.2 节）。

### 5.6 徽标与状态（Badge）

```html
<span class="layui-badge layui-bg-green">启用</span>
<span class="layui-badge layui-bg-gray">禁用</span>
<span class="layui-badge layui-bg-orange">待审核</span>
<span class="layui-badge layui-bg-blue">处理中</span>
```

**规范**：
- 状态展示统一使用 `layui-badge` + `layui-bg-*` 语义色。
- **禁止**用 emoji 或彩色文字替代状态徽标。

### 5.7 空状态（Empty）

```html
<div class="layui-empty" style="text-align:center; padding: 40px 0; color: #999;">
    <i class="layui-icon layui-icon-face-smile" style="font-size: 48px;"></i>
    <p style="margin-top: 10px;">暂无数据</p>
</div>
```

**规范**：
- 空状态使用大号图标（48px）+ 提示文字，图标颜色弱化（`#999`）。
- **禁止**用 emoji（如 📭）作为空状态图标。

### 5.8 导航与菜单

```html
<!-- 侧边栏菜单项 -->
<li class="layui-nav-item">
    <a href="javascript:;">
        <i class="fa fa-folder"></i>
        <span>文章管理</span>
    </a>
</li>
```

**规范**：
- 菜单图标统一使用 FontAwesome（`fa fa-xxx`），与菜单文字对齐。
- 菜单图标尺寸 16px，颜色继承菜单文字色。
- **禁止**用 emoji 作为菜单图标。

***

## 六、设计语言统一规范

### 6.1 设计语言定位

CMSPRO 的设计语言定位为：**专业、克制、高效、一致**的企业级管理界面。

- **专业**：界面传达可信赖、严谨的产品气质，避免卡通化、娱乐化元素。
- **克制**：减少装饰性元素，图标、颜色、动效均服务于功能表达。
- **高效**：信息密度适中，操作路径最短，减少用户认知负担。
- **一致**：全局统一的色彩、字体、间距、组件，形成可预期的交互体验。

### 6.2 视觉传达原则

1. **图标即语言**：图标是界面语义的重要组成部分，必须语义准确、风格统一（统一使用 FontAwesome / Layui 线性图标）。
2. **色彩即语义**：颜色用于表达状态与层级，不用于装饰。主色、语义色严格按色板使用。
3. **层级即秩序**：通过字号、字重、间距建立清晰的信息层级，标题 > 正文 > 辅助。
4. **留白即呼吸**：适度留白提升可读性，避免内容拥挤。
5. **动效即反馈**：动效仅用于操作反馈（加载、弹窗、悬停），克制使用，禁止花哨动画。

### 6.3 禁止事项（"AI 味"清单）

以下行为会破坏设计语言统一性，**一律禁止**：

| 禁止项 | 说明 |
|--------|------|
| 使用 emoji 替代图标 | 见第三章 |
| 硬编码主色值 | 必须使用 `var(--global-primary-color)` |
| 引入色板外随机颜色 | 自定义颜色必须取自语义色板 |
| 自定义字体族 | 统一使用系统字体栈 |
| 引入外部字体/CDN | 见第七章 |
| 覆盖 Layui 组件默认尺寸 | 破坏 select 定位等 |
| 无层级的大字号堆砌 | 遵循字号规范 |
| 花哨动画/装饰 | 动效仅用于反馈 |
| 同一功能多图标 | 全局统一图标语义 |
| 魔法数字间距 | 遵循 5px 倍数体系 |

***

## 七、资源本地化要求

### 7.1 核心原则

> **【强制】** 所有 JavaScript 和 CSS 资源必须**完全本地化**，禁止使用任何第三方外部链接（CDN、远程字体、远程脚本），确保系统在无网络环境下正常运行和界面一致。

### 7.2 系统内置资源引用

系统已内置 layui、pear、font-awesome 等 UI 框架，统一存放在 `public/CmsProUi/` 目录下。应用视图中引用这些系统级资源时，**必须使用 `{{ asset() }}` 引用本地路径**：

```html
<!-- 必须引入的公共 CSS -->
<link rel="stylesheet" href="{{ asset('CmsProUi/component/pear/css/pear.css') }}">
<link rel="stylesheet" href="{{ asset('CmsProUi/font-awesome/4.7.0/css/font-awesome.min.css') }}">
<link rel="stylesheet" href="{{ asset('Admin/css/admin.css') }}">
<link rel="stylesheet" href="{{ asset('Admin/css/variables.css') }}">
<link rel="stylesheet" href="{{ asset('Admin/css/reset.css') }}">

<!-- 必须引入的公共 JS -->
<script src="{{ asset('CmsProUi/component/layui/layui.js') }}"></script>
<script src="{{ asset('CmsProUi/component/pear/pear.js') }}"></script>
```

#### 系统内置的代码高亮库 highlight.js（可选）

系统内置了代码高亮库 highlight.js，存放在 `public/CmsProUi/component/highlight.js/`，**不依赖任何应用**，可直接在后台/用户端页面中引用，用于 markdown 代码块等场景的语法高亮：

```html
<!-- 代码高亮主题样式（可选，按需引入 github-dark 或其他风格） -->
<link rel="stylesheet" href="{{ asset('CmsProUi/component/highlight.js/styles/github-dark.min.css') }}">

<!-- 高亮核心 JS -->
<script src="{{ asset('CmsProUi/component/highlight.js/highlight.min.js') }}"></script>
<!-- 按需引入语言包；如需额外语言，在 public/CmsProUi/component/highlight.js/languages/ 下补充 -->
<script src="{{ asset('CmsProUi/component/highlight.js/languages/bash.min.js') }}"></script>
<script src="{{ asset('CmsProUi/component/highlight.js/languages/css.min.js') }}"></script>
<script src="{{ asset('CmsProUi/component/highlight.js/languages/javascript.min.js') }}"></script>
<script src="{{ asset('CmsProUi/component/highlight.js/languages/json.min.js') }}"></script>
<script src="{{ asset('CmsProUi/component/highlight.js/languages/php.min.js') }}"></script>
<script src="{{ asset('CmsProUi/component/highlight.js/languages/sql.min.js') }}"></script>
<script src="{{ asset('CmsProUi/component/highlight.js/languages/xml.min.js') }}"></script>
```

渲染代码块时调用 `hljs.highlightElement(block)` 即可：

```javascript
markdown 渲染后对代码块逐个高亮：
$content.find('pre code').each(function(i, block) {
    try { hljs.highlightElement(block); } catch (e) {}
});
```

> 语言包按需引入（java、python、go、rust 等默认未打包）。若确需新增，请将对应 `*.min.js` 补充到 `public/CmsProUi/component/highlight.js/languages/` 目录（通用库公共资源，不随单个应用交付）。

### 7.3 第三方库本地化

如需使用额外的第三方库（如 echarts、qrcodejs 等，highlight.js 已内置，见上方 7.2）：

1. 下载到应用自身的 `Assets/` 目录中。
2. 通过 `public/apps/{appId}/` 访问（系统自动发布符号链接）。
3. **禁止直接引用 CDN**。

```html
<!-- 正确：引用应用本地资源 -->
<script src="{{ asset('apps/cmspro.blog/js/echarts.min.js') }}"></script>
```

### 7.4 禁止的外部链接示例

```html
<!-- ❌ 禁止：CDN 引用 -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
<script src="https://cdn.bootcdn.net/ajax/libs/layui/2.8.0/layui.js"></script>
<link href="https://fonts.googleapis.com/css2?family=..." rel="stylesheet">

<!-- ✅ 正确：本地引用 -->
<link rel="stylesheet" href="{{ asset('CmsProUi/font-awesome/4.7.0/css/font-awesome.min.css') }}">
<script src="{{ asset('CmsProUi/component/layui/layui.js') }}"></script>
```

### 7.5 本地化检查要点

- [ ] 页面中不存在 `http://` / `https://` 开头的资源引用（`asset()` 生成的除外）。
- [ ] 不存在 `cdn.`、`unpkg.com`、`jsdelivr.net`、`bootcdn`、`googleapis` 等外部域名。
- [ ] 所有 CSS/JS 均通过 `{{ asset() }}` 引用本地路径。
- [ ] 图标字体（FontAwesome、Layui iconfont）随本地 CSS 加载，无远程字体。

***

## 八、实施细则与检查标准

### 8.1 实施步骤

#### 8.1.1 开发阶段

1. **开发前**：阅读本规范及《应用视图规范》，明确图标、色彩、组件使用标准。
2. **开发中**：严格遵循图标库、色板、字号、间距、组件规范编写视图。
3. **开发后**：对照 8.2 节检查清单逐项自检，修正违规项。

#### 8.1.2 代码审查阶段

审查者按 8.2 节清单逐项核对，重点检查：

- 是否存在 emoji 替代图标。
- 图标是否来自官方图标库、语义是否匹配。
- 颜色是否取自色板、是否硬编码主色。
- 资源是否本地化、是否引入外部链接。
- 组件是否遵循 Layui 标准、是否覆盖默认样式。

#### 8.1.3 质量验收阶段

质量团队按 8.3 节视觉效果检查标准进行页面级验收，并截图留档。

### 8.2 代码审查检查清单

#### 图标规范
- [ ] 页面中**不存在**任何 emoji 字符（✅❌🚀📌🔧⭐⚠️➕➖🔍📊💾🔄 等）。
- [ ] 所有图标均使用 `fa fa-xxx` 或 `layui-icon layui-icon-xxx` 类名。
- [ ] 使用 SVG 图标时，已确认官方图标库无对应图标，且遵循 2.6 节 SVG 规范（`viewBox="0 0 24 24"`、`currentColor`、存放于 `Assets/`）。
- [ ] 图标语义与功能匹配（新增=plus/add，删除=trash/delete，编辑=edit，搜索=search）。
- [ ] 同一功能全局使用同一图标。
- [ ] 按钮图标与文字间距合理（约 5px）。
- [ ] 状态指示使用 `layui-badge` + 语义色，未用 emoji。
- [ ] **FA 4.7 版本兼容性**：未使用 `fa-coffee`、`fa-tools` 等 FA 5+ 版本才有的图标（见 2.7 节）。
- [ ] **动态图标渲染**：后端返回的图标类名通过 `<i class="xxx">` 标签渲染，未作为纯文本输出（见 2.8 节）。
- [ ] **图标验证**：首次使用的图标已在浏览器中实际测试渲染效果。

#### 色彩规范
- [ ] 主色通过 `var(--global-primary-color)` 引用，未硬编码 `#16baaa`。
- [ ] 自定义颜色取自语义色板（绿/蓝/红/橙/灰）。
- [ ] 未引入色板外的随机颜色。
- [ ] 状态色语义正确（成功绿、危险红、警告橙）。

#### 字体与间距
- [ ] 未自定义字体族，使用系统字体栈。
- [ ] 字号遵循规范（标题 20/16，正文 14，辅助 12）。
- [ ] 间距遵循 5px 倍数体系，无魔法数字。

#### 组件规范
- [ ] 按钮使用 `layui-btn` 系列类名，尺寸语义正确。
- [ ] 表单使用 `layui-form` 结构，未覆盖 `.layui-form-label` 的 `width` 和 `.layui-input-block` 的 `margin-left`。
- [ ] 表格配置含 `skin: false`、完整 `page` 对象、至少一列弹性列。
- [ ] 弹窗提示使用 `layer.msg` 内置图标（icon: 1/2/3）。
- [ ] 表单弹窗遵循固定底部按钮栏布局（`.bottom` 无 `padding`/`line-height`，含 `.button-container`）。
- [ ] 长表单标签使用 `white-space: nowrap`。

#### 本地化规范
- [ ] 页面中不存在外部 CDN/远程资源引用。
- [ ] 所有 CSS/JS 通过 `{{ asset() }}` 引用本地路径。
- [ ] 第三方库已本地化到 `Assets/` 目录。

#### 视图规范（引用《应用视图规范》）
- [ ] 引入必要的公共 CSS/JS（pear.css、font-awesome、admin.css、variables.css、reset.css、layui.js、pear.js）。
- [ ] 设置 CSRF Token（`$.ajaxSetup`）。
- [ ] Layui 模板语法用 `@verbatim` 包裹。
- [ ] 后台列表页注入权限脚本 `@include('admin.partials.permission-script')`。
- [ ] 操作按钮添加 `data-permission` 属性。

#### 前台 H5 应用规范（第十章）
- [ ] 建立了 Design Token 体系（`:root` CSS 变量），未散落魔法数值。
- [ ] 视图/JS 中不存在内联硬编码色值（`style="color:#xxx"`）。
- [ ] 公共样式已收敛到应用统一 CSS，视图内无重复 `<style>` 块。
- [ ] 响应式断点遵循 360/768/1024 三级，固定定位元素已对齐容器宽度并处理安全区。
- [ ] 列表首屏使用骨架屏，未用纯文字"加载中..."。
- [ ] 操作提交有防重复点击与统一 Loading。

#### 动效规范（第十一章）
- [ ] 动效时长/缓动引用 CSS 变量（`--dur-*` / `--ease-*`）。
- [ ] 无与交互无关的装饰性动画（闪烁、弹跳、庆祝类）。
- [ ] 无 `transition: all`，过渡显式列出实际变化的属性。
- [ ] 动效优先使用 `transform`/`opacity`，未动画 `width`/`height`/`top`/`left`/`margin`。
- [ ] `backdrop-filter` 仅用于必要场景（固定头部/弹窗遮罩），未大面积滥用；移动端固定头部已禁用。
- [ ] 过渡时长 ≤ 0.3s，进场动画 ≤ 0.4s，无长时过渡。
- [ ] `will-change` 仅用于确实需要预合成的元素，未滥用。

#### 可访问性规范（第十二章）
- [ ] 可交互元素使用 `button`/`a`，键盘可聚焦，`:focus-visible` 焦点可见。
- [ ] 导航标注 `aria-label`/`aria-current`，装饰图标 `aria-hidden="true"`。
- [ ] 已实现 `prefers-reduced-motion` 动效降级。
- [ ] 触控目标 ≥ 32×32px，未仅用颜色表达状态。

### 8.3 视觉效果检查标准

质量团队在浏览器中逐页检查：

| 检查项 | 标准 | 通过条件 |
|--------|------|---------|
| 图标一致性 | 图标风格统一、语义准确 | 无 emoji、无混用混乱 |
| 色彩一致性 | 主色、语义色统一 | 无随机颜色、无硬编码主色 |
| 字体一致性 | 字体、字号统一 | 无自定义字体、字号规范 |
| 间距一致性 | 间距节奏统一 | 无魔法数字、无拥挤/空旷 |
| 组件一致性 | 组件样式统一 | 按钮/表单/卡片/表格符合规范 |
| 对齐 | 元素对齐整齐 | 表单标签、表格列对齐 |
| 状态表达 | 状态清晰可辨 | 状态徽标语义正确 |
| 本地化 | 无外部资源 | 断网后页面样式完整 |

### 8.4 违规处理

- **开发阶段**：自检发现违规立即修正。
- **审查阶段**：审查者提出修改意见，开发者修正后复审。
- **验收阶段**：存在 emoji 替代图标、外部资源引用等**严重违规**，视为验收不通过，退回修改。

***

## 九、附录：图标速查表

### 9.1 常用 FontAwesome 图标

| 语义 | 类名 | 语义 | 类名 |
|------|------|------|------|
| 新增/添加 | `fa fa-plus` | 编辑 | `fa fa-edit` |
| 删除 | `fa fa-trash` | 保存 | `fa fa-save` |
| 搜索 | `fa fa-search` | 刷新 | `fa fa-refresh` |
| 返回 | `fa fa-arrow-left` | 前进 | `fa fa-arrow-right` |
| 设置 | `fa fa-cog` | 用户 | `fa fa-user` |
| 首页 | `fa fa-home` | 文件夹 | `fa fa-folder` |
| 文件 | `fa fa-file-text` | 下载 | `fa fa-download` |
| 上传 | `fa fa-upload` | 导出 | `fa fa-download` |
| 打印 | `fa fa-print` | 图表 | `fa fa-bar-chart` |
| 通知 | `fa fa-bell` | 邮件 | `fa fa-envelope` |
| 成功 | `fa fa-check-circle` | 失败 | `fa fa-times-circle` |
| 警告 | `fa fa-exclamation-triangle` | 信息 | `fa fa-info-circle` |
| 锁定 | `fa fa-lock` | 解锁 | `fa fa-unlock` |
| 日历 | `fa fa-calendar` | 时钟 | `fa fa-clock-o` |
| 数据库 | `fa fa-database` | 服务器 | `fa fa-server` |
| 标签 | `fa fa-tag` | 列表 | `fa fa-list` |
| 排序 | `fa fa-sort` | 筛选 | `fa fa-filter` |
| 复制 | `fa fa-copy` | 关闭 | `fa fa-close` |
| 更多 | `fa fa-ellipsis-h` | 眼睛 | `fa fa-eye` |

### 9.2 常用 Layui 图标

| 语义 | 类名 | 语义 | 类名 |
|------|------|------|------|
| 新增 | `layui-icon-add-1` | 编辑 | `layui-icon-edit` |
| 删除 | `layui-icon-delete` | 搜索 | `layui-icon-search` |
| 刷新 | `layui-icon-refresh` | 成功 | `layui-icon-ok` |
| 关闭 | `layui-icon-close` | 返回 | `layui-icon-left` |
| 前进 | `layui-icon-right` | 用户 | `layui-icon-username` |
| 设置 | `layui-icon-set` | 首页 | `layui-icon-home` |
| 文件夹 | `layui-icon-folder` | 文件 | `layui-icon-file` |
| 下载 | `layui-icon-download-circle` | 上传 | `layui-icon-upload` |
| 图表 | `layui-icon-chart` | 通知 | `layui-icon-notice` |
| 邮件 | `layui-icon-email` | 时间 | `layui-icon-time` |
| 日期 | `layui-icon-date` | 加载 | `layui-icon-loading` |
| 更多 | `layui-icon-more` | 眼睛 | `layui-icon-eye` |
| 锁定 | `layui-icon-password` | 帮助 | `layui-icon-help` |
| 警告 | `layui-icon-tips` | 笑脸 | `layui-icon-face-smile` |

### 9.3 图标选择建议

| 业务场景 | 推荐图标 |
|---------|---------|
| 新增/创建 | `fa-plus` / `layui-icon-add-1` |
| 编辑/修改 | `fa-edit` / `layui-icon-edit` |
| 删除/移除 | `fa-trash` / `layui-icon-delete` |
| 查询/搜索 | `fa-search` / `layui-icon-search` |
| 保存/提交 | `fa-save` / `layui-icon-ok` |
| 刷新/重置 | `fa-refresh` / `layui-icon-refresh` |
| 导出/下载 | `fa-download` / `layui-icon-download-circle` |
| 上传/导入 | `fa-upload` / `layui-icon-upload` |
| 设置/配置 | `fa-cog` / `layui-icon-set` |
| 用户/账号 | `fa-user` / `layui-icon-username` |
| 返回/上一页 | `fa-arrow-left` / `layui-icon-left` |
| 关闭/取消 | `fa-close` / `layui-icon-close` |

### 9.4 SVG 图标补充说明

当业务图标在 FontAwesome 与 Layui 图标库中均不存在时，按 2.6 节规范创建 SVG 图标。SVG 图标遵循统一规范：

- 统一 `viewBox="0 0 24 24"` 网格，线性风格（`stroke-width="2"`、`fill="none"`）。
- 颜色使用 `currentColor` 继承文字色，不硬编码固定色。
- 存放于应用 `Assets/icons/` 目录，通过 `public/apps/{appId}/icons/xxx.svg` 访问。
- 命名语义化小写，如 `workflow.svg`、`approval.svg`。

### 9.5 餐饮/订餐相关图标

针对订餐签到、餐饮管理等场景，以下为 FA 4.7 兼容图标推荐：

| 业务场景 | 推荐图标 | 说明 |
|---------|---------|------|
| 早餐 | `fa fa-sun-o` | 太阳（象征早晨） |
| 午餐 | `fa fa-cutlery` | 餐具 |
| 晚餐 | `fa fa-moon-o` | 月亮（象征夜晚） |
| 下午茶 | `fa fa-glass` | 玻璃杯 |
| 签到/确认 | `fa fa-check-circle` | 勾选圆圈 |
| 签到成功 | `fa fa-check` | 勾选 |
| 已签到 | `fa fa-calendar-check-o` | 日历勾选 |
| 未签到 | `fa fa-circle-o` | 空心圆 |
| 签到时间 | `fa fa-clock-o` | 时钟 |
| 餐饮/订餐 | `fa fa-cutlery` | 餐具 |
| 食物/菜品 | `fa fa-circle` | 圆点（占位） |

### 9.6 FA 4.7 常用图标速查

以下为 FA 4.7 版本中**确认可用**的常用图标，开发时优先从此表选择：

| 语义 | 类名 | 语义 | 类名 |
|------|------|------|------|
| 太阳/早晨 | `fa fa-sun-o` | 月亮/夜晚 | `fa fa-moon-o` |
| 餐具 | `fa fa-cutlery` | 玻璃杯 | `fa fa-glass` |
| 咖啡/茶杯（文字图标） | `fa fa-circle` | 勾选 | `fa fa-check` |
| 勾选圆圈 | `fa fa-check-circle` | 勾选方框 | `fa fa-check-square-o` |
| 空心圆 | `fa fa-circle-o` | 时钟 | `fa fa-clock-o` |
| 日历 | `fa fa-calendar` | 日历勾选 | `fa fa-calendar-check-o` |
| 签到/记录 | `fa fa-history` | 历史 | `fa fa-history` |
| 提示/信息 | `fa fa-info-circle` | 警告 | `fa fa-exclamation-triangle` |
| 错误/失败 | `fa fa-times-circle` | 成功 | `fa fa-check-circle` |

**使用提示**：
- 不确定图标是否可用时，先在浏览器中测试
- 餐饮相关图标在 FA 4.7 中较少，复杂场景建议使用 SVG 图标
- 避免使用 AI 生成的 `fa fa-coffee`、`fa fa-tools` 等 FA 5+ 版本图标

***

## 十、前台 H5 应用设计规范

> 适用场景：H5 商城、移动端页面、小程序 H5 页面等**非 Layui 框架**的自建前台应用。后台 Layui 页面仍以第四、五章为准；本清单与第四、五章冲突时，以前台 H5 专项规定为准。

### 10.1 设计 Token 体系（强制）

前台 H5 应用必须建立 **CSS 变量（Design Token）体系**统一管理视觉参数，禁止在页面与样式中散落魔法数值。参考模板：

```css
:root {
    /* 品牌色（渐变双端） */
    --brand-500: #ff5a2c;
    --brand-400: #ff7a3d;
    --brand-50:  #fff3ee;
    --brand-gradient: linear-gradient(135deg, #ff5a2c 0%, #ff8a3c 100%);

    /* 功能色 */
    --green-500: #16b777;  --green-50:  #e8f8f1;
    --blue-500:  #1e9fff;  --blue-50:   #e8f4ff;
    --gold-500:  #ff9500;  --gold-50:   #fff7e8;
    --red-500:   #f5484d;  --red-50:    #feeded;

    /* 中性色（文字层级：1 主标题 > 2 正文 > 3 辅助 > 4 占位） */
    --text-1: #1f2329;  --text-2: #4e5969;
    --text-3: #86909c;  --text-4: #c9cdd4;

    /* 背景与边框 */
    --bg-page: #f5f6f7;  --bg-card: #ffffff;  --bg-hover: #f7f8fa;
    --border: #e5e6eb;   --border-light: #f0f1f3;

    /* 圆角 / 阴影 / 动效 / 布局 */
    --radius-sm: 6px; --radius-md: 10px; --radius-lg: 14px; --radius-full: 999px;
    --shadow-sm: 0 1px 2px rgba(31,35,41,.04), 0 1px 4px rgba(31,35,41,.05);
    --shadow-md: 0 2px 8px rgba(31,35,41,.06), 0 4px 16px rgba(31,35,41,.05);
    --dur-fast: .15s; --dur-base: .25s; --dur-slow: .4s;
    --ease-out: cubic-bezier(.25,.8,.4,1);
    --container: 640px;  /* H5 页面最大容器宽度 */
}
```

**使用原则**：
1. 页面内一律引用 `var(--xxx)`，**禁止**在视图/JS 中硬编码色值（如 `style="color:#ff5a2c"`）。
2. 功能色仅表达对应语义（成功绿/信息蓝/警告橙/危险红），不随意挪用。
3. 阴影分层克制，仅 `sm/md/lg` 三档，禁止随意造阴影。
4. 组件背景用 `--bg-card`（白卡）、页面底色用 `--bg-page`，形成统一层次。

### 10.2 内联样式治理（强制）

1. **禁止在视图文件中散落 `<style>` 块**定义公共样式；所有公共类必须收敛到应用统一 CSS（如 `Assets/css/shop.css`）。
2. **禁止在 HTML/JS 中内联硬编码颜色**（`style="color:#xxx"`）；必须使用语义类或 `var(--xxx)`。
3. 单页私有样式（如仅一个页面使用的少量覆盖）允许保留在 `@push('styles')`，但不得与全局类重复定义。
4. 重构存量代码时，同步删除因迁移产生的冗余 `<style>` 块与死样式。

### 10.3 响应式断点规范

前台 H5 应用统一使用以下断点（移动端优先）：

| 断点 | 范围 | 布局策略 |
|------|------|---------|
| 超小屏 | `< 360px` | 压缩间距与字号（商品网格 gap 8px、价格 16px） |
| 手机基准 | `360px ~ 767px` | 默认双列网格、卡片式布局 |
| 平板 | `≥ 768px` | 商品网格升级 3 列，卡片边距增至 14px |
| 桌面 | `≥ 1024px` | 商品网格升级 4 列，容器居中（`max-width: 640px`） |

**原则**：
- 以 `max-width: 640px` 容器居中呈现 H5 应用，超出部分为留白背景（`#eef0f2` 等浅灰）。
- 固定定位元素（底部导航/操作栏）必须同时设置 `max-width` 与 `margin: 0 auto`，保持与容器对齐。
- 底部导航/操作栏需处理 `env(safe-area-inset-bottom)`，适配 iPhone 底部安全区。

### 10.4 状态加载规范

1. **列表首屏加载**：使用骨架屏（`skeleton`）而非文字"加载中..."，由 JS 动态生成占位卡片，见示例：

```js
// 商品卡片骨架屏生成器（填充到已有 .shop-goods-grid 容器内）
goodsSkeleton: function (count) {
    var html = '';
    for (var i = 0; i < (count || 4); i++) {
        html += '<div class="shop-goods-item">' +
            '<div class="shop-skeleton-line" style="width:100%;aspect-ratio:1;"></div>' +
            '<div class="shop-goods-info">' +
            '<div class="shop-skeleton-line" style="height:14px;width:85%;margin-bottom:8px;"></div>' +
            '<div class="shop-skeleton-line" style="height:14px;width:55%;"></div>' +
            '</div></div>';
    }
    return html;
}
```

```css
.shop-skeleton-line {
    border-radius: 6px;
    background: linear-gradient(90deg, #f7f8fa 25%, #eef0f2 50%, #f7f8fa 75%);
    background-size: 200% 100%;
    animation: shopShimmer 1.4s ease infinite;
}
```

2. **操作提交**：统一 `showLoading/hideLoading` 全屏加载（带旋转指示器），并做**防重复点击**（提交期间 `disabled` 按钮或计数控制）。
3. **Toast 提示**：统一封装（含成功/错误两种类型、自动消失、同文案防抖），禁止散落 `alert()`。
4. **空态**：大图标（48px，弱化颜色）+ 主提示 + 辅助说明三级结构。

***

## 十一、动效与交互反馈规范

> 原则：**动效只用于操作反馈，克制使用**。禁止为了"炫技"添加与交互无关的动画。

### 11.1 动效参数统一

动效时长与缓动通过 CSS 变量统一管理（见 10.1 模板）：

| 参数 | 值 | 用途 |
|------|-----|------|
| `--dur-fast` | 0.15s | 按压反馈、图标切换 |
| `--dur-base` | 0.25s | 弹窗、Tab、过渡 |
| `--dur-slow` | 0.4s | 进场动画、大元素过渡 |
| `--ease-out` | `cubic-bezier(.25,.8,.4,1)` | 默认退出缓动 |
| `--ease-spring` | `cubic-bezier(.34,1.4,.5,1)` | 弹跳感（弹窗/Toast 进场） |

### 11.2 允许的动效场景

| 场景 | 动效 | 时长 |
|------|------|------|
| 按压反馈 | 缩放 `scale(.96-.98)` | `--dur-fast` |
| 弹窗出现 | 遮罩淡入 + 面板底部滑入 | `--dur-base` |
| Tab 切换 | 下划线滑入 + 面板淡入上移 | `--dur-base` |
| 底部导航激活 | 图标轻微上浮放大 | `--dur-base` |
| Toast/Loading | 缩放 + 淡入 | `--dur-base` + spring |
| 商品卡片悬停 | 上浮 2px + 阴影加深 | `--dur-base` |
| 骨架屏 | 微光扫描 | 1.4s 循环 |

### 11.3 禁止的动效

- ❌ 无意义的持续闪烁、弹跳、旋转装饰动画。
- ❌ 页面入场时大面积元素同时动画（造成眩晕）。
- ❌ 与功能无关的"庆祝"类动画（除非营销页经设计评审）。
- ❌ 长列表滚动时的逐项交错动画（影响性能与阅读）。

### 11.4 性能克制要求（强制）

> 动效必须兼顾浏览器性能，避免浪费 GPU/CPU 资源。以下为硬性要求：

1. **禁止 `transition: all`**：`all` 会监听元素所有属性变化，浏览器需持续计算。必须**显式列出实际变化的属性**（如 `transition: color .25s, background .25s`）。
2. **优先合成层属性**：动效优先使用 `transform`、`opacity`（GPU 合成，性能好）；**避免动画 `width`/`height`/`top`/`left`/`margin`**（触发重排，性能差）。
3. **`backdrop-filter` 克制**：`backdrop-filter` 是持续 GPU 高消耗操作。仅用于固定头部、弹窗遮罩等必要场景；**禁止大面积、多元素滥用**；移动端固定头部必须禁用（见 13.7）。
4. **时长克制**：悬停/过渡时长 ≤ 0.3s，进场动画 ≤ 0.4s；禁止长时（>0.5s）过渡。
5. **`will-change` 谨慎**：仅对确实需要预合成的元素（如图片缩放）使用 `will-change: transform`，用完即止，禁止滥用（会占用 GPU 内存）。
6. **减少持续动画**：避免常驻的无限循环动画（骨架屏除外）；滚动监听类动效需节流。

***

## 十二、可访问性（无障碍）规范

### 12.1 交互可访问性

1. **键盘操作**：所有可交互元素必须可通过键盘聚焦与触发（`button`/`a`，禁止用 `div` 模拟按钮而无 `role` 与键盘事件）。
2. **焦点可见**：`focus` 时移除浏览器默认描边但**必须**提供替代可见焦点（`:focus-visible` 描边），禁止裸写 `outline: none`：

```css
:focus { outline: none; }
:focus-visible {
    outline: 2px solid var(--brand-500);
    outline-offset: 2px;
}
```

3. **触控目标**：可点击元素最小触控区域 ≥ 32×32px（推荐 44px 按钮高度），相邻可点元素间距 ≥ 8px。
4. **点击高亮**：移除 iOS 点击灰色遮罩（`-webkit-tap-highlight-color: transparent`），并用 `:active` 缩放/变色提供按压反馈。

### 12.2 语义与标注

1. **导航标注**：底部导航/菜单使用 `aria-label` 标识区域，当前项使用 `aria-current="page"`。
2. **图标标注**：纯装饰性 SVG 添加 `aria-hidden="true"`；承担语义的图标必须有文字标签或 `aria-label`。
3. **表单**：`label` 与输入控件关联（`for`/`id` 或包裹结构）；错误提示与字段关联。
4. **返回按钮**：使用 `aria-label="返回"` 等明确描述。

### 12.3 动效降级

必须支持 `prefers-reduced-motion`（系统"减弱动态效果"偏好），关闭非必要动画：

```css
@media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
        animation-duration: 0.001ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.001ms !important;
        scroll-behavior: auto !important;
    }
}
```

### 12.4 颜色与对比度

1. 正文/主标题与背景对比度 ≥ 4.5:1；辅助文字（次要信息）≥ 3:1。
2. **禁止仅用颜色表达状态**（如"红色=失败"），必须配合图标或文字（如"失败：xxx"）。
3. 品牌色浅底标签（如 `--brand-50` + 深橙文字）保证文字可读。

***

## 附：与其他文档的关系

| 文档 | 关系 |
|------|------|
| 《CmsPro-v5-应用开发文档》 | 应用开发总纲，本规范是其 UI 层面的细化 |
| 《应用视图规范》 | 视图结构、布局、语法规范，本规范补充视觉与图标标准 |
| 《CMSPRO.md 开发规范》 | 通用开发规范，本规范聚焦 UI 视觉一致性 |

> 本规范与《应用视图规范》配合使用：视图规范解决"页面怎么写"，本规范解决"界面长什么样、图标怎么用"。
> v1.1.0 新增：前台 H5 应用设计规范（第十章）、动效与交互反馈规范（第十一章）、可访问性规范（第十二章）。
> v1.2.0 新增：前台 PC 官网（门户）应用设计规范（第十三章），沉淀自 Cmsprohome 官网 UI 美化改造实践。
> v1.3.0 更新：第十三章泛化为通用规范（去除特定应用引用），新增移动端导航与抽屉菜单规范（13.7）、主内容区顶部留白规范（13.6-4），并同步更新检查清单。
> v1.4.0 更新：新增动效性能克制要求（11.4），明确禁止 `transition: all`、克制 `backdrop-filter`、优先合成层属性等，并同步更新检查清单。

***

## 十三、前台 PC 官网（门户）应用设计规范

> 适用场景：PC 端官网、门户站点、产品营销站等**基于自建 CSS 体系**的前台应用。后台 Layui 页面仍以第四、五章为准；本清单与第四、五章冲突时，以前台官网专项规定为准。本章为通用规范，适用于所有官网类应用，不针对特定应用。

### 13.1 设计 Token 体系（强制）

前台官网应用必须建立 `:root` CSS 变量（Design Token）体系统一管理视觉参数，**禁止在页面与样式中散落魔法数值**。参考模板（变量命名与层级为通用标准，色值按各应用品牌替换）：

```css
:root {
    /* 品牌色阶（主色 5 级 + RGB 分量） */
    --primary: #2563eb;
    --primary-dark: #1d4ed8;
    --primary-deep: #1e40af;
    --primary-light: #dbeafe;
    --primary-lighter: #eff6ff;
    --primary-rgb: 37, 99, 235;   /* 供 rgba(var(--primary-rgb), .x) 透明色使用 */

    /* 语义色 */
    --accent: #f97316;            /* 强调/促销 */
    --success: #16a34a;  --success-light: #dcfce7;
    --danger: #dc2626;   --danger-light: #fee2e2;
    --warning: #f59e0b;  --warning-light: #fef3c7;

    /* 中性色（文字层级：text > text-secondary > text-third > text-light） */
    --text: #0f172a;  --text-secondary: #475569;
    --text-third: #64748b;  --text-light: #94a3b8;

    /* 背景与边框 */
    --bg: #ffffff;  --bg-gray: #f8fafc;  --bg-muted: #f1f5f9;  --bg-dark: #0b1220;
    --border: #e2e8f0;  --border-strong: #cbd5e1;

    /* 阴影（3 级 + 品牌投影） */
    --shadow: 0 1px 2px rgba(15,23,42,.04), 0 1px 3px rgba(15,23,42,.06);
    --shadow-md: 0 2px 6px rgba(15,23,42,.06), 0 6px 16px rgba(15,23,42,.08);
    --shadow-lg: 0 8px 20px rgba(15,23,42,.08), 0 20px 40px rgba(15,23,42,.08);
    --shadow-brand: 0 6px 18px rgba(37,99,235,.22);

    /* 圆角（4 级） */
    --radius: 10px;  --radius-lg: 16px;  --radius-xl: 24px;  --radius-full: 999px;

    /* 动效 */
    --ease: cubic-bezier(.25,.46,.45,.94);
    --ease-out: cubic-bezier(.16,1,.3,1);
    --dur: .28s;

    --max-width: 1200px;   /* 内容最大宽度 */
    --header-height: 66px; /* 固定头部高度，供滚动定位计算 */
}
```

**使用原则**：

1. 页面内一律引用 `var(--xxx)`，**禁止**在视图/JS 中硬编码色值（如 `style="color:#2563eb"`、`background:#1890ff`）。
2. 需要透明色时使用 `rgba(var(--primary-rgb), 0.x)`，禁止另造同色系色值。
3. 语义色仅表达对应语义（成功绿/危险红/警告橙/强调橙），不随意挪用。
4. 阴影、圆角、动效均从变量体系取值，禁止自定义魔法值。
5. 新页面/新应用的 Token 必须与既有体系命名一致，不得自造平行体系。

### 13.2 内联样式治理（强制）

1. **禁止在视图文件中散落 `<style>` 块**定义公共样式；公共类收敛到应用统一 CSS（如 `Assets/css/{app}.css`）。
2. **禁止在 HTML/JS 中内联硬编码颜色与尺寸**（`style="color:#xxx"`、`style="font-size:52px"`）；必须使用语义类或 `var(--xxx)`。
3. 单页私有覆盖允许保留在 `@push('page_styles')`，但不得与全局类重复定义。
4. 重构存量代码时，同步清理因迁移产生的冗余 `<style>` 块与死样式，并将内联样式迁移到 CSS 类。

### 13.3 图标使用规范（官网专项）

1. **emoji 一律禁止**作为状态/功能图标（见第三章）。查询结果的状态、锁、警告、关闭等必须使用内联 SVG 线条图标。
2. SVG 图标规范（官网内联场景）：`viewBox="0 0 24 24"`、`fill="none"`、`stroke="currentColor"`、`stroke-width="2"`、`stroke-linecap/linejoin="round"`。
3. 状态图标通过 CSS 控制尺寸（`width/height`），跟随语义色（`color`）自动变色：
   - 状态标题图标：`22px`，随 `h4` 状态色（成功绿/危险红）。
   - 徽章/内联小图标：`14px`。
   - 空态/警示大图标：`50px`，灰色（`var(--text-light)`），`display:block; margin: 0 auto` 居中。
4. 按钮、导航等已有图标库（FontAwesome/Layui）场景，仍按第二章优先使用图标库。

### 13.4 卡片与区块体系

| 组件 | 规范 |
|------|------|
| 卡片 | 白底 + `1px solid var(--border)` + `border-radius: var(--radius-lg)`；悬浮态 `--shadow-lg` + `translateY(-4~-6px)` + 边框品牌色 |
| 图标容器 | 品牌浅色渐变底（`linear-gradient(135deg, var(--primary-lighter), var(--primary-light))`），圆形用 `--radius-full`，方形用 `--radius` |
| 区块标题 | 居中：`34px / 800 字重 / 负字距`；带"查看全部"的左侧场景：左对齐 + `flex` 布局两端对齐 |
| 副标题 | `16px / var(--text-third)`，与标题间距 ≥ 48px |
| 统计卡片 | 数字 `38px / 800 / 主色`，配白卡 + 边框，悬浮微浮起 |
| 列表项/表格网格 | 间距统一 20~24px，hover 背景用 `var(--primary-lighter)` |

### 13.5 按钮与弹窗规范

1. **主按钮**：渐变底（`linear-gradient(135deg, var(--primary), var(--primary-dark))`）+ `--shadow-brand` 投影 + hover `translateY(-1px)` + 投影加深；禁用态置灰。
2. **次级按钮**：`btn-outline`，白底 + `var(--border-strong)` 边框，hover 变品牌色边框 + 浅底。
3. **弹窗**：遮罩 `rgba(15,23,42,.55)` + `backdrop-filter: blur(4px)`；面板 `--radius-lg` + 大投影 + 进场动画（淡入 + 上移 + 缩放，`--dur` + `--ease-out`）。
4. **弹窗输入框**：统一 `var(--border-strong)` 边框 + focus 时品牌色边框 + `0 0 0 3px rgba(var(--primary-rgb),.15)` 光环。
5. **结果/反馈容器**：可关闭的结果面板需提供右上角圆形关闭按钮（`button` 元素 + `aria-label`），关闭后内容清空、状态类移除。

### 13.6 固定头部与滚动定位

1. 固定头部高度统一 `var(--header-height)`，页面主体 `padding-top: var(--header-height)` 避免遮挡。
2. **锚点/结果滚动定位禁止裸用 `scrollIntoView({ block: 'start' })`**（会被固定头部遮挡），必须手动计算偏移：

```js
var headerOffset = 66 + 24; // 固定头部高度 + 顶部留白（可微调）
var top = el.getBoundingClientRect().top + window.pageYOffset - headerOffset;
window.scrollTo({ top: top, behavior: 'smooth' });
```

3. 滚动定位数值（头部高度、留白）统一定义，避免魔法数字散落；同一页面多处滚动逻辑的偏移口径保持一致。
4. **主内容区顶部留白**：`.home-main` 等主容器默认**不设** `padding-top`（PC 端 hero/banner 自带顶部留白，避免导航下方出现白色空隙）；仅在移动端断点（≤768px）添加 `padding-top: var(--header-height)`，防止内容被固定头部遮挡。

### 13.7 移动端导航与抽屉菜单（强制）

> 官网 PC 应用在移动端需切换为抽屉式导航。本节沉淀了移动端菜单定位的常见陷阱与标准做法。

1. **`backdrop-filter` 会创建包含块**：固定头部若使用 `backdrop-filter`，其子元素的 `position: fixed` 会相对头部而非视口定位，导致展开的抽屉菜单高度异常/不可见。**移动端必须禁用头部的 `backdrop-filter`**（`backdrop-filter: none`），并可将头部背景改为近不透明（`rgba(255,255,255,.98)`）。
2. **抽屉菜单置于 body 直接子级**：将移动端抽屉 `<nav>` 放在 `<header>` 之外、body 直接子级，确保其 `position: fixed` 完全相对视口，不受头部包含块与层叠上下文影响。
3. **双导航方案**：桌面端与移动端各用一套导航，互不干扰：
   - 桌面导航：位于 `<header>` 内，`display: flex` 居中显示。
   - 移动抽屉：body 直接子级，默认 `display: none`，展开时 `display: flex` + `position: fixed; top: var(--header-height); bottom: 0; overflow-y: auto`。
   - 移动端断点隐藏桌面导航（`display: none`），显示汉堡按钮。
4. **层级控制**：头部保持 `z-index: 1000`（勿设 `auto`，否则被页面内容覆盖）；抽屉菜单 `z-index: 1001`；遮罩层 `z-index: 999`。三者层级：菜单 > 头部 > 遮罩。
5. **交互**：汉堡按钮切换 `mobile-open` 类；点击遮罩关闭；菜单项点击后关闭；支持 ESC 关闭。

### 13.8 特殊组件：授权证书（沉淀样例）

官网"域名授权查询"等正式凭证场景，建议采用证书式呈现：

- **证书容器**：浅色纸感背景 + 双线内框（`::before`/`::after` 定位描边）+ 品牌色水印（低透明度居中 SVG）。
- **结构层次**：认证徽章（胶囊渐变）→ 证书标题（大字号 + 大字距）→ 证书编号（等宽字母数字，避免中文/URL 编码）→ 授权域名（大字号强调）→ 证明语 → 信息网格（`3` 列卡片）→ 有效性状态 → 页脚（签发机构 + 时间）→ 印章（圆形倾斜描边）。
- **编号生成**：`{前缀}-{域名字母数字}-{授权时间数字}`，禁止拼接中文或未经处理的原生字符串（会产生 URL 编码乱码）。
- **状态表达**：成功用绿色对勾（SVG）+ "授权有效"；失败用灰色警示图标 + 虚线边框警示框，**禁止 emoji**。
- **响应式**：信息网格 `≥3` 列在 ≤480px 降为 `1` 列，印章缩小，页脚纵向堆叠。

### 13.9 响应式断点（官网 PC 应用）

| 断点 | 布局策略 |
|------|---------|
| `≤ 1024px` | 卡片网格 2 列、页脚 2 列、移动导航抽屉启用 |
| `≤ 768px` | 卡片网格 1 列、汉堡菜单 + 抽屉导航、固定头部降为 50px |
| `≤ 480px` | 紧凑间距（section 36px）、触控目标 ≥ 44px、弹窗变底部抽屉式 |

**原则**：

- 触控目标（按钮/链接）最小 44×44px，输入框字号 ≥ 16px 防 iOS 缩放。
- 固定定位元素（返回顶部等）处理安全区（`env(safe-area-inset-bottom)`）。
- 支持 `prefers-reduced-motion` 动效降级（见 12.3 节）。

### 13.10 官网应用检查清单

- [ ] 建立了 Design Token 体系（`:root` 变量），视图/JS 中无内联硬编码色值与魔法数值。
- [ ] 公共样式收敛到应用统一 CSS，视图内无重复 `<style>` 块。
- [ ] 无 emoji 状态/功能图标，SVG 图标遵循 `24×24` + `currentColor` 规范。
- [ ] 主按钮渐变 + 品牌投影，次级按钮描边式，弹窗遮罩模糊 + 进场动画。
- [ ] 固定头部场景的滚动定位已计算头部偏移，未裸用 `scrollIntoView`。
- [ ] 主内容区 PC 端无多余 `padding-top`，移动端才添加头部留白。
- [ ] 移动端抽屉菜单置于 body 直接子级，头部已禁用 `backdrop-filter`，层级（菜单>头部>遮罩）正确。
- [ ] 可关闭结果面板提供右上角关闭按钮（`button` + `aria-label`）。
- [ ] 响应式断点遵循 1024/768/480 三级，触控目标与字号符合规范。
- [ ] 已实现 `prefers-reduced-motion` 降级与 `:focus-visible` 焦点可见。
