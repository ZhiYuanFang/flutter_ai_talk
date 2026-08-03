## Context

当前 Flutter 端 `sendCommand()` 通过同步 HTTP 调用 `POST /device/history/api/chat`，一次性等待完整回复。兄弟仓 `go_ai_talk` 已实现 `POST /device/history/api/chat/stream` SSE 流式接口，协议如下：

```
POST /device/history/api/chat/stream
Body: { deviceNo, transcript }
Response: text/event-stream

SSE 帧：
  event: thinking
  data: <思考过程增量文本>
  (空行)

  event: answer
  data: <回答内容增量文本>
  (空行)

  data: [DONE]
  (空行)
```

仓库内已有 SSE 实现参考：`tip_repository.dart`（小贴士流式生成），使用 `http.Client.send()` + `http.Request` 建立流式连接。

约束：
- 不得使用裸 `debugPrint` / `print`，日志须走 `AppDebugLog` / `ApiHttpLog`
- 不得引入新依赖（`http` 包已在 `pubspec` 中）
- 同步接口 `/device/history/api/chat` 继续保留，`fetchWidgetFeedingTip` 不受影响

## Goals / Non-Goals

**Goals:**
- `sendCommand()` 由同步 `Future<String?>` 改为 `Stream<String>`，按事件顺序产出 thinking / answer 增量
- HomeScreen 新增 `_chatThinking` 状态，消息条优先展示 thinking，answer 首帧到达后切换
- 保持 WS ready 前置检查、AI 额度错误处理与现有行为一致
- Flutter 编译通过（debug + release 均无报错）

**Non-Goals:**
- 不改动同步接口 `POST /device/history/api/chat` 的任何行为
- 不改动 `fetchWidgetFeedingTip()`（继续使用同步接口）
- 不引入新的状态管理框架（继续使用本地 State + setState）
- 不实现 SSE 自动重连（单次请求失败即结束，由用户重新触发）

## Decisions

### 1. SSE 连接方式：复用 `http.Client.send()`（与 tip_repository 一致）

**决策**：不使用现有 `ApiClient`（其内部使用 `http.post` 一次性读取响应体，不支持流式），直接使用 `http.Client` 的 `send()` 方法获取 `http.StreamedResponse`，逐行解析 SSE 帧。

**理由**：
- `tip_repository.dart` 已验证此模式可行，代码可复用度高
- `ApiClient` 的 `{code, message, data}` 信封解析与 SSE 文本流不兼容
- 无需引入 `eventsource` 或类似第三方包

**备选**：
- 使用 `eventsource` 包 → 引入新依赖，不必要
- 改造 `ApiClient` 增加流式方法 → 改动面大，单一功能不值得

### 2. SSE 解析策略：标准 `event:` + `data:` 双行帧

**决策**：逐行扫描流式响应，按以下规则解析：
- 遇到 `event: <type>` → 记录当前事件类型（thinking / answer）
- 遇到 `data: <content>` → 若当前事件类型非空，则 yield 内容（与事件类型一起）
- 遇到 `data: [DONE]` → 关闭流
- 空行 → 帧分隔符，无需处理
- 解析失败的行 → 静默跳过（不中断流）

**理由**：
- 与兄弟仓 `writeSSEEvent()` 的输出格式完全匹配
- 支持多行 data（SSE 规范允许）
- 兼容未来可能的新事件类型（未知事件类型的数据被忽略，不破坏流）

### 3. 事件产出格式：Stream<String> 纯文本增量

**决策**：`sendCommand()` 返回 `Stream<String>`，直接产出文本增量，不包装事件类型。调用方通过先后顺序区分：先到的是 thinking，answer 首帧到达后后续均为 answer。

**理由**：
- UI 层只需知道「当前展示什么」，用先后顺序即可区分
- 简化接口，避免引入额外数据类
- answer 一旦开始即不再展示 thinking，状态切换由 UI 层在收到首帧 answer 时完成

**备选**：
- `Stream<ChatSSEEvent>` 含 type + content → 更明确但过度设计，UI 层不需要事件类型的精确区分

### 4. UI 状态管理：本地 State + setState（与现有模式一致）

**决策**：在 `_HomeScreenState` 中新增 `String? _chatThinking` 和 `StreamSubscription<String>? _chatStreamSub`，使用 `setState` 触发重建。

**理由**：
- 与现有 `_chatReply` / `_partial` 等状态管理模式完全一致
- 不需要引入 Riverpod provider（聊天流是单次交互的临时状态，不跨组件共享）
- `_voiceStripText` getter 可直接读取本地状态

### 5. 并发发送防护：新请求前 cancel 上一个订阅

**决策**：每次调用 `sendCommand()` 前，先 `_chatStreamSub?.cancel()` 并置空，确保同一时间只有一个活跃的 SSE 流。

**理由**：
- 用户快速连续发送时，旧流的结果不应再更新 UI
- 避免多个流同时写入 `_chatThinking` / `_chatReply` 导致状态混乱

## Risks / Trade-offs

| 风险 | 说明 | 应对 |
|------|------|------|
| **SSE 帧跨 chunk** | 一个 SSE 帧可能被拆分为多个 TCP chunk 到达，逐行解析需处理不完整行 | 使用行缓冲，遇到换行符才处理完整行 |
| **HTTP 非 200** | 服务端返回 4xx/5xx（如额度不足、未登录） | 检查 `response.statusCode`，非 200 时关闭 client 并抛出异常，由调用方处理（与现有 `ApiBusinessException` 路径一致） |
| **WS ready 检查** | 流式调用仍需 WS ready（与同步一致） | 保留 `isHistoryWebSocketReady` 前置检查，不满足时返回空流或 null |
| **内存泄漏** | StreamSubscription 未 cancel 导致内存泄漏 | dispose() 中 `_chatStreamSub?.cancel()`；新请求前 cancel 上一个 |
| **断流无 answer** | 网络中断导致只收到部分 thinking 无 answer | UI 层保留已收到的 thinking/answer 文本，不自动清空（用户可看到部分内容） |
