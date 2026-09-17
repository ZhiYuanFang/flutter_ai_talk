## ADDED Requirements

### Requirement: Feeding and growth workspaces SHALL place primary CTA below body with shared usage copy

On both the feeding-analysis workspace and the growth-trajectory workspace, the primary analyze/predict control（「AI智能分析」/「轨迹预测」/「重新预测」）SHALL be rendered below the main body content and horizontally centered, and MUST NOT live in the AppBar trailing actions. Directly under that control, when the user can use the capability, the client MUST show usage copy in the form `今日已用 {used}/{limit} 次` (or equivalent with the same numbers). 喂养与成长工作台主 CTA **必须** 在正文下方居中，**不得** 放在 AppBar；可使用时 CTA 下 **必须** 展示「今日已用 x/y 次」。

#### Scenario: 成长 CTA 在正文下

- **WHEN** 用户打开已开通的成长轨迹工作台且未在 streaming/asking
- **THEN** AppBar MUST NOT 展示轨迹预测/重新预测按钮
- **AND** 正文下方 MUST 展示该按钮及「今日已用 x/y 次」

#### Scenario: 喂养用量为服务端已用/上限

- **WHEN** 喂养工作台已拿到 care-alert daily（或等价）返回的 `usedToday` 与 `dailyLimit`
- **THEN** CTA 下方 MUST 展示「今日已用 {usedToday}/{dailyLimit} 次」
- **AND** MUST NOT 仅展示不含已用次数的「每日最多 N 次」固定句作为唯一用量提示

#### Scenario: 思考/提问中隐藏主 CTA

- **WHEN** 成长回合 streaming 或 asking，或喂养分析思考流进行中
- **THEN** 正文下主 CTA MUST 隐藏或不可再点并发第二轮（与防重入一致）
