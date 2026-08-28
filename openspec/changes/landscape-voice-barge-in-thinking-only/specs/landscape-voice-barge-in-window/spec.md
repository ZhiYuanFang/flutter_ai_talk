## ADDED Requirements

### Requirement: barge-in MUST 仅在思考窗开放

After `interrupt_commit` and while waiting for reply TTS (thinking window), the landscape/portrait prediction voice session MAY arm barge-in KWS so a wake phrase can interrupt. Once reply TTS playback is about to start, the client MUST pause or otherwise release KWS microphone ownership and MUST treat barge-in as disarmed for the speaking window. `interrupt_commit` 之后、回复 TTS 开播之前（思考窗），预测语音会话 MAY 武装 barge-in KWS 以便唤醒词打断。一旦即将开始播放回复 TTS，客户端 MUST pause 或以其它方式释放 KWS 麦克风，并 MUST 在播放窗内将 barge-in 视为已解除。

#### Scenario: 思考中可打断

- **WHEN** 已 `interrupt_commit` 且尚未开始播放回复 TTS，且 barge-in 已武装
- **AND** 用户说出唤醒词
- **THEN** 客户端 MUST 走既有 barge-in 路径（停后续 TTS 接收、end、提示「我在」、开听）

#### Scenario: 开播前释放 KWS

- **WHEN** 客户端处理 `audio_end` 并即将播放累计 TTS PCM
- **THEN** 客户端 MUST 在开播前 pause/disarm barge-in KWS
- **AND** MUST 经 Debug 记录原因（如 `tts_start`）

#### Scenario: 播放中唤醒词不打断

- **WHEN** 回复 TTS 正在播放
- **AND** 用户说出唤醒词
- **THEN** 客户端 MUST NOT 触发 barge-in 打断当前播放
- **AND** MUST NOT 为 barge-in 重新 start/resume KWS 占麦

#### Scenario: 播完后按 finish_talk 编排

- **WHEN** TTS 收口发出 `VoiceChatTurnEnded`
- **THEN** 客户端 MUST 按既有 `finish_talk` 续听或回唤醒
- **AND** MUST NOT 在 Speaking 窗内保持 KWS 占麦

### Requirement: 播放窗芯片 MUST NOT 以 barge-in 停 TTS

While reply TTS is playing, tapping the listen chip MUST NOT invoke the barge-in stop-TTS path. 回复 TTS 播放期间，点击聆听芯片 MUST NOT 走 barge-in 停 TTS 路径。

#### Scenario: 播中点芯片

- **WHEN** TTS 正在播放且用户点击聆听芯片
- **THEN** 客户端 MUST NOT 调用 `stopTts` / discard 打断本轮播放
- **AND** Thinking 窗或假死「请说话」等既有芯片行为 MUST 保持可用（非播中）
