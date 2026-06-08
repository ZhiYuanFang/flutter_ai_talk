## Why

UCG 模块当前沿用 `add-ucg-module` 约定的「可爱玻璃拟态」风格（悬浮磨砂 dock、渐变卡片、胶囊互动条），与产品近期偏好的小红书式简约信息流不一致；同时 UCG 内所有文本输入尚未接入全 App 已有的 `keyboard-top-input-confirm-bar` 能力，导致键盘弹出时页面被顶起、输入体验与喂养模块不统一。需要在一次变更中完成 UCG 视觉体系 pivot 与键盘输入桥接全量接入，并为后续 UCG 功能建立可复用的简约组件与受管控输入规范。

## What Changes

- **BREAKING（UCG 视觉）**：UCG 内联 UI 不再使用玻璃拟态容器（`BackdropFilter` 磨砂 pill、渐变描边阴影卡片）；改为简约风——连续 `shellColor` 沉浸式布局、轻表面卡片、轻量选中态（颜色+字重，无底色 pill）。
- 底部五栏导航改为全宽扁平嵌入 `shellColor`；中间「发布」与两侧 tab 同构，无渐变圆按钮。
- 广场 Feed 卡片使用轻表面（`UcgSurfaceCard`：单色浅底、无 blur/阴影），保留双列瀑布流交互不变。
- 帖子详情页保留首图/封面背景 `BackdropFilter` 氛围模糊（内容层仍无圆角玻璃卡包裹）。
- **不纳入**：喂养页 `UcgEnterSquareTab` 侧栏拉条视觉改造。
- 新增 `ManagedKeyboardTextField`（或等效封装），统一 `attach` / `detach` / `updateDraft` 样板；UCG 全部受管控输入接入 `keyboardInputBridgeController`。
- `UcgScaffold` 及 UCG 内相关页面默认 `resizeToAvoidBottomInset: false`，键盘输入由顶部确认条承接。
- UCG 评论 Sheet 去掉 `respectKeyboardInset: true` 顶起行为，改走键盘桥接；Sheet 视觉随简约风改为 flat sheet（非玻璃）。
- `UcgShellGlassCard` 体系迁移为 `UcgSurfaceCard`；`UcgGlassBottomDock` / `UcgGlassInputDock` 重命名并扁平实现。
- 喂养模块玻璃拟态与 `keyboard-top-input-confirm-bar` 全局 overlay **保持不变**；仅 UCG 风格分叉，主题 token 仍共享。

## Capabilities

### New Capabilities

- `managed-keyboard-textfield`：可复用的受管控文本输入封装，对接 `keyboardInputBridgeController`，供 UCG 及后续模块默认使用。

### Modified Capabilities

- `ucg-visual-system`：从「喂养同款玻璃拟态」改为「UCG 简约风」；明确轻表面、轻量选中、内联 UI 禁止 blur 玻璃；详情氛围 blur 例外；UCG 输入须接入键盘确认条。
- `ucg-shell-navigation`：底栏从 glass dock 改为 flat embedded bar；发布入口扁平同构。
- `ucg-square-feed`：Feed 卡片容器从玻璃卡改为轻表面卡（supersede `ucg-square-detail-notifications-redesign` 中 Masonry 玻璃卡条款）。
- `ucg-chat-ui`：聊天输入 dock 简约化 + 键盘桥接。
- `ucg-compose-post`：发布页分区简约化 + 正文输入键盘桥接。
- `ucg-profile`：资料编辑输入键盘桥接。
- `keyboard-top-input-confirm-bar`：扩展适用范围说明——UCG 模块所有受管控输入必须接入；新增 UCG 场景 Scenario。

## Impact

- **Flutter**：`app/lib/ucg/**`（`ucg_visual_widgets.dart`、`ucg_shell.dart`、`ucg_square_tab.dart`、`ucg_masonry_feed_card.dart`、`ucg_messages_tab.dart`、`ucg_compose_screen.dart`、`ucg_chat_screen.dart`、`ucg_post_detail_screen.dart`、`ucg_profile_screens.dart`）；新增 `app/lib/ui/widgets/managed_keyboard_text_field.dart`（或同级路径）。
- **OpenSpec**：`add-ucg-module` 中 `ucg-visual-system` / `ucg-shell-navigation` 部分条款被本变更 supersede；与 `ucg-square-detail-notifications-redesign` Feed 玻璃卡任务实现冲突时以本变更为准。
- **不在范围**：`UcgEnterSquareTab`、喂养模块 UI、`HistoryEditGlassPanel` 全局玻璃 Sheet（喂养仍用）；后端 API 无变更。
