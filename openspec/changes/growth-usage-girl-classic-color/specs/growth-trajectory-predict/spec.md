## ADDED Requirements

### Requirement: Unlocked growth trajectory CTA SHALL show account daily usage copy

When growth trajectory is effectively unlocked and the module shows「轨迹预测」or「重新预测」, the client SHALL display secondary text under that control in the form「今日已用 {usedToday}/{dailyLimit} 次」, using values from Go (`latest` and/or successful `result`). The client MUST NOT disable the button solely because usage reached the limit; exhausting the day MUST still allow tap, and the server rejection MUST surface via Toast. 已开通且展示预测 CTA 时 **必须** 在按钮下方显示「今日已用 used/limit 次」；用尽 **不得** 仅因此灰掉按钮，点后超限 **必须** Toast。

#### Scenario: 展示今日已用

- **WHEN** 用户已开通成长轨迹且 CTA 为「轨迹预测」或「重新预测」
- **AND** 服务端已提供 usedToday 与 dailyLimit（例如 2 与 5）
- **THEN** 客户端 MUST 在该按钮下方展示「今日已用 2/5 次」

#### Scenario: 用尽仍可点并 Toast

- **WHEN** usedToday >= dailyLimit
- **AND** 用户点击「重新预测」或「轨迹预测」
- **THEN** 客户端 MUST 仍发起 turn（或不拦截点击）
- **AND** 若 Go 以日限业务错误拒绝 MUST Toast 其 message

### Requirement: Growth trajectory latest and result SHALL expose usedToday and dailyLimit

Go SHALL include integer fields `usedToday` and `dailyLimit` on `GET .../growth-trajectory/latest` data and on successful SSE `result` payloads, reflecting the **account (wxId)** Shanghai-day usage counter and configured daily cap. 成长轨迹 latest 与成功 result **必须** 回传账号维 `usedToday`、`dailyLimit`。

#### Scenario: latest 带回用量

- **WHEN** 已开通用户请求 latest
- **THEN** 响应 data MUST 含 usedToday 与 dailyLimit（非负整数）

### Requirement: Trajectory result Markdown SHALL NOT be a day-by-day schedule

The growth-trajectory generate output SHALL describe the next 7 days as holistic「可能发生什么 / 需要注意什么」(and optional feeding/summary sections) with ample emoji for readability, and MUST NOT structure the primary advice as「第1天…第N天」daily agenda. Fallback templates MUST follow the same rule. 最终 Markdown **必须** 以整段 7 天注意点为主并多用 emoji，**不得** 以按日日程为主要结构。

#### Scenario: 无按日标题

- **WHEN** 智能体产出成长轨迹结果
- **THEN** 正文 MUST NOT 以「第1天」…「第7天」作为主要分节骨架
- **AND** MUST 包含面向「未来7天」的注意/变化类内容并使用 emoji
