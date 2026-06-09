## Why

全局键盘顶部浮层当前存在高度异常、emoji 切换导致 binding 误解除、布局与场景不匹配等问题；且 UCG/喂养各输入场景对产品形态差异大（聊天微信式 dock、发布仅 emoji、评论完整浮层发送、登录无 emoji 等），无法用单一浮层形态覆盖。需要将 `KeyboardInputBridgeController` 重构为可组合配置，统一 accessory 样式与「顶组件」滚动策略，并修复已知交互缺陷。

## What Changes

- 引入 `KeyboardOverlayConfig`（`showEmoji` / `showMultimedia` / `showInputField` / `showConfirmButton` + `confirmLabel`）；四 bool 均为 false 时不渲染全局浮层。
- **BREAKING**：废弃「emoji 切换仅能在全局浮层 accessory」的单一规则；`ucg.chat` 改为页面 dock 内 emoji + 面板（无全局浮层）。
- 全局浮层 accessory 行统一布局：左 emoji/多媒体 → 中输入框（可选）→ **最右侧场景化文案按钮**（如评论/`home.text` 为「发送」，资料/登录为「确定」）。
- `showInputField == true` 时页面命中输入框只读，主编辑在浮层 TextField；否则页面 Field 可编辑。
- 引入「顶组件」：键盘/浮层弹出时以聚焦锚点组件底边对齐键盘+浮层顶缘，而非盲目 `resizeToAvoidBottomInset` 顶整页。
- 统一 `KeyboardOverlayMetrics`（44px accessory、输入 36–72px、emoji 面板高度 ≈ `lastKeyboardInset`）；修复 Android/iOS 一致的高度与圆角贴合问题。
- 修复 emoji 模式 `TextInput.hide` 导致 focus 丢失误 `detach` 的问题。
- `showMultimedia` 时在浮层 accessory 上方展示可删缩略图条（本迭代仅预留能力，首个接入 scene 后续迭代；聊天多媒体走顶部预制区，不走浮层）。
- **聊天特例**：四 bool 全 false；dock 行内 emoji；面板在 dock 正下方高度 ≈ 键盘；多媒体选后在聊天顶部预制，点 dock「发送」才发出。
- 登录/注册/改密/绑定/宝宝资料等 auth 类 scene：**浮层无 emoji**。
- `home.text`（Web 文字指令）：完整浮层编辑 + emoji，右侧文案 **「发送」**。

## Capabilities

### New Capabilities

（无新增独立 capability；行为归入下列 MODIFIED delta。）

### Modified Capabilities

- `keyboard-top-input-confirm-bar`：可组合浮层配置、accessory 布局、metrics、顶组件、多媒体缩略条占位、场景化 `confirmLabel`、emoji 会话生命周期。
- `managed-keyboard-textfield`：`KeyboardOverlayConfig` 透传、页面只读/可编辑规则、锚点注册。
- `ucg-emoji-input`：emoji 入口位置按 config 分流（全局浮层 vs 聊天 dock）；喂养非 auth scene 支持 emoji。
- `ucg-chat-ui`：无全局浮层、dock 内 emoji 面板、顶部多媒体预制、发送语义。
- `ucg-compose-post`：仅 emoji 浮层、页面正文可编辑、无浮层确定/输入。
- `ucg-profile`：完整浮层编辑（含 emoji）、页面只读展示。
- `ucg-post-comment`：评论 Sheet 完整浮层编辑、右侧「发送」、页面只读。

## Impact

- **Flutter 核心**：`keyboard_input_bridge.dart`、`managed_keyboard_text_field.dart`、`keyboard_dismiss_scope.dart`。
- **UCG**：`ucg_chat_screen.dart`、`ucg_visual_widgets.dart`（`UcgInputDock`）、`ucg_compose_screen.dart`、`ucg_post_detail_screen.dart`、`ucg_mention_composer_field.dart`、`ucg_profile_shell.dart`。
- **喂养**：`home_screen.dart`（`home.text` Web）、`home_history_edit_sheet.dart`、`home_number_event_sheet.dart`、`login_screen.dart`、`register_screen.dart`、`change_password_screen.dart`、`baby_bind_screen.dart`、`baby_profile_editor.dart`。
- **OpenSpec**：MODIFIED delta 覆盖上述 capability；与已归档 `ucg-keyboard-input-enhancements` 部分条款冲突处以本变更为准。
- **不在范围**：新增自动化测试文件、后端 API、自定义贴纸包；浮层 `showMultimedia` 的首个非聊天接入 scene（除架构预留外）。
