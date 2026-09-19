## ADDED Requirements

### Requirement: Asking phase SHALL offer restart of the whole trajectory session

While the growth-trajectory workspace is asking the user a question, the client SHALL show a「重新预测」control. Activating it MUST start a new session via the existing restart turn (`action=restart` with an empty `sessionId`) and MUST NOT resume or edit the in-progress question. The client MUST NOT show this control while a turn stream is in flight. The client MUST NOT increment a local daily-usage counter because of this restart. 提问阶段客户端 **必须** 展示「重新预测」；点击 **必须** 以空 `sessionId` 的既有 restart 整轮重开，**不得** 回到上一题或修改已提交答案。思考流进行中 **不得** 展示该控件。客户端 **不得** 因这次重开而本地计日次。

#### Scenario: 提问中可以整轮重来

- **WHEN** 成长轨迹处于向用户提问并等待作答，且用户已开通
- **THEN** 页面 MUST 展示「重新预测」
- **AND** 该控件 MUST NOT 位于选项按钮组内部

#### Scenario: 点击后进入新一轮思考

- **WHEN** 用户在提问阶段点击「重新预测」且服务端未拒绝
- **THEN** 客户端 MUST 以 restart、空 sessionId 发起新一轮
- **AND** MUST 隐藏当前题目并进入流式思考
- **AND** MUST NOT 把本次点击计为本地日限消耗

#### Scenario: 思考中不提供重开

- **WHEN** 成长轨迹处于流式思考且本轮请求尚未结束
- **THEN** 页面 MUST NOT 展示「重新预测」

#### Scenario: 重开失败保留已有结果

- **WHEN** 提问阶段的重新预测失败，且页面上已有上一次结果
- **THEN** 客户端 MUST Toast 服务端或既有失败文案
- **AND** MUST 回到展示该已有结果，而不是空白页
