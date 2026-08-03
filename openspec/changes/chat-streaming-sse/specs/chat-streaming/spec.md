## ADDED Requirements

### Requirement: sendCommand uses SSE streaming
Flutter 端 `sendCommand()` SHALL 建立 SSE 连接到 `POST /device/history/api/chat/stream`，并以 `Stream<String>` 形式按事件顺序产出 thinking / answer 增量文本。

#### Scenario: sendCommand returns streaming text
- **WHEN** Flutter 调用 `sendCommand(text)`
- **THEN** 方法 SHALL 立即返回 `Stream<String>`
- **AND** 订阅后 SHALL 向 `/device/history/api/chat/stream` 发起 POST 请求（body 含 `deviceNo`、`transcript`）
- **AND** 请求头 SHALL 包含 `Accept: text/event-stream`、`Content-Type: application/json`、`Authorization: Bearer <token>`

#### Scenario: SSE thinking events yield text
- **WHEN** SSE 流收到 `event: thinking` 帧
- **THEN** SHALL 将该帧的 `data:` 内容作为字符串 yield 到 Stream

#### Scenario: SSE answer events yield text
- **WHEN** SSE 流收到 `event: answer` 帧
- **THEN** SHALL 将该帧的 `data:` 内容作为字符串 yield 到 Stream

#### Scenario: SSE [DONE] terminates stream
- **WHEN** SSE 流收到 `data: [DONE]`
- **THEN** SHALL 正常关闭 Stream（done）
- **AND** SHALL 关闭 `http.Client` 连接

#### Scenario: HTTP non-200 throws
- **WHEN** SSE 请求返回 HTTP 状态码非 200
- **THEN** SHALL 关闭 `http.Client`
- **AND** SHALL 以异常结束 Stream

### Requirement: sendCommand preserves preconditions
`sendCommand()` SHALL 保留同步版本的全部前置条件检查（deviceNo 非空、WS ready、文本非空）。

#### Scenario: deviceNo missing returns empty stream
- **WHEN** `deviceNo` 为 null 或空字符串
- **THEN** SHALL 返回空 Stream（立即 done）
- **AND** SHALL Toast 提示「请先绑定宝宝信息」

#### Scenario: WS not ready returns empty stream
- **WHEN** `isHistoryWebSocketReady` 为 false
- **THEN** SHALL 返回空 Stream（立即 done）

#### Scenario: empty text returns empty stream
- **WHEN** 输入文本 trim 后为空
- **THEN** SHALL 返回空 Stream（立即 done）

### Requirement: UI shows thinking before answer
HomeScreen SHALL 新增 `_chatThinking` 状态，`_voiceStripText` getter 优先展示 thinking（answer 首帧到达后切换展示 answer）。

#### Scenario: thinking displayed first
- **WHEN** 流式对话进行中且仅收到 thinking 事件
- **THEN** `_voiceStripText` SHALL 返回 thinking 累积文本
- **AND** 消息条 SHALL 实时展示 thinking 增量

#### Scenario: answer replaces thinking
- **WHEN** 收到首个 answer 增量
- **THEN** `_chatThinking` SHALL 被清空
- **AND** `_voiceStripText` SHALL 返回 answer 累积文本（优先于 thinking）
- **AND** 消息条 SHALL 切换展示 answer 内容

#### Scenario: answer accumulates incrementally
- **WHEN** 持续收到 answer 增量
- **THEN** `_chatReply` SHALL 累积追加所有 answer 增量
- **AND** 消息条 SHALL 实时展示 answer 全文

#### Scenario: stream error preserves partial content
- **WHEN** 流式过程中发生错误
- **THEN** SHALL 保留已收到的 answer（优先）或 thinking 文本
- **AND** 消息条 SHALL 展示已收到的部分内容（不清空）

### Requirement: stream subscription lifecycle managed
HomeScreen SHALL 正确管理 `sendCommand()` 返回的 Stream 订阅，避免并发发送与内存泄漏。

#### Scenario: new request cancels previous subscription
- **WHEN** 用户发起新的发送请求（语音松手或文字回车）
- **THEN** SHALL `cancel()` 上一个 `StreamSubscription`
- **AND** SHALL 清空 `_chatThinking` 与 `_chatReply`

#### Scenario: dispose cancels subscription
- **WHEN** HomeScreen `dispose()` 被调用
- **THEN** SHALL `cancel()` 当前活跃的 `StreamSubscription`（若存在）

### Requirement: sync chat API unchanged
同步接口 `POST /device/history/api/chat` 与 `fetchWidgetFeedingTip()` SHALL 保持完全不变。

#### Scenario: fetchWidgetFeedingTip still uses sync API
- **WHEN** `fetchWidgetFeedingTip()` 被调用
- **THEN** SHALL 继续调用同步接口 `POST /device/history/api/chat`
- **AND** 行为 SHALL 与变更前完全一致
