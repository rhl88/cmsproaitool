# 维度五：兼容性验证清单

> 依据：`rules/CmsPro-v5-应用开发文档.md`（下称"开发文档"）、`rules/CMSPRO-UI开发规范.md`（下称"UI 规范"）
> 检查对象：数据库跨驱动兼容、Linux 部署兼容、浏览器/响应式/移动端、可访问性
> 判定级别：**[严重]** 一票否决 / **[强制]** 必须整改 / **[建议]** 优化项

---

## 5.1 数据库跨驱动（MySQL 生产 / SQLite 测试）

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| C1 | 建表用 `Schema::create()`，禁止裸写 `CREATE TABLE` SQL | [严重] | Grep Migrations：`CREATE TABLE`（不区分大小写）应无命中（开发文档第七章） |
| C2 | 加列/删列/改列用 `Schema::table()` + `$table->type()`/`dropColumn()`/`change()`，禁止 `ALTER TABLE ... ADD/DROP/MODIFY COLUMN` 裸 SQL | [严重] | Grep Migrations：`ALTER TABLE`（例外：仅表 COMMENT 语句允许，核对上下文） |
| C3 | 新增字段前 `Schema::hasColumn()` 判断；改字段可空性禁止 `Blueprint::change()` 模式，用原生 SQL + information_schema 精确判断（防迁移已应用误判） | [强制] | 读修改字段的迁移文件核对（开发文档第七章·CMSPRO 约束） |
| C4 | `after('column')` 仅 MySQL 生效，使用时确认 SQLite 下字段顺序不敏感 | [建议] | Grep：`->after\(` 核对使用场景（开发文档第七章） |
| C5 | 迁移在 SQLite 内存数据库下通过：`php artisan test` 全量绿即覆盖（测试环境即 SQLite :memory:） | [严重] | 运行 `php artisan test`（开发文档第七章·测试环境注意事项） |
| C6 | 模型名等关键字无数据库保留字冲突（order、group 等），有冲突时表名/字段名已规避 | [建议] | 读迁移表名/字段名核对常见保留字 |

## 5.2 Linux 部署兼容（大小写敏感）

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| C7 | 目录名、命名空间、代码引用三者大小写完全一致（Windows 测试通过 ≠ Linux 能运行）——与 F2/F3 交叉核对 | [严重] | `php -r "echo app_id_to_class_name('{app_id}');"` + Grep 全部 `App\\Apps\\` 引用核对（开发文档·应用命名规范规则4） |
| C8 | 迁移文件定位使用 `__DIR__`，无 Windows 专属路径分隔符拼接（`\` 硬拼接） | [强制] | Grep Migrations/Install.php：`__DIR__\s*\.` 核对拼接方式（开发文档第十二章） |
| C9 | 无依赖 Windows 专属函数/扩展（`win32`、反斜杠路径硬编码、COM 等） | [强制] | Grep：`win32\|COM\(\)\|C:\\\\` 排查 |

## 5.3 响应式布局

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| C10 | 后台页面使用 Layui 栅格（layui-row/layui-col-md*）响应式，窄窗口无布局破碎 | [强制] | 浏览器缩放窗口实测（UI 规范4.4，与 U45 交叉核对） |
| C11 | 前台 H5 应用断点策略：<360px 压缩间距、360~767px 双列卡片、≥768px 三列、≥1024px 四列且容器 `max-width: 640px` 居中 | [强制] | 读样式媒体查询 + 浏览器设备模拟实测（UI 规范10.3，仅前台 H5 适用） |
| C12 | 前台 PC 官网断点策略：≤1024px 网格 2 列 + 移动导航抽屉、≤768px 单列 + 汉堡菜单 + 头部 50px、≤480px 紧凑间距 | [强制] | 同上（UI 规范13.9，仅前台官网适用） |
| C13 | 固定定位元素（底部导航/操作栏）同时设 `max-width` 与 `margin: 0 auto`，并处理 `env(safe-area-inset-bottom)` iPhone 安全区 | [强制] | 读固定定位元素样式核对（UI 规范10.3·13.9，仅前台适用） |
| C14 | 移动端双导航方案：桌面导航在 header 内；移动抽屉为 body 直接子级（fixed 相对视口）；层级菜单(1001) > 头部(1000) > 遮罩(999)，头部 z-index 勿设 auto；支持 ESC/遮罩点击关闭 | [强制] | 读前台布局 DOM 结构与 z-index 核对（UI 规范13.7，仅前台适用） |
| C15 | 移动端头部禁用 `backdrop-filter`（`backdrop-filter: none`），背景改近不透明——与 P17 交叉核对 | [强制] | 读移动端断点样式核对（UI 规范13.7） |
| C16 | 触控目标 ≥ 44×44px（移动端）、相邻可点元素间距 ≥ 8px；输入框字号 ≥ 16px 防 iOS 聚焦缩放 | [强制] | [人工] 读触控类元素样式/设备实测（UI 规范12.1·13.9） |
| C17 | 禁止裸用 `scrollIntoView({ block: 'start' })`（被固定头部遮挡），必须手动计算头部高度偏移 | [强制] | Grep：`scrollIntoView` 核对（UI 规范13.6，仅前台适用） |
| C18 | 固定头部高度统一 `var(--header-height)`，页面主体 `padding-top` 避免遮挡；仅移动端断点加 padding-top | [建议] | 读前台布局样式核对（UI 规范13.6） |

## 5.4 可访问性

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| C19 | 可交互元素用 `button`/`a`，禁止 div 模拟按钮而无 role 与键盘事件；键盘可聚焦可触发 | [强制] | [人工] 读交互元素标签（UI 规范12.1） |
| C20 | `:focus` 提供替代可见焦点（`:focus-visible` 描边），禁止裸写 `outline: none` | [强制] | Grep：`outline:\s*none` 结合上下文核对是否有 :focus-visible 替代（UI 规范12.1） |
| C21 | 导航/底部菜单 `aria-label` 标识区域，当前项 `aria-current="page"`；返回按钮 `aria-label="返回"` | [强制] | 读导航/菜单 DOM 核对（UI 规范12.2） |
| C22 | 装饰性 SVG 加 `aria-hidden="true"`；语义图标有文字标签或 `aria-label`；`label` 与输入控件关联（for/id 或包裹） | [强制] | 读图标/表单 DOM 核对（UI 规范12.2） |
| C23 | 正文/主标题与背景对比度 ≥ 4.5:1，辅助文字 ≥ 3:1；状态表达不仅靠颜色（配合图标/文字） | [强制] | [人工] 取色核对关键文字（UI 规范12.4） |
| C24 | 支持 `prefers-reduced-motion` 减弱动态效果偏好，关闭非必要动画 | [强制] | Grep：`prefers-reduced-motion` 核对媒体查询（UI 规范12.3） |
| C25 | 移除 iOS 点击灰色遮罩（`-webkit-tap-highlight-color: transparent`），用 `:active` 提供按压反馈 | [建议] | Grep：`tap-highlight` 核对（UI 规范12.1） |

## 5.5 浏览器与运行环境

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| C26 | 页面在 Chromium 内核（运维环境常用）与 Firefox 下渲染正常：表格对齐、弹窗、开关、下拉无错位 | [建议] | 浏览器访问核心页面实测 |
| C27 | 无网络环境可用：断外网后页面加载与功能正常（资源全本地化的实际验证）——与 P12 交叉核对 | [严重] | 开发者工具 Network 屏蔽外域后刷新页面（UI 规范7.1） |
| C28 | API 兼容性：对外 API 路径小写下划线、HTTP 方法语义正确（GET 查询/POST 创建/PUT 更新/DELETE 删除） | [建议] | 读路由定义核对（CMSPRO 规范·接口设计） |
| C29 | API 版本化与向后兼容：废弃接口提前通知，升级不破坏既有客户端调用（SSE/OpenAI 兼容等场景按各自标准核对） | [建议] | [人工] 读对外 API 文档与路由比对（CMSPRO 规范·版本管理） |
