## ADDED Requirements

### Requirement: Chat WS start MUST carry orientation-appropriate outputModality

The `/voice/chat/ws` client MUST include `outputModality` on JSON `start` according to the active prediction voice mode: portrait go-record PTT MUST send `text`; landscape wake/listen dialogue MUST send `audio` (or an explicit value that selects server TTS). The client MUST refresh modality on the next `start` after orientation or mode switches (via `end` then `start` when a session was already started). 客户端 `start` MUST 按模式携带 `outputModality`（竖屏 text / 横屏 audio），模式切换后 MUST 在下一轮 `start` 更新。

#### Scenario: Portrait PTT start is text

- **WHEN** 竖屏「去记录」PTT 发送 `start`
- **THEN** JSON MUST 含 `outputModality`=`text`

#### Scenario: Landscape start is audio

- **WHEN** 横屏唤醒或点麦芯对话发送 `start`
- **THEN** JSON MUST 含 `outputModality`=`audio`（或等价默认 audio）

### Requirement: Text output modality MUST seal the turn without waiting for audio_end

When the active session `outputModality` is `text`, the client MUST treat a successful `answer` frame (honoring `finish_talk` when present) as sufficient to complete the turn-completion signal for UI controllers, and MUST NOT hang waiting for `audio_chunk` / `audio_end`. When `outputModality` is `audio`, the client MUST continue to consume TTS frames and seal after playback (or empty audio) per existing landscape TTS turn-seal behavior. `outputModality=text` 时 MUST 以 `answer` 收口，MUST NOT 死等 `audio_end`；audio 模式 MUST 仍按既有 TTS 收口。

#### Scenario: Text mode seals on answer

- **WHEN** 当前会话为 text 输出且服务端下发 `answer` 且无 `audio_*`
- **THEN** 客户端 MUST 发出话轮结束信号供编排层继续
- **AND** MUST NOT 无限等待 `audio_end`

#### Scenario: Audio mode still plays TTS

- **WHEN** 当前会话为 audio 输出且服务端下发 `audio_chunk`/`audio_end`
- **THEN** 客户端 MUST 播放流式音频并按既有规则 seal
