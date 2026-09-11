# 维度三：交互体验评估清单

> 依据：`rules/CMSPRO-UI开发规范.md`（下称"UI 规范"）、`rules/应用视图规范.md`（下称"视图规范"）、`rules/CmsPro-v5-应用开发文档.md`（下称"开发文档"）
> 检查对象：应用视图中的 AJAX/弹窗/表格/表单交互逻辑
> 判定级别：**[严重]** 一票否决 / **[强制]** 必须整改 / **[建议]** 优化项

---

## 3.1 AJAX 基础配置

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| I1 | 每个含 AJAX 的页面均设置 `$.ajaxSetup` 注入 CSRF Token：`headers: { 'X-CSRF-TOKEN': '{{ csrf_token() }}' }`（缺失导致 POST 返回 419/500） | [严重] | Grep 视图目录：`ajaxSetup`，核对每个含 `$.ajax`/`$.post`/`$.get` 的页面均配置（视图规范6.3·7.4） |
| I2 | `$.ajaxSetup` 配置 `statusCode: { 401: ... }`：提示"登录已过期"并跳转登录页（含 redirect 参数回跳） | [强制] | Grep：`statusCode` 核对 401 分支与跳转逻辑（视图规范6.3·CMSPRO 约束） |
| I3 | XMLHttpRequest 手写调用单独添加 401 状态判断（不经过 $.ajaxSetup 的场景） | [强制] | Grep：`new XMLHttpRequest\|xhr\.onreadystatechange` 核对 status===401 处理（CMSPRO 约束） |
| I4 | AJAX error 回调解析 `xhr.responseText` 中的 `message` 字段展示，禁止硬编码"请求失败" | [强制] | Grep：`error:\s*function` 逐个核对实现（开发文档19.6） |
| I5 | error 回调优先判断 401 状态并提前返回，避免与 statusCode 处理重复弹窗 | [强制] | [人工] 读 error 回调逻辑（CMSPRO 约束） |
| I6 | 前端 AJAX 请求包含后端验证要求的全部字段（如修改密码接口的 confirm_password） | [强制] | 比对前端提交字段与后端验证规则（CMSPRO 约束） |

## 3.2 提示与反馈

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| I7 | 成功/失败提示统一 `layer.msg('...', { icon: 1/2 })`，确认 `layer.confirm('...', { icon: 3 })`，禁止 emoji、禁止散落 `alert()` | [强制] | Grep：`alert\(` 应无命中；核对 layer.msg 带 icon 参数（UI 规范5.5·10.4） |
| I8 | 危险操作（删除、禁用、批量操作）必须二次确认 `layer.confirm` | [强制] | 读删除类操作的 JS 事件核对（UI 规范5.1.4） |
| I9 | 异步操作使用 `layer.load()` 或 `layui-icon-loading` 加载指示；提交期间防重复点击（disabled 或计数控制） | [强制] | 读提交类函数核对 loading 与防重（UI 规范5.5·10.4） |
| I10 | 前台 H5 列表首屏使用骨架屏（skeleton），禁止纯文字"加载中..."；Toast 统一封装（成功/错误两类、自动消失、同文案防抖） | [强制] | 页面访问核对（UI 规范10.4，仅前台 H5 适用） |

## 3.3 表格交互

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| I11 | 行内状态开关成功后用 `table.updateRow` 单行更新（index 取 `$tr.data('index')`），禁止整表 `reload`（滚动位置跳顶） | [强制] | Grep：`updateRow` 核对开关场景实现（视图规范2.3.1，标注"必须遵循"） |
| I12 | 开关模板带 `data-id` 定位行；开关带 `lay-filter` 与 `lay-skin="switch"` | [强制] | 读状态列模板核对（视图规范2.3.1） |
| I13 | 行内操作失败/异常时回滚界面状态（开关取反 + `form.render('switch')`），保证界面与后端一致 | [强制] | 读开关切换 error 分支核对（视图规范2.3.1） |
| I14 | 仅影响多行的操作（设为默认/删除/批量）才 `reload`，且优先本地缓存：`table.reload('xxxTable', { data: table.cache['xxxTable'] })` | [强制] | 读多行操作场景核对（视图规范2.3.2） |
| I15 | Layui 表单事件监听使用精确 lay-filter 值（不支持通配符 `*`）；同类下拉框统一相同 lay-filter | [强制] | Grep：`form\.on\(` 核对 filter 值与视图定义匹配（CMSPRO 约束） |

## 3.4 iframe 弹窗体系

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| I16 | 表单页提交成功后：`parent.layer.getFrameIndex(window.name)` 获取并关闭父层弹窗，随后 `parent.table.reload('xxxTable')` 刷新父页表格 | [强制] | 读 form 页提交回调核对（视图规范3.1） |
| I17 | 列表页 `reloadTable()` 直接 `table.reload('xxxTable')`，禁止 `parent.` 前缀（列表页 parent 是后台主框架，无表格实例会报 not found） | [严重] | 读列表页 reloadTable 函数核对（视图规范4.2 强制） |
| I18 | 列表页 `layer.open`（新增/编辑）带 `end: function () { reloadTable(); }` 回调，保证关闭后列表刷新 | [强制] | Grep：`layer\.open` 核对 end 回调（视图规范4.2） |
| I19 | iframe 内再弹 iframe 选择器：使用 `parent.layer.open` / `parent.layer.full` 提升到父页面层级，配置 `maxmin: true`，通过 sessionStorage 回传数据 | [强制] | 读嵌套弹窗场景核对（视图规范4.1） |
| I20 | 所有 iframe 弹窗内调用 Layui 表格 reload 使用 `parent.layui.table.reload(...)` 并加存在性判断兜底（parent.table 可能是局部变量） | [强制] | Grep：`parent\.(layui\.)?table\.reload` 核对兜底判断（CMSPRO 约束） |
| I21 | 使用 `parent.layui.table` 前判断 `parent.layui && parent.layui.table` 存在性，避免 iframe 层级不符时报 undefined | [强制] | 同上核对（CMSPRO 约束） |

## 3.5 权限交互

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| I22 | 后台列表页在 `</head>` 之前注入 `@include('admin.partials.permission-script')`，且位置在 `</style>` 之后（放 style 内会被当作 CSS 文本不执行）；iframe 子页面不继承父页 window 变量，须各自注入 | [强制] | Grep：`permission-script` 核对位置（视图规范6.4·9.1） |
| I23 | 工具栏操作按钮添加 `data-permission` 属性（只加在 `<button>` 上，不加在 `<a>` dropdown 触发器上），并实现 hidePermButtons 隐藏逻辑 | [强制] | 读工具栏按钮核对（视图规范9.2） |
| I24 | dropdown 菜单项添加 `permission` 属性并用 `.filter()` 过滤 | [强制] | 读 dropdown 模板核对（视图规范9.3） |
| I25 | 行内操作按钮在 `table.render` 的 `done` 回调中隐藏无权限项 | [强制] | 读 done 回调核对（视图规范9.4） |
| I26 | 动态生成的按钮、switch 开关等添加 `hasPermission` 操作拦截 | [强制] | 读动态渲染逻辑核对（视图规范9.5） |
| I27 | 权限码已在 `admin_permissions` 表注册（manifest permissions 声明与前端 data-permission 值一致） | [强制] | 查库比对权限码清单（视图规范9.7） |
| I28 | 前端权限控制不替代后端校验：后端仍有 `can:xxx` 中间件兜底 | [严重] | 与 F50 交叉核对（开发文档第十五章） |

## 3.6 动效规范

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| I29 | 动效仅用于操作反馈、克制使用；禁止炫技装饰动画、持续闪烁/弹跳/旋转、入场大面积同时动画、长列表逐项交错动画、"庆祝"类动画 | [建议] | 页面访问观察（UI 规范11/11.3） |
| I30 | 禁止 `transition: all`，必须显式列出变化属性（如 `transition: color .25s, background .25s`） | [强制] | Grep 视图与 CSS：`transition:\s*all` 应无命中（UI 规范11.4） |
| I31 | 动效优先 `transform`/`opacity`（GPU 合成），禁止动画 `width`/`height`/`top`/`left`/`margin`（触发重排）；悬停/过渡 ≤0.3s、进场 ≤0.4s，禁止 >0.5s 长过渡 | [强制] | Grep：`@keyframes` 与 `transition` 核对属性与时长（UI 规范11.4） |
| I32 | 动效时长/缓动引用 CSS 变量（`--dur-fast`/`--dur-base`/`--dur-slow`/`--ease-out`/`--ease-spring`） | [建议] | Grep：`--dur-\|--ease-` 使用情况（UI 规范11.1） |
| I33 | `backdrop-filter` 仅用于固定头部/弹窗遮罩等必要场景，禁止大面积滥用；`will-change` 谨慎使用、用完即止 | [强制] | Grep：`backdrop-filter\|will-change` 核对场景（UI 规范11.4） |
| I34 | 滚动监听类动效做节流处理 | [建议] | [人工] 读滚动监听代码（UI 规范11.4） |

## 3.7 表单交互细节

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| I35 | 表单提交按钮带 `lay-submit lay-filter="save"`，submit 事件拦截后 AJAX 提交 | [强制] | 读 form 页提交按钮核对（视图规范3.1） |
| I36 | 输入框 `autocomplete="off"`（敏感信息输入场景） | [建议] | Grep：`autocomplete` 核对（视图规范5.2 属性项） |
| I37 | 设置页开关字段（lay-skin="switch"）在 switchFields 数组显式列出并用 `:checked` 转 `'1'/'0'`，保存时正确序列化 | [强制] | 读设置页 JS 核对（开发文档12A.5） |
| I38 | 设置保存后执行 `Artisan::call('route:clear')` 与 `config:clear`（涉及路由相关配置时） | [强制] | 读 SettingController::update 核对（开发文档12A.5） |
| I39 | 表单页作为 iframe 弹窗时高度自适应弹窗（配合 U5-U7 布局），无内部滚动条错位、按钮栏遮挡 | [建议] | 页面访问实测（视图规范3.2） |
