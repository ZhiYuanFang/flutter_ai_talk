## Why

当前 `sendCommand()` 文本对话接口采用同步 HTTP 调用，用户发送文本后需等待完整回复才能看到内容，缺少思考过程的实时反馈，交互体验与 AI 对话的直觉预期不一致。兄弟仓 `go_ai_talk` 已实现 `POST /device/history/api/chat/stream` SSE 流式接口，可逐帧推送 thinking / answer 事件，Flutter 端尚未接入。

## What Changes

- **BREAKING**: `FeedRepository.sendCommand()` 返回类型由 `Future<String?>` 改为 `Stream<String>`，调用方需改为流式订阅
- `RemoteFeedRepository.sendCommand()` 改为建立 SSE 连接到 `/device/history/api/chat/stream`，按事件顺序产出 thinking / answer 增量文本
- `HomeScreen` 新增 `_chatThinking` 状态，`_voiceStripText` getter 优先展示 thinking（answer 首帧到达后切换展示 answer）
- 同步接口 `/device/history/api/chat` 继续保留（`fetchWidgetFeedingTip` 仍使用），不受影响

## Capabilities

### New Capabilities

- `chat-streaming`: Flutter 端文本对话 SSE 流式接收能力，含 sendCommand 流式改造、UI thinking/answer 状态切换

### Modified Capabilities

- （无）

## Impact

- **代码文件**：`app/lib/data/feed_repository.dart`（接口签名）、`app/lib/data/remote_feed_repository.dart`（SSE 实现）、`app/lib/ui/home_screen.dart`（状态与 UI）
- **API 契约**：新增对 `POST /device/history/api/chat/stream`（SSE）的依赖；兄弟仓已就绪
- **依赖**：复用 `http` 包的 `Client.send()`（与 `tip_repository.dart` 模式一致），无需新增依赖
- **兼容性**：`sendCommand` 签名变更是破坏性改动，调用方仅 `home_screen.dart` 两处（语音发送、文字发送），影响范围可控
