## ADDED Requirements

### Requirement: Voice mode SHALL show AI chat quota below voice orb with glass styling

On the feeding home screen, when `HomeInputChannel.voice` is active, the client MUST display the monthly AI dialogue remaining quota (`voiceAi` from `GET /voice/app/api/ai-quota`) in a glass-morphism capsule positioned **below** the voice orb, vertically separated so the hint MUST NOT overlap or obscure the orb or its press-and-hold hit target.

喂养主页语音模式下，客户端必须在语音球**下方**以玻璃拟态胶囊展示「本月 AI 对话剩余 N 次」，且不得遮挡语音球或其按压热区。

#### Scenario: 额度在语音球下方

- **WHEN** 用户处于喂养主页语音输入模式且额度数据可用
- **THEN** UI SHALL 在语音球圆心下方展示剩余次数字样
- **AND** 额度文案 SHALL NOT 覆盖语音球圆形区域

#### Scenario: 玻璃拟态样式

- **WHEN** 额度提示可见
- **THEN** 背景 SHALL 使用半透明 + 模糊（`BackdropFilter` 或等价玻璃 token）
- **AND** 文字 SHALL 保持可读对比度

#### Scenario: 无额度数据不占位

- **WHEN** `voiceAiQuotaProvider` 无数据或 `limit <= 0`
- **THEN** UI SHALL NOT 为额度提示保留空白占位

#### Scenario: 语音面板无纵向溢出

- **WHEN** 语音模式下额度提示与语音球同时展示
- **THEN** 底部输入面板 SHALL NOT 出现 `RenderFlex overflow`
- **AND** 语音球 SHALL 在额度条上方居中，额度条贴面板底缘内侧
