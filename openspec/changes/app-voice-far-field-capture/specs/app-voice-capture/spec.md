## ADDED Requirements

### Requirement: App MUST 暴露唯一 PCM 采集配置

The Flutter app MUST define a single shared PCM capture configuration (e.g. `AppVoiceRecordConfig.pcm16kMono`) as the sole source of truth for all in-app voice input that uses the `record` package to stream PCM. The shared configuration MUST use 16 kHz, 16-bit, mono PCM, MUST enable automatic gain control (`autoGain: true`) on platforms where supported, MUST keep `noiseSuppress` and echo cancellation disabled during uplink listen phases in this change (`noiseSuppress: false`, `echoCancel: false`), and MUST set Android `audioSource` to `voiceRecognition` via `AndroidRecordConfig`. Client code MUST NOT define divergent inline `RecordConfig` instances for landscape chat WS, home cloud ASR WS, or landscape KWS. 客户端 MUST 提供唯一共享 PCM 采集配置（如 `AppVoiceRecordConfig.pcm16kMono`），作为所有经 `record` 包流式上送 PCM 的语音输入的唯一真相源；MUST 为 16 kHz / 16-bit / mono，MUST 在支持平台启用 `autoGain: true`，本变更听音阶段 MUST 保持 `noiseSuppress: false` 与 `echoCancel: false`，Android MUST 通过 `AndroidRecordConfig` 使用 `voiceRecognition` 音源。横屏 chat WS、首页云端 ASR WS、横屏 KWS **不得**再 inline 分散定义 `RecordConfig`。

#### Scenario: 横屏 chat 使用共享配置

- **WHEN** `VoiceChatWsClient` 调用 `startStream` 上送用户语音
- **THEN** MUST 使用 `AppVoiceRecordConfig.pcm16kMono`（或等价唯一常量）
- **AND** MUST NOT 使用本地私有 inline `RecordConfig`

#### Scenario: 首页云端 ASR 使用共享配置

- **WHEN** 用户选择云端识别并按住说话，`VoiceAsrWsClient` 开始 PCM 流
- **THEN** MUST 使用与横屏相同的共享 `RecordConfig`

#### Scenario: 横屏 KWS 使用共享配置

- **WHEN** `LandscapeWakeWord` 在 `start` 或 `resume` 后采集 PCM 供 KWS
- **THEN** MUST 使用与 chat WS 相同的共享 `RecordConfig`

#### Scenario: 系统 STT 例外

- **WHEN** 用户选择系统识别引擎（`SystemSttHomeSpeechRecognizer` / `speech_to_text`）
- **THEN** 该路径 MAY 继续不使用 `AppVoiceRecordConfig`
- **AND** 规格 MUST 将系统 STT 记录为本能力的明确例外

### Requirement: 共享配置 MUST NOT 在本变更启用客户端掐帧

The shared capture configuration and uplink paths in this change MUST continue streaming all PCM frames to the server without client-side energy gating that drops sub-threshold frames. Far-field improvement MUST rely on gain and threshold alignment, not silence frame suppression. 本变更中共享采集配置与上送路径 MUST 继续向服务端流式发送全部 PCM 帧，MUST NOT 以客户端能量门控丢弃低于阈值的帧。远场改善 MUST 依赖增益与门槛对齐，而非静音掐帧。

#### Scenario: 低能量帧仍上送

- **WHEN** 开听期间出现低于有效音门槛的 PCM 块
- **THEN** 客户端 MUST 仍将该块经 WebSocket 二进制帧上送（在 `_listening` / utterance 活跃期间）
- **AND** MUST NOT 因块级 avgAbs 低于门槛而跳过 `sink.add`

### Requirement: 有效音能量常量 MUST 集中定义

The app MUST define the client-side effective-speech energy threshold (e.g. `AppVoiceRecordConfig.effectiveChunkAvgAbs`) in the same module as the shared `RecordConfig`. Landscape chat idle cancellation and `hasEffectiveSpeech` detection MUST read this constant. The initial value MUST be lower than the previous default (~200) to support far-field capture; final values MUST be validated on device in the flat screen-up 2 m quiet-speech fixture. 客户端 MUST 在与共享 `RecordConfig` 相同模块中定义有效音能量阈值（如 `effectiveChunkAvgAbs`）。横屏 chat 的 idle 取消与 `hasEffectiveSpeech` MUST 读取该常量。初值 MUST 低于原默认（约 200）以支持远场；最终值 MUST 在平放屏朝上 2m 小声验收集上经真机标定。

#### Scenario: 横屏开听读取集中阈值

- **WHEN** `VoiceChatWsClient` 检测块级 avgAbs 是否计入有效音
- **THEN** MUST 使用 `AppVoiceRecordConfig.effectiveChunkAvgAbs`
- **AND** MUST NOT 硬编码分散阈值常量

#### Scenario: 诊断日志

- **WHEN** 横屏 chat 上送 PCM 且处于 debug 构建
- **THEN** 客户端 SHOULD 经 `AppDebugLog.landscapeVoice` 记录块级与会话 avgAbs（至少在有 effective 状态变化或标定阶段）
