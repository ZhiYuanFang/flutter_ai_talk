## ADDED Requirements

### Requirement: 左下监听 chip MUST 展示 chat WS 连接与本轮聆听态

In landscape prediction, the listen affordance MUST show a connection indicator adjacent to the microphone icon: a red dot when `/voice/chat/ws` is not ready; a green dot when the socket is ready (including while waiting for the wake phrase). The microphone icon MUST be highlighted only when the socket is ready AND the client is actively streaming the current user utterance uplink (`VoiceChatWsClient` listening). The microphone MUST NOT be highlighted solely because a wake turn has started (`awakened`) before uplink listening begins. 预测横屏左下监听入口 MUST 在话筒旁展示连接指示：chat WS 未就绪为红点；已就绪（含待唤醒）为绿点。话筒高亮 MUST 仅在「已连接且本轮正在上送用户语音」时成立；MUST NOT 仅因 `awakened`/文案「我在听…」而高亮。

#### Scenario: 待唤醒且已连接

- **WHEN** 预测横屏已激活且 `/voice/chat/ws` 握手就绪、尚未本轮开麦上送
- **THEN** 话筒旁 MUST 显示绿点
- **AND** 话筒图标 MUST NOT 使用「本轮在听」高亮样式

#### Scenario: 本轮正在听

- **WHEN** chat WS 就绪且 `beginListen` 已成功、正在上送 PCM
- **THEN** 话筒旁 MUST 显示绿点
- **AND** 话筒图标 MUST 高亮

#### Scenario: 未连接

- **WHEN** chat WS 未就绪或已断线
- **THEN** 话筒旁 MUST 显示红点
- **AND** 话筒 MUST NOT 以「本轮在听」高亮

### Requirement: 唤醒后开听 MUST 完成或失败恢复（不得永久「我在听…」）

After wake acknowledgement UI is shown, the client MUST progress through releasing the wake mic, playing the local「我在」prompt, ensuring the chat session, and starting uplink recording, with timeouts on operations that may hang (including wake `pause` and chat `startStream`). If any step fails or times out, the client MUST surface a short user-readable reason, clear the in-turn busy latch, resume wake listening when still active, and MUST NOT leave the status caption stuck on「我在听…」indefinitely. 唤醒确认 UI 展示后，客户端 MUST 推进放麦、播「我在」、确保会话、开麦上送，并对可能挂起的步骤（含唤醒 pause 与 chat startStream）施加超时。任一步失败或超时 MUST 给出可读短因、清除本轮忙锁、在仍激活时恢复唤醒监听，且 MUST NOT 使状态文案无限停在「我在听…」。

#### Scenario: 开麦成功进入请说话

- **WHEN** 唤醒后各启动步骤成功完成
- **THEN** 左下角状态 MUST 进入表示可说话的文案（如「请说话…」）
- **AND** 连接指示 MUST 符合「已连接且本轮在听」

#### Scenario: 开麦超时或失败

- **WHEN** `pause` 或 `startStream`（或会话确保）超时/失败
- **THEN** 左下角 MUST 显示失败类短文案（不得仍为无限「我在听…」）
- **AND** 客户端 MUST 清除本轮忙锁并尝试恢复唤醒监听

### Requirement: 横屏语音启动路径 MUST 可经 Debug 日志观测

Wake-to-listen startup and chat ready transitions MUST be logged via `AppDebugLog` with a dedicated tag (e.g. `[LandscapeVoice]`) including step names and failure causes (truncated/err), without logging secrets. 唤醒到开听的启动步骤与 chat ready 变化 MUST 经带专用 tag 的 `AppDebugLog` 记录步骤名与失败原因，MUST NOT 记录密钥。

#### Scenario: 卡在开听时可对照日志

- **WHEN** Debug 构建下用户唤醒后开听失败或超时
- **THEN** logcat 过滤专用 tag MUST 可见对应步骤失败记录
