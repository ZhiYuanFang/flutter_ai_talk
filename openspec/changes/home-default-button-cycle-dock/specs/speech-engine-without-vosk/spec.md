## MODIFIED Requirements

### Requirement: 语音不可用时不阻塞非语音功能

The system MUST allow non-voice home input and other features when the selected speech engine is unavailable. 当云端或系统 STT 不可用时，系统 MUST 仍允许非语音功能（登录、历史、设置等）；**不得**因语音不可用而阻塞应用。

#### Scenario: 云端未连接（移动端）

- **WHEN** 用户在 Android/iOS 选择云端识别但 WebSocket 未就绪
- **THEN** 主页 MUST 提示连接状态，且 Toast/文案 MUST 引导用户**切换到事件按钮记录模式**（或稍后重试），**不得**再引导「改用文字输入」

#### Scenario: 云端未连接（Web）

- **WHEN** 用户在 Web 上选择云端识别但 WebSocket 未就绪
- **THEN** 主页 MUST 提示连接状态并允许切换文字输入或系统识别（若平台可用），行为与变更前一致
