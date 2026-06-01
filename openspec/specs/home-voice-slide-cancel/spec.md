## ADDED Requirements

### Requirement: 滑出语音圆取消发送

The system SHALL treat pointer release as cancel (no sendCommand) when the user held to speak but the finger was outside the voice orb circle at release, and SHALL treat release inside the circle as the normal end-of-utterance path. 系统必须在用户**按住说话**时，以主页**语音圆**（约 132px 圆形按钮区域）为界：松手时若指针在**圆外**，必须**取消**本次采集（调用 `cancelSession`），**不得**向服务端发送指令文本；松手时若指针在**圆内**，必须保持现有结束并发送（若有识别结果）的行为。

#### Scenario: 滑出圆外后松手取消

- **WHEN** 用户已在语音圆上按下并开始采集，随后将手指移出语音圆外并在圆外松手
- **THEN** 系统必须结束采集且不得调用 `sendCommand`

#### Scenario: 未滑出圆内松手发送

- **WHEN** 用户按住说话并在语音圆内松手且识别结果非空
- **THEN** 系统必须按现有逻辑提交识别文本（`sendCommand`）

### Requirement: 滑回圆内恢复发送态

The system MUST allow the user to move the finger back inside the voice orb while still holding, restoring the send-on-release state before release. 用户在**未松手**的情况下将手指**移回语音圆内**时，系统必须恢复为「松手可正常结束/发送」的状态（不得仍停留在仅可取消的状态）。

#### Scenario: 移出后移回圆内

- **WHEN** 用户先将手指移出语音圆（取消态），再在仍按住时移回圆内
- **THEN** 界面必须恢复为圆内发送态提示（如「松开结束」），且在该状态下松手必须按发送路径处理（有文本时）

### Requirement: 取消态反馈

The system SHALL provide distinct UI feedback while the finger is outside the voice orb during an active hold. 手指在圆外且仍处于按住流程时，系统必须提供与圆内不同的可见反馈（如文案「松开取消」及区别于正常的边框/颜色）。

#### Scenario: 圆外按住中的提示

- **WHEN** 用户正在按住说话且指针位于语音圆外
- **THEN** 主按钮文案必须表明松手将取消（不得仍仅显示「松开结束」）
