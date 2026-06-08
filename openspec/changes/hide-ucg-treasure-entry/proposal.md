# Proposal: 临时隐藏 UCG 宝藏入口

## Why

宝藏功能尚未就绪，首版上架需避免用户进入「敬请期待」占位页；下版计划恢复宝藏 Tab 与真实内容。

## What

通过编译期开关 `kUcgTreasureEnabled = false` 临时隐藏：

- UCG 底部导航「宝藏」Tab
- 资料页（我的 Tab 与他人主页）「宝藏」Tab

占位组件与双 Tab 结构保留，下版将 `kUcgTreasureEnabled` 改回 `true` 即可恢复入口。

## Scope

- `ucg-shell-navigation`：底栏在 flag 为 false 时为四栏（广场、发布、消息、我的）
- `ucg-profile`：flag 为 false 时仅展示动态列表，无 TabBar
- 不含宝藏业务 API 或真实内容实现
