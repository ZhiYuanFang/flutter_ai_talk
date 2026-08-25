## ADDED Requirements

### Requirement: chat WS 上送 MUST 使用 App 共享 PCM 采集配置

The `/voice/chat/ws` client MUST use the app-wide shared PCM capture configuration from `app-voice-capture` for `AudioRecorder.startStream`. Uplink MUST remain continuous PCM without client-side frame dropping in this change. Client-side effective-speech detection MUST use the centralized `effectiveChunkAvgAbs` constant. `/voice/chat/ws` 客户端 MUST 使用 `app-voice-capture` 定义的 App 级共享 PCM 采集配置调用 `startStream`。本变更上送 MUST 保持连续 PCM，不得客户端掐帧。客户端有效音检测 MUST 使用集中定义的 `effectiveChunkAvgAbs` 常量。

#### Scenario: beginListen 使用共享配置

- **WHEN** `VoiceChatWsClient.beginListen` 成功启动 PCM 流
- **THEN** MUST 使用 `AppVoiceRecordConfig.pcm16kMono`
- **AND** MUST 在 `_sendPcm` 路径用集中阈值更新 `hasEffectiveSpeech`

#### Scenario: 协议不变

- **WHEN** 本变更部署后客户端上送 PCM
- **THEN** `start` JSON 参数 MUST 仍为 16 kHz / 16-bit / mono / stream
- **AND** MUST NOT 变更 WebSocket 帧协议或引入 text 上行
