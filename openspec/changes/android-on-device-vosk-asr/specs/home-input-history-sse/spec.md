## MODIFIED Requirements

### Requirement: 主输入方式按平台区分

The system SHALL provide a dominant primary input on home: on Android, press-and-hold voice with on-device Vosk STT (text-only payload); on iOS, press-and-hold voice with STT as today unless otherwise specified; on Web, text submit without voice capture for that control. 系统必须在主页提供视觉显著的主输入区。**Android** 上用户必须通过**按住开始、松手结束**完成一次采集；系统必须使用 **App 内 Vosk 离线识别**将语音转为文字，且仅将转写后的文本发往指令接口（或 Mock 等价物），**不得**依赖 Android 系统 `SpeechRecognizer` 或要求用户安装第三方语音引擎。**iOS** 上可继续使用系统或插件支持的语音识别（本变更默认不强制改为 Vosk）。**Web** 上系统不得对该主控件使用语音采集；用户必须以文本输入自然语言并**显式提交**。

#### Scenario: Android 语音采集结束

- **WHEN** 用户在 Android 上说完话并松开语音控件
- **THEN** 系统必须通过内置 Vosk 获得转写文本并以该文本为载荷调用对外的指令动作

#### Scenario: 移动端语音采集结束（iOS）

- **WHEN** 用户在 iOS 上说完话并松开语音控件
- **THEN** 系统必须获得转写文本并以该文本为载荷调用对外的指令动作

#### Scenario: Web 文本提交

- **WHEN** 用户在 Web 上输入文字并提交
- **THEN** 系统必须使用与移动端相同的指令载荷形状，以所输入文字调用该指令动作
