## MODIFIED Requirements

### Requirement: barge-in MUST 仅在思考窗开放

After `interrupt_commit` and while waiting for reply TTS (thinking window), the landscape/portrait prediction voice session MAY arm barge-in KWS so a wake phrase can interrupt. Once reply TTS playback is about to start, the client MUST pause or otherwise release KWS microphone ownership and MUST treat barge-in as disarmed for the speaking window. While reply TTS is playing, the client MUST NOT start a microphone capture (including `AudioRecord` / `startStream`) for speech-energy or wake barge-in, and MUST NOT stop playback because of detected speech or a wake phrase. A thinking-window barge-in MUST show subtitle 「我在」, MUST play the short local 叮 asynchronously, and MUST begin listening without waiting for that sound to finish. `interrupt_commit` 之后、回复 TTS 开播之前（思考窗），预测语音会话 MAY 武装 barge-in KWS 以便唤醒词打断。一旦即将开始播放回复 TTS，客户端 MUST pause 或以其它方式释放 KWS 麦克风，并 MUST 在播放窗内将 barge-in 视为已解除。回复 TTS 播放期间客户端 MUST NOT 为开口能量或唤醒打断再开麦克风采集，也 MUST NOT 因检测到说话或唤醒词而停播。思考窗打断 MUST 展示字幕「我在」，MUST 异步播放短本地「叮」，并 MUST 不等该声音结束就开始聆听。

#### Scenario: 思考中可打断

- **WHEN** 已 `interrupt_commit` 且尚未开始播放回复 TTS，且 barge-in 已武装
- **AND** 用户说出唤醒词「胖宝」
- **THEN** 客户端 MUST 走既有 barge-in 路径（停后续 TTS 接收、end、字幕「我在」、异步「叮」、开听）
- **AND** MUST NOT 等「叮」或人声「我在」播完才开听

#### Scenario: 开播前释放 KWS

- **WHEN** 客户端处理 `audio_end` 并即将播放累计 TTS PCM
- **THEN** 客户端 MUST 在开播前 pause/disarm barge-in KWS
- **AND** MUST 经 Debug 记录原因（如 `tts_start`）
- **AND** MUST NOT 在随后的播放期间为打断启动录音

#### Scenario: 播放中唤醒词不打断

- **WHEN** 回复 TTS 正在播放
- **AND** 用户说出唤醒词或发出达到有效音能量的声音
- **THEN** 客户端 MUST NOT 触发 barge-in 打断当前播放
- **AND** MUST NOT 为 barge-in 重新 start/resume KWS 或另开录音占麦

#### Scenario: 播完后按 finish_talk 编排

- **WHEN** TTS 收口发出 `VoiceChatTurnEnded`
- **THEN** 客户端 MUST 按既有 `finish_talk` 续听或回唤醒
- **AND** MUST NOT 在 Speaking 窗内保持 KWS 占麦
