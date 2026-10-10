## ADDED Requirements

### Requirement: Growth asking text input MUST support hold-to-talk Chinese ASR

While the growth-trajectory workspace is in the asking phase and a text input is visible (`format=free_text`, or `format=choice` after the user opens manual text entry), the client MUST offer a press-and-hold speech control that fills the answer field with Chinese speech-to-text. The client MUST use the shared `HomeSpeechRecognizer` / global `VoiceAsrWsClient` path and MUST NOT open a second ASR WebSocket or use `/voice/chat/ws` for this fill. Releasing the hold MUST write the final transcript into the field and MUST NOT auto-submit the answer; the user MUST still use the existing submit control. 成长轨迹提问且文本框可见时 **必须** 提供按住说话中文转写填框；**必须** 共用全局 ASR；**不得** 新建第二条 ASR 或改用 chat/ws；松手 **不得** 自动提交，**必须** 仍经现有提交。

#### Scenario: Free-text question shows hold-to-talk

- **WHEN** 流返回 `question` 且 `format` 为 `free_text`
- **THEN** 客户端 MUST 展示文本输入、提交控件，以及按住说话控件

#### Scenario: Choice manual entry shows hold-to-talk

- **WHEN** `format` 为 choice 且用户进入「手动输入」
- **THEN** 客户端 MUST 在文本输入旁展示按住说话控件

#### Scenario: Choice buttons only have no mic

- **WHEN** `format` 为 choice 且未进入手动输入
- **THEN** 客户端 MUST NOT 展示按住说话控件

#### Scenario: Hold fills field without auto-submit

- **WHEN** 用户在追问文本输入态按住说话并松手且转写非空
- **THEN** 客户端 MUST 将最终中文转写写入答题输入框
- **AND** MUST NOT 仅因松手而调用 `submitAnswer` / 开启下一 turn

#### Scenario: Shared ASR singleton

- **WHEN** 成长轨迹页发起按住说话
- **THEN** 客户端 MUST 经 `createHomeSpeechRecognizer`（或等价）使用全局 ASR 客户端
- **AND** MUST NOT 为轨迹页单独 `new` 第二条 `VoiceAsrWsClient`

#### Scenario: Cancel listening when leaving ask or starting turn

- **WHEN** 用户提交答案进入思考流，或收到新 question，或离开提问态
- **THEN** 客户端 MUST 结束或取消进行中的语音采集会话
