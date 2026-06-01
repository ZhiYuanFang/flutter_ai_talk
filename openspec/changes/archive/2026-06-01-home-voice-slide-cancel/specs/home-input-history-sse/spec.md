## ADDED Requirements

### Requirement: 按住说话支持滑出取消

The system SHALL support canceling an in-progress press-and-hold utterance when the user slides the finger outside the voice orb without releasing on the orb. 系统在 Android/iOS 主页**按住说话**交互中，必须支持用户将手指**滑出语音圆区域**后通过松手**取消**本次说话，避免误发送。

#### Scenario: 与主输入方式一致

- **WHEN** 用户使用按住说话主输入
- **THEN** 滑出取消行为必须对当前选中的语音识别引擎均生效（云端 / Vosk / 系统 STT）
