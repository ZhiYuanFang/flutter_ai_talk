## Why

华为等设备上端侧 Vosk 存在包体与稳定性成本；网关已提供 **`/voice/asr/ws`** 仅做实时转写。需在 App 内增加可切换的**云端流式 ASR**，并与既有 `sendCommand` 文本指令链衔接。

## What Changes

- 新增 `VoiceAsrWsClient`：`start` → Binary PCM → `commit` → `asr_partial`/`asr_final` → `end`。
- 设置中心三档引擎：**云端实时转写** / **端侧 Vosk** / **系统语音识别**。
- **默认**：Android → 云端；iOS → 系统（未存偏好时）。
- 云端模式：WS 断开时主页麦克风区提示；按住前自动 `connect`。
- `asr_final` 文本仍走 `POST /voice/text/chat`（`sendCommand`）。

## Capabilities

### New Capabilities

- `voice-asr-ws`：语音转写 WebSocket 协议、连接态、与主页按住说话集成。

### Modified Capabilities

- `home-input-history-sse`：识别来源扩展为三引擎可配置。

## Impact

- `lib/voice/`、`lib/asr/cloud_asr_home_speech_recognizer.dart`、`lib/config/speech_engine*.dart`、`home_screen.dart`、设置中心。
