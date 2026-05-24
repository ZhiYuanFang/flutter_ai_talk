## MODIFIED Requirements

### Requirement: 主输入方式按平台区分

The system SHALL provide a dominant primary input on home: on Android and iOS, press-and-hold voice using the user-selected speech engine (cloud ASR or system STT); on Web, text submit without voice capture for that control. 系统必须在主页提供视觉显著的主输入区。**Android / iOS** 上用户通过**按住开始、松手结束**完成一次采集；系统必须使用用户在设置中选择的**云端识别**或**系统识别**将语音转为文字，且仅将转写后的文本发往指令接口；**不得**再使用 Vosk 端侧识别。**Web** 上系统不得对该主控件使用语音采集；用户必须以文本输入自然语言并**显式提交**。

#### Scenario: Android 语音采集结束

- **WHEN** 用户在 Android 上说完话并松开语音控件
- **THEN** 系统必须通过云端 ASR 或系统 STT（按当前设置）获得转写文本并以该文本为载荷调用对外的指令动作

#### Scenario: 移动端语音采集结束（iOS）

- **WHEN** 用户在 iOS 上说完话并松开语音控件
- **THEN** 系统必须通过云端 ASR 或系统 STT（按当前设置）获得转写文本并以该文本为载荷调用对外的指令动作

#### Scenario: Web 文本提交

- **WHEN** 用户在 Web 上输入文字并提交
- **THEN** 系统必须使用与移动端相同的指令载荷形状，以所输入文字调用该指令动作
