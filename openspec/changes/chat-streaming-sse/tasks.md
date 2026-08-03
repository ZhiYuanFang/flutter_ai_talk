## 1. 接口层改造

- [x] 1.1 修改 `feed_repository.dart` 中 `sendCommand()` 签名：由 `Future<String?> sendCommand(String text)` 改为 `Stream<ChatStreamEvent> sendCommand(String text)`

## 2. 数据层实现（RemoteFeedRepository SSE 流式）

- [x] 2.1 在 `remote_feed_repository.dart` 中实现 `sendCommand()` 流式逻辑：使用 `http.Client.send()` + `http.Request` 建立 SSE 连接到 `/device/history/api/chat/stream`
- [x] 2.2 实现 SSE 帧解析：按行扫描，支持 `event:` 头 + `data:` 内容，正确处理 `thinking` / `answer` 事件与 `data: [DONE]` 结束标记
- [x] 2.3 保留前置条件检查：deviceNo 非空、WS ready、文本非空，不满足时返回空 Stream
- [x] 2.4 保留 AI 额度/登录错误处理：`ApiBusinessException` 中 AI 额度相关 code 继续 rethrow 交由 UI 层处理
- [x] 2.5 正确关闭 `http.Client`：流结束、出错或取消时均关闭连接，避免资源泄漏

## 3. UI 层改造（HomeScreen 状态与订阅）

- [x] 3.1 在 `home_screen.dart` 中新增状态：`String? _chatThinking`、`StreamSubscription<ChatStreamEvent>? _chatStreamSub`
- [x] 3.2 修改 `_voiceStripText` getter：优先级调整为 `thinking > answer > partial > "聆听中…"`
- [x] 3.3 修改 `_onVoiceEnd()`：由 `await sendCommand()` 改为订阅 Stream，收到 thinking 累积到 `_chatThinking`，收到 answer 累积到 `_chatReply` 并清空 `_chatThinking`
- [x] 3.4 修改 `_onTextSubmit()`：同上改为流式订阅模式
- [x] 3.5 新增并发发送防护：每次发送前 `_chatStreamSub?.cancel()` 并清空 `_chatThinking` / `_chatReply`
- [x] 3.6 修改 `dispose()`：`_chatStreamSub?.cancel()`

## 4. 验证

- [x] 4.1 执行 `flutter analyze` 无错误（与本次改动相关的错误已全部修复）
- [x] 4.2 执行 `flutter build apk --debug` 编译通过 ✓
- [ ] 4.3 验证：语音球发送文本后能实时看到 thinking 过程并最终切换到 answer
