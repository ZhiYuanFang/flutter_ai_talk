## MODIFIED Requirements

### Requirement: 主输入方式按平台区分

The system SHALL provide a dominant primary input on home: press-and-hold voice with STT on Android/iOS (text-only payload). On Web, the system MUST render either the text-field primary input with explicit submit, or the same press-and-hold voice primary input pattern as mobile, according to the single globally configured Web home input mode; when that mode is text, the system MUST NOT use voice capture for that primary control; when that mode is speech and STT is available, the system SHALL use voice capture and send only transcribed text as the command payload. 系统必须在主页提供视觉显著的主输入区。在 Android 与 iOS 上，用户必须通过**按住开始、松手结束**完成一次采集；系统必须使用原生或系统支持的语音识别将语音转为文字，且仅将转写后的文本发往指令接口（或 Mock 等价物）。在 Web 上，主输入方式由全局配置决定：文本模式下用户必须以文本输入自然语言并**显式提交**；语音模式下用户必须使用与移动端一致的按住说话交互，并在技术不可用时降级为文本模式（实现细节见对应变更 design）。

#### Scenario: 移动端语音采集结束

- **WHEN** 用户在 Android 或 iOS 上说完话并松开语音控件
- **THEN** 系统必须获得转写文本并以该文本为载荷调用对外的指令动作

#### Scenario: Web 文本提交

- **WHEN** 用户在 Web 上处于文本模式并输入文字并提交
- **THEN** 系统必须使用与移动端相同的指令载荷形状，以所输入文字调用该指令动作

#### Scenario: Web 语音模式提交

- **WHEN** 用户在 Web 上处于语音模式并完成一次按住说话且识别成功
- **THEN** 系统必须使用与移动端相同的指令载荷形状，以识别得到的文字调用该指令动作
