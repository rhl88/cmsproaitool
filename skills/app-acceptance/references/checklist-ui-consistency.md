# 维度二：界面一致性检查清单

> 依据：`rules/CMSPRO-UI开发规范.md`（下称"UI 规范"）、`rules/应用视图规范.md`（下称"视图规范"）
> 检查对象：`code/app/Apps/{AppName}/Views/` 下全部 `.blade.php`（下称"视图文件"）
> 判定级别：**[严重]** 一票否决 / **[强制]** 必须整改 / **[建议]** 优化项

---

## 2.1 页面完整结构

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| U1 | 列表页/表单页为完整 HTML：`<!DOCTYPE html>`、`<html>`、`<head>`（charset/viewport/title/公共CSS）、`<body>`；禁止输出裸露模板片段 | [强制] | 逐个读视图文件核对（视图规范2.1/2.2） |
| U2 | 后台/用户端视图禁止 `@extends('layouts.admin')` / `@extends('layouts.user')`（iframe 独立入口会导致布局嵌套），须为独立完整 HTML | [严重] | Grep 视图目录：`@extends\(` 应无 layouts.admin/layouts.user 命中（开发文档19.6·第二十章第17条） |
| U3 | 列表页包含 `pear-container` 容器 + 两类卡片：搜索条件卡、表格卡（`layui-card` + `layui-card-body`） | [强制] | 读列表页核对（视图规范2.1·UI 规范4.4） |
| U4 | 视图文件扩展名 `.blade.php`，目录结构 `Admin|User|Home/功能模块/视图文件.blade.php`；`index/form/detail/_片段` 命名规范，功能子目录全小写 | [强制] | LS Views 目录核对（视图规范1.2） |

## 2.2 表单页（iframe 弹窗）布局

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| U5 | 固定底部按钮栏 + 内容区自适应滚动布局：`html,body{height:100%;margin:0;overflow:hidden}`；含 `box-sizing:border-box` 声明；`.layui-form{height:100%}` | [强制] | 读 form.blade.php 的 `<style>` 块核对（视图规范3.2，标注"必须遵循"） |
| U6 | 内容区 `.layui-form > .layui-row { height: calc(100vh - 52px); overflow-y: auto; padding: 15px; }`；减数与按钮栏高度一致 | [强制] | 核对 calc 值与 `.bottom` 高度匹配（视图规范3.2） |
| U7 | `.bottom { height: 52px; }` 不加 padding、不加 line-height；内部按钮用 `.button-container` 包装；`.layui-row` 与 `.bottom` 为 `.layui-form` 同级直接子元素 | [强制] | 读样式核对（视图规范3.2 明确禁止项） |
| U8 | 禁止用 `position: fixed` / `sticky` 固定按钮栏 | [强制] | Grep 视图文件：`position:\s*(fixed\|sticky)` 结合上下文判断（视图规范3.2） |
| U9 | 表单标签不换行：`.layui-form-label { white-space: nowrap; }` 已声明 | [强制] | Grep：`white-space:\s*nowrap`（视图规范3.3） |
| U10 | 禁止覆盖 Layui 表单默认尺寸：`.layui-form-label` 的 width（含 `width: unset`）、`.layui-input-block` 的 margin-left | [强制] | Grep：`\.layui-form-label[^}]*width` 与 `\.layui-input-block[^}]*margin-left`（视图规范3.3·7.3） |
| U11 | 视图配置值带默认值：`{{ $configs['key'] ?? '默认值' }}`，避免首次安装无记录显示空白 | [强制] | Grep：`\$configs\[[^\]]+\]\]?\s*\}\}` 排查无 `??` 的用法（开发文档12A.4） |

## 2.3 Layui 模板与 Blade 语法

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| U12 | `<script type="text/html">` 内的 Layui 模板（`{{# }}`、`{{ d.field }}`）必须用 `@verbatim`/`@endverbatim` 包裹；只包裹模板内容，不包裹整个 script 标签 | [严重] | 逐个读含 `<script type="text/html">` 的视图核对配对（视图规范5.1/5.2） |
| U13 | `@verbatim` 块内不得出现 Blade 语法（`{{ csrf_token() }}`、`{{ $var }}`、`{{ asset() }}` 等），否则原样输出不解析 | [严重] | [人工] 读 @verbatim 块内容排查；页面若显示未替换的 `{{ }}` 即范围过大（视图规范5.2·7.1） |
| U14 | Blade 注释（`{{-- --}}`）中禁止出现 `@verbatim`、`@endverbatim`、`@section`、`@yield`、`@extends` 等指令关键字（会导致整个 script 块被静默移除） | [严重] | Grep：`\{\{--.*@(verbatim\|endverbatim\|section\|yield\|extends)`（开发文档第二十章第18条） |
| U15 | 普通 `<script>` 中 Layui 的 `{{ }}` 使用 `@{{ }}` 转义 | [强制] | [人工] 读页面级 JS 排查（CMSPRO 项目约束） |
| U16 | 使用 `@json` 时空默认值用 `[]` 而非 `{}`（避免 Blade 编译歧义） | [强制] | Grep：`@json\([^)]*\?\? ['"]\{` （CMSPRO 项目约束） |

## 2.4 公共资源引用

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| U17 | 引入公共 CSS：pear.css、font-awesome(4.7.0)、admin.css、variables.css、reset.css | [强制] | Grep 视图文件核对引用清单（视图规范6.1） |
| U18 | 引入公共 JS：layui.js、pear.js | [强制] | Grep 核对（视图规范6.2） |
| U19 | 所有 CSS/JS 通过 `{{ asset() }}` 引用本地路径 | [严重] | Grep：`(src\|href)=["'](?!\{\{ asset)` 结合人工判断（UI 规范7.2） |
| U20 | 禁止任何外部资源引用：CDN 域名（cdn.、unpkg.com、jsdelivr.net、bootcdn、googleapis）、远程字体、http(s) 开头资源（asset() 生成除外） | [严重] | Grep 视图目录：`https?://[^"']*\.(css\|js\|woff\|svg)\|cdn\.\|unpkg\.com\|jsdelivr\|bootcdn\|googleapis`（UI 规范7.1/7.4/7.5·8.4 验收不通过项） |
| U21 | 第三方库（echarts、qrcodejs 等）已下载到应用 `Assets/`，通过 `public/apps/{appId}/` 访问 | [强制] | LS Assets 目录 + Grep 引用路径核对（UI 规范7.3） |
| U22 | Assets/ 仅存放应用自带静态资源，不含运行时生成文件（上传文件应放 storage/ 等独立目录，避免升级清除） | [强制] | LS Assets 目录核对（开发文档第六章·第二十章第20条） |

## 2.5 色彩规范

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| U23 | 主色通过 `var(--global-primary-color)` 引用，禁止硬编码主色值 `#16baaa`；圆角统一 `var(--global-border-radius)` | [强制] | Grep 视图目录：`#16baaa`（忽略大小写）应无命中（UI 规范4.1.1·6.3） |
| U24 | 自定义颜色仅从语义色板选取（信息蓝 #1e9fff、成功绿 #16b777、危险红 #ff5722、警告橙 #ffb800、中性灰 #5f5f5f、边框灰 #e6e6e6、背景灰 whitesmoke），禁止色板外随机色 | [强制] | Grep：`#[0-9a-fA-F]{3,6}` 收集全部硬编码色值，逐一比对色板（UI 规范4.1.2） |
| U25 | 语义色不挪用（如红色表示"正常"）；状态色优先 Layui 内置类 `layui-badge layui-bg-green/gray/orange/blue` | [强制] | [人工] 读状态列模板核对（UI 规范4.1.2/4.1.3） |
| U26 | 前台 H5/官网类应用建立 `:root` Design Token 体系，页面引用 `var(--xxx)`，禁止散落魔法数值与内联硬编码色值（`style="color:#xxx"`） | [强制] | Grep：`style="[^"]*#` 排查内联色值（UI 规范10.1/10.2/13.1/13.2，仅前台应用适用） |

## 2.6 字体与字号

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| U27 | 使用系统字体栈（Layui 默认），禁止自定义字体族、禁止引入外部字体（Google Fonts 等） | [强制] | Grep：`font-family` 与 `@font-face`、`fonts\.` 核对（UI 规范4.2.1） |
| U28 | 字号层级规范：页面标题 20px / 区块标题 16px / 正文 14px / 辅助 12px；正文统一 14px，禁止随意放大缩小 | [建议] | Grep：`font-size` 收集值核对层级（UI 规范4.2.2） |

## 2.7 图标规范

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| U29 | 界面图标仅使用 FontAwesome（`fa fa-xxx`）或 Layui（`layui-icon layui-icon-xxx`），禁止 emoji、Unicode 符号、自绘图片 | [严重] | Grep 视图目录常见功能 emoji：按钮/菜单/状态/提示/空状态等场景逐一排查（UI 规范2.1/第三章·8.4 验收不通过项） |
| U30 | 官方图标库已有对应图标时禁止创建 SVG；确需 SVG 时：`viewBox="0 0 24 24"`、`stroke-width="2"`、`fill="none"`、`currentColor` 继承色、存放 `Assets/icons/`、禁止外部 SVG 链接（iconfont 在线地址） | [强制] | Glob `Assets/icons/*.svg` 抽查 + Grep 外链（UI 规范2.6） |
| U31 | 同一功能全局使用同一图标，禁止同一功能不同页面不同图标；按钮推荐"图标+文字"组合 | [建议] | [人工] 跨页面对比新增/编辑/删除等操作图标（UI 规范2.5·2.3.3） |
| U32 | 菜单图标统一 FontAwesome，16px，颜色继承菜单文字色 | [强制] | 读 manifest menus 的 icon 字段核对（UI 规范5.8） |

## 2.8 组件配置规范

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| U33 | 表格配置 `skin: false`（统一 th/td 盒模型防错位） | [强制] | Grep：`skin:\s*false`（视图规范5.4·UI 规范5.4.2） |
| U34 | 分页为完整 page 配置对象（layout/groups/limit/limits），禁止 `page: true` 简写 | [强制] | Grep：`page:\s*true` 应无命中；核对完整对象（UI 规范5.4.2） |
| U35 | cols 至少一列不设 width（弹性列）；弹性列不得放在 `fixed: 'right'` 列上 | [强制] | 读 table.render 的 cols 定义核对（视图规范5.4） |
| U36 | 表格配置 `parseData` 明确数据解析，字段映射与后端响应结构一致 | [强制] | 读 parseData 与 API 响应比对（视图规范5.4·CMSPRO 约束） |
| U37 | 状态列统一 `layui-badge` + `layui-bg-*` 语义色，禁止 emoji 或彩色文字 | [强制] | 读状态列模板核对（UI 规范5.6） |
| U38 | 表单结构规范：`layui-form` + `lay-filter` + `layui-form-item` + `layui-form-label` + `layui-input-block`；必填 `lay-verify="required"`；占位符"请输入/请选择+字段名" | [强制] | 读 form.blade.php 核对（UI 规范5.2） |
| U39 | 下拉框按规范处理：JS 动态填充 option 的 select 加 `lay-ignore` 用原生渲染；静态 option 可走 Layui 美化 | [强制] | [人工] 读动态填充下拉框场景（CMSPRO 项目约束） |
| U40 | 弹窗配置规范：`shade: [0.5, '#000']`、`shadeClose: 0`、`closeBtn: 1`；禁止 `cancel: function(){ return false; }`（拦截关闭与 ESC） | [强制] | Grep：`layer.open` 上下文核对三项配置（CMSPRO 项目约束） |
| U41 | iframe 表单弹窗指定固定尺寸（如 `area: ['550px','450px']`） | [强制] | Grep：`area:\s*\[` 核对（UI 规范5.5·视图规范3.2） |
| U42 | 空状态使用 48px 大图标 + 提示文字（图标色 #999 弱化），禁止 emoji | [建议] | [人工] 页面访问核对（UI 规范5.7） |
| U43 | 同一操作区按钮尺寸一致；主操作居右/首位；危险操作红色 `layui-btn-danger` | [建议] | 页面访问核对（UI 规范5.1） |
| U44 | 间距遵循 5px 倍数体系（5/10/15/20）：页面内边距 15px、卡片间距 15px、元素内间距 10px；禁止魔法数字间距 | [建议] | Grep：`padding|margin` 收集非 5 倍数值核对（UI 规范4.3） |
| U45 | 内容以 `layui-card` 组织，使用 Layui 栅格（`layui-row`/`layui-col-md*`）响应式布局 | [强制] | 读页面结构核对（UI 规范4.4） |

## 2.9 日期时间显示

| # | 检查项 | 级别 | 检查方法 |
|---|--------|------|----------|
| U46 | 界面日期显示 `Y-m-d H:i:s` 格式，禁止 ISO 8601（`2026-05-23T00:16:39.000000Z`）、英文可读格式 | [严重] | 页面访问 + Grep 前端 `format\(` 核对日期格式化（CMSPRO 规则第1章） |
| U47 | 后端模型已配置 `$casts`（`datetime:Y-m-d H:i:s`）或重写 `serializeDate()`；前端/Controller 不做二次 format | [强制] | 读 Models 核对（CMSPRO 规则第1章） |
