## ADDED Requirements

### Requirement: App pause MUST stop TTS and resume MUST NOT replay it

When the app moves to the background (`paused`, or equivalent inactive where the platform suspends audio) during prediction voice reply TTS or a local prompt played by the same player, the client MUST stop the player and discard any buffered PCM so playback cannot continue. When the app returns to the foreground, the client MUST NOT start playback of that same utterance again. If a turn was waiting for playback completion, the client MUST close it as discarded/interrupted (MUST NOT emit a successful playback-complete `VoiceChatTurnEnded` solely because the app resumed) and MUST let the existing barge-in or discard orchestration return to wake or the already-resolved non-playback path without replaying audio.

预测语音回复 TTS 或同一播放器上的本地提示在 App 进入后台时，客户端 MUST 停止播放并丢弃缓冲。回到前台 MUST NOT 重播该句。若话轮仍在等播完，MUST 按 discard/打断收口，MUST NOT 仅因 resume 补发成功播完的 `VoiceChatTurnEnded`，且 MUST NOT 再播该音频。

#### Scenario: 后台停播

- **WHEN** 回复 TTS 正在播放且 App 进入 `paused`
- **THEN** 客户端 MUST 停止播放器并丢弃未播完缓冲

#### Scenario: 回前台不重播

- **WHEN** 上一句 TTS 因进入后台被停止
- **AND** App 回到前台
- **THEN** 客户端 MUST NOT 再次播放该句音频
