## Why

UCG 社交与喂养主页存在一组已复现的体验与可靠性问题：发布/编辑动态加图后预览闪烁、聊天表情面板交互不符合预期、发送消息出现重复气泡、相册选择全屏刷新、AI 对话额度遮挡语音球，以及 UCG 聊天 WebSocket 仅在进入广场后才建连、缺少与喂养历史 WS 同等的心跳与退避机制。这些问题影响核心社交与 AI 对话路径的可用性与观感，且后端已稳定回传 `clientMsgId` 与 ping/pong 协议，适合一次性合并修复。

## What Changes

- 抽取共享 `ResilientWebSocketClient`，将喂养历史 WS 的登录建连、token 刷新、JSON ping/pong、指数退避 + gaveUp、App 生命周期 resume 重连机制复用到 UCG 聊天 WS；登录且 wxId 已绑定后 UCG WS 须保持长连接（不依赖是否停留在 UCG Shell）。
- 聊天消息去重：统一 `clientMsgId` 生成与解析，处理 `message_ack` / `message_delivered` upsert，消除乐观消息与服务端回显重复展示；处理 `audit_failed`。
- 聊天表情：未唤起键盘时点击表情须展示 dock 下方面板；表情模式下点击输入区外部须收起面板。
- 发布/编辑 compose：后台上传完成时避免整页闪烁（本地预览优先、单格刷新）。
- 相册选择：选中/取消选中时仅局部刷新对应格子，不得全网格重建导致闪屏。
- 喂养主页：AI 对话剩余额度移至语音球下方，玻璃拟态样式且不得遮挡语音球。
- 喂养主页「进入广场」拉条左上角增加 UCG 未读高亮（会话 + 互动消息 OR 逻辑，复用 `ucgUnreadCountProvider`）。
- **不在范围内**：拍摄界面文案（已为中文，无需改动）。

## Capabilities

### New Capabilities

- `resilient-websocket-client`：共享 WebSocket 传输层（鉴权握手、心跳、退避、gaveUp、生命周期、token 刷新钩子），供喂养历史与 UCG 聊天复用。
- `home-ai-quota-hint`：喂养主页语音模式下 AI 对话月度剩余额度展示（语音球下方、玻璃拟态、不遮挡交互）。

### Modified Capabilities

- `ucg-chat-ui`：登录后 UCG WS 长连、`clientMsgId` 关联与去重、`message_ack`/`audit_failed` 处理。
- `ucg-emoji-input`：聊天场景无键盘点表情出面板、表情模式外部点击收起面板。
- `ucg-compose-post`：编辑/发布加图后上传完成不得明显闪烁。
- `ucg-album-picker`：选择资产时局部刷新缩略图网格。
- `ucg-home-entry`：喂养页「进入广场」拉条展示 UCG 未读角标。

## Impact

- **Flutter**：`app/lib/data/remote_feed_repository.dart`、`app/lib/ucg/data/ucg_repository.dart`、新增 `app/lib/network/` WS 客户端；`ucg_chat_screen.dart`、`keyboard_input_bridge.dart`、`ucg_compose_screen.dart`、`ucg_compose_media_grid` / preview、`ucg_album_picker_screen.dart`、`home_screen.dart`、`ai_quota_remaining_hint.dart`、`ucg_enter_square_tab.dart`、`ucg_providers.dart`、`repositories.dart`。
- **后端**：无协议变更；依赖 `go_ai_talk` 既有 `clientMsgId`、`message_ack`、`message_delivered`、`ping`/`pong` 语义。
- **基线**：引用 `v2.0.2` 中 `history-ws-reconnect`、`ucg-chat-ui`、`ucg-emoji-input`、`ucg-compose-post`、`ucg-album-picker`、`ucg-home-entry` 等能力并做 delta 扩展。
