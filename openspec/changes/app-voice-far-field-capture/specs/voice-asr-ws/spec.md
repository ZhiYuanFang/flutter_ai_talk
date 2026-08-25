## ADDED Requirements

### Requirement: 云端 ASR WS MUST 使用 App 共享 PCM 采集配置

When the user selects cloud ASR for home hold-to-talk, `VoiceAsrWsClient` MUST use the same shared PCM capture configuration (`AppVoiceRecordConfig.pcm16kMono`) as landscape voice chat and KWS. PCM format parameters in the `start` frame MUST remain 16 kHz, 16-bit, mono. 当用户选择首页云端 ASR 按住说话时，`VoiceAsrWsClient` MUST 使用与横屏对话及 KWS 相同的共享 PCM 采集配置（`AppVoiceRecordConfig.pcm16kMono`）。`start` 帧 PCM 参数 MUST 仍为 16 kHz、16-bit、单声道。

#### Scenario: 按住说话采集

- **WHEN** 用户在云端 ASR 模式下开始一轮 utterance 并上传 PCM
- **THEN** `VoiceAsrWsClient` MUST 通过共享 `RecordConfig` 调用 `startStream`
- **AND** MUST NOT 保留独立的 inline 裸采集配置

#### Scenario: 与横屏采集一致

- **WHEN** 同一设备先后使用横屏对话与首页云端 ASR
- **THEN** 两处 PCM 采集的 `autoGain` 与 Android 音源设置 MUST 一致（均来自共享模块）
