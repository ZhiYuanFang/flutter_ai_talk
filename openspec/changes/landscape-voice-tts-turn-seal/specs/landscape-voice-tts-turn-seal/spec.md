## ADDED Requirements

### Requirement: audio_end 后 TTS 收口 MUST 发出 TurnEnded

After the client handles a non-discarded `audio_end` for landscape `/voice/chat/ws`, it MUST emit the turn-completion signal (`VoiceChatTurnEnded` or equivalent) once playback finishes successfully, fails, or hits the playback watchdog timeout, carrying the resolved `finish_talk`. The client MUST NOT leave the turn open solely because `onPlayerComplete` never arrives. 横屏 `/voice/chat/ws` 在非 discard 的 `audio_end` 处理路径上，MUST 在播放成功结束、播放失败或播放看门狗超时后发出一次话轮结束信号（`VoiceChatTurnEnded` 或等价），并携带已解析的 `finish_talk`。MUST NOT 仅因 `onPlayerComplete` 未到达而无限挂起话轮。

#### Scenario: 正常播完

- **WHEN** `audio_end` 后 PCM 播放正常触发完成回调且未 discard
- **THEN** 客户端 MUST 发出带 `finish_talk` 的 `VoiceChatTurnEnded`
- **AND** 编排层 MUST 能清答案字幕并按 `finish_talk` 续听或回唤醒

#### Scenario: 播放器声停但 complete 未到

- **WHEN** `audio_end` 后已开始播放，但在看门狗时限内未收到完成回调且未 discard
- **THEN** 客户端 MUST 停止播放器（若仍占用）
- **AND** MUST 仍发出 `VoiceChatTurnEnded`（携带该轮 `finish_talk`）
- **AND** MUST 经 Debug 记录超时收口（如 `tts play timeout seal`）

#### Scenario: barge-in discard 不发 TurnEnded

- **WHEN** `_ttsDiscard`（或等价）已置位且 `audio_end`/播放结束
- **THEN** 客户端 MUST NOT 因本需求补发 `VoiceChatTurnEnded`
- **AND** 话轮收口 MUST 仍由 barge-in 编排路径负责

### Requirement: TTS 播放看门狗时限 MUST 与 PCM 时长相关

The playback wait after `audio_end` MUST use a timeout derived from PCM duration (sample count / sample rate) plus a documented slack, with a documented floor and hard cap that is substantially shorter than a multi-minute hang. `audio_end` 后等待播完的超时 MUST 由 PCM 时长（采样点数/采样率）加文档化 slack 推导，并带文档化下限与硬上限；硬上限 MUST 明显短于数分钟级挂起。

#### Scenario: 短回复

- **WHEN** PCM 时长约 2 秒
- **THEN** 看门狗时限 MUST 为「约 2s + slack」且不低于下限
- **AND** MUST NOT 使用固定约 2 分钟作为唯一等待

#### Scenario: 长回复受硬上限约束

- **WHEN** PCM 时长很长
- **THEN** 看门狗时限 MUST NOT 超过实现文档化的硬上限（建议不超过约 60 秒量级）

### Requirement: audio_chunk 与 audio_end MUST 串行处理

The client MUST process `audio_chunk` and `audio_end` frames for a voice-chat session on a single serial pipeline so that `audio_end` does not take the PCM buffer before previously received chunks have been appended. 同一 voice-chat 会话内，客户端 MUST 在单一串行管道上处理 `audio_chunk` 与 `audio_end`，MUST NOT 在前序 chunk 尚未写入缓冲时抢先 `audio_end` 取走 PCM。

#### Scenario: chunk 紧随 end 同批到达

- **WHEN** 服务端连续下发若干 `audio_chunk` 后立即 `audio_end`
- **THEN** 开播所用 PCM MUST 包含该 `audio_end` 之前已入队的全部 chunk 字节
- **AND** MUST NOT 因并行 unawaited 丢尾包导致系统性半包开播
