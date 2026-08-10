## MODIFIED Requirements

### Requirement: iOS 可在设置中心切换语音后端并记忆

The Settings center MUST NOT present the speech-engine selection tile (`SpeechEngineTile` / 「语音识别」) on iOS or Android. The client MAY continue to persist and read a previously chosen speech engine for **companion** (and any other non-feeding) voice paths. When no persisted choice exists, the client MUST use the platform default (Android on-device Vosk; iOS existing default). Companion voice input MUST remain available. Feeding page voice input UI is out of scope for this requirement (see `feeding-buttons-only`).

设置中心在 iOS/Android **不得** 再展示「语音识别」引擎切换模块。客户端 MAY 继续读写既有引擎偏好供**陪伴**等非喂养语音路径使用；无偏好时 MUST 使用平台默认。陪伴语音 **必须** 仍可用。

#### Scenario: 设置中心无语音识别模块

- **WHEN** 用户在 iOS 或 Android 打开设置中心
- **THEN** UI MUST NOT 展示 `SpeechEngineTile` /「语音识别」切换控件

#### Scenario: 陪伴仍可语音

- **WHEN** 用户进入陪伴页并使用语音输入（非 Web）
- **THEN** 系统 MUST 仍能按持久化引擎或平台默认完成转写准备/识别流程
- **AND** MUST NOT 因设置项隐藏而强制禁用陪伴语音
