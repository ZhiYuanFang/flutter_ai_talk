## MODIFIED Requirements

### Requirement: 设置开关默认关闭

The system MUST NOT expose a user-visible settings toggle for recording diagnostics; the feature SHALL remain disabled for end users unless explicitly enabled in source code. 系统**不得**在设置页向用户展示「显示录音数据」开关；对用户而言诊断能力**必须**默认且恒为关闭，除非开发者在源码中显式启用（如将 `kRecordingDiagnosticsFeatureEnabled` 设为 `true` 并恢复设置 UI）。

#### Scenario: 设置页无诊断开关

- **WHEN** 用户打开设置中心（Android / iOS）
- **THEN** 不得展示「显示录音数据」或等价的诊断开关控件

#### Scenario: 功能关闭时主页不显示

- **WHEN** 诊断功能在源码中处于关闭状态（默认）
- **THEN** 主页不得显示录音诊断面板，即使用户本地 prefs 中 `show_recording_diagnostics` 曾为 `true`

#### Scenario: 源码启用后可读 prefs

- **WHEN** 开发者将功能开关设为启用、恢复设置 UI，且用户在设置中打开「显示录音数据」
- **THEN** 在满足云端聆听条件时必须能够显示诊断面板，且重启应用后仍保持 prefs 中的开启状态

### Requirement: 仅云端 ASR 且聆听中显示

The system MUST show the recording diagnostics panel only when diagnostics are enabled in source code, the speech engine is cloud ASR, and `_listening` is true. 录音诊断面板**仅当**源码中诊断功能已启用、当前语音识别引擎为**云端 ASR**、且 `_listening == true` 时显示；Vosk 或系统 STT 下**即使** prefs 为开启也**不得**显示。

#### Scenario: 云端聆听中显示

- **WHEN** 诊断功能已启用、prefs 为开启、引擎为云端 ASR、用户处于 `_listening`
- **THEN** 语音圆左侧必须显示诊断信息

#### Scenario: Vosk 下不显示

- **WHEN** 诊断功能已启用且 prefs 为开启，但引擎为 Vosk 且 `_listening` 为 true
- **THEN** 不得显示录音诊断面板

#### Scenario: 未聆听不显示

- **WHEN** 诊断功能已启用且 prefs 为开启，但 `_listening` 为 false
- **THEN** 不得显示录音诊断面板

#### Scenario: 功能未启用不显示

- **WHEN** 源码中诊断功能处于关闭状态（默认）
- **THEN** 即使引擎为云端 ASR 且 `_listening` 为 true，也不得显示录音诊断面板
