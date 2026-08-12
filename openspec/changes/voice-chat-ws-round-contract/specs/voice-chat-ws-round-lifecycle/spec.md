## ADDED Requirements

### Requirement: 客户端 MUST 解析并暴露 finish_talk

The `/voice/chat/ws` client MUST parse the boolean `finish_talk` field from server `answer` and/or `audio_end` frames (when present) and MUST expose it on the turn-completion signal consumed by UI controllers (e.g. `VoiceChatTurnEnded` or an equivalent typed event). Missing `finish_talk` MUST be treated as a documented default that ends the dialogue segment (return-to-wake path), not as silent ignore. `/voice/chat/ws` 客户端 MUST 解析服务端 `answer` 与/或 `audio_end` 帧中的布尔字段 `finish_talk`（若存在），并 MUST 在 UI 控制器消费的话轮结束信号上暴露该值。缺失 `finish_talk` 时 MUST 按已文档化的缺省（结束本段对话、走回唤醒路径）处理，MUST NOT 静默忽略导致无限假听。

#### Scenario: audio_end 携带 finish_talk

- **WHEN** 服务端下发 `audio_end` 且含 `finish_talk`
- **THEN** 客户端 MUST 在随后的话轮结束事件中带上该布尔值供编排层使用

#### Scenario: 缺省 finish_talk

- **WHEN** 成功答完路径未出现可解析的 `finish_talk`
- **THEN** 客户端 MUST 按「结束本段对话」缺省暴露（等价于需回唤醒），并可用 Debug 日志记录缺省

### Requirement: 下一音频窗前 MUST end 再 start

After a successful server commit/answer path that arms server-side `waitEndAfterCommit`, the client MUST send JSON `type=end` and then a new JSON `type=start` (with `deviceNo` and PCM meta) before streaming further user PCM on the same socket. The client MUST NOT assume an already-started session flag alone re-opens the audio window. 在服务端成功 commit/应答并武装 `waitEndAfterCommit` 之后，客户端在同一套接字上再次上送用户 PCM 之前 MUST 先发送 JSON `type=end`，再发送新的 JSON `type=start`（含 `deviceNo` 与 PCM 元数据）。客户端 MUST NOT 仅凭「会话已 start」标志认定音频窗仍开放。

#### Scenario: 续听前重启音频轮次

- **WHEN** 本轮 TTS/答完后编排层需要继续聆听用户下一句
- **THEN** 客户端 MUST 在 `beginListen`（或等价开听）之前完成 `end`→`start`
- **AND** MUST 随后才上送 PCM

#### Scenario: 禁止跳过 end

- **WHEN** `_sessionStarted` 已为 true 且服务端可能仍在 `waitEndAfterCommit`
- **THEN** `ensureSessionStarted` / 开听路径 MUST NOT 因已 start 而跳过 `end`→`start` 清门闩

### Requirement: exit 帧 MUST 结束对话段

When the server sends `exit`, the client MUST stop uplink listening and MUST signal the landscape (or host) controller to end the dialogue segment (return to wake waiting), and MUST send `end` to clear server wait/session state when the socket remains open. 当服务端下发 `exit` 时，客户端 MUST 停止上行聆听，并 MUST 通知横屏（或宿主）控制器结束本段对话（回待唤醒）；若连接仍保持，MUST 发送 `end` 以清除服务端等待/会话态。

#### Scenario: 收到 exit

- **WHEN** 解析到 `type=exit`
- **THEN** MUST 停止本轮麦克风上送
- **AND** MUST 触发结束对话段 / 回唤醒编排
- **AND** 连接仍开时 MUST 发送 `type=end`

### Requirement: 客户端主动结束本段 MUST 发送 end

Whenever the App ends a dialogue segment on its own initiative while the `/voice/chat/ws` socket remains open—including the landscape 5-second no-effective-speech idle exit that plays the leave prompt and returns to wake—the client MUST send JSON `type=end` (e.g. via `endSession`) after stopping the mic and MUST clear the local session-started flag. Stopping the mic alone MUST NOT be treated as sufficient to close the server audio/session window. 凡 App 在 `/voice/chat/ws` 连接仍保持时主动结束本段对话——包括横屏 5 秒无有效音 idle 退下（播退下音并回待唤醒）——客户端在停麦之后 MUST 发送 JSON `type=end`（例如经 `endSession`），并 MUST 清除本地「会话已 start」标志。仅停麦 MUST NOT 视为已关闭服务端音频/会话窗。

#### Scenario: 5s idle 退下发 end

- **WHEN** 开听后 5 秒内无有效音触发 idle 退下路径
- **THEN** 客户端 MUST 停止上行麦克风
- **AND** MUST 在回唤醒前向服务端发送 `type=end`（连接仍开时）
- **AND** MUST NOT 仅 `ensureMicStopped` 而不发 `end`

#### Scenario: finish_talk 结束本段亦发 end

- **WHEN** 编排层因 `finish_talk=true`（或缺省结束本段）回唤醒且连接仍开
- **THEN** 客户端 MUST 发送 `type=end` 再恢复唤醒监听
