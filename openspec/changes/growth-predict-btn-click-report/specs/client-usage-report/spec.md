## ADDED Requirements

### Requirement: Growth predict button clicks MUST report on tap

When a logged-in user taps the growth-trajectory workspace primary button labeled「轨迹预测」, the client MUST report `growth_predict_btn_click` immediately, including when the tap only opens the unlock dialog because the feature is locked. The description MUST distinguish that locked tap (for example「点击轨迹预测（未开通）」) from a tap that starts prediction. When a logged-in user taps「重新预测」(existing result, or restart during the question step), the client MUST report `growth_predict_restart_click`. These reports MUST be fire-and-forget: the client MUST NOT wait for `startPredict` to succeed, MUST NOT block the unlock dialog, and MUST NOT show a toast if the report fails. The client MUST NOT require a successful prediction before emitting the click report. The feeding-analysis「AI智能分析」button MUST NOT emit these events.

已登录用户点击成长轨迹「轨迹预测」时，客户端 MUST 立即上报 `growth_predict_btn_click`；未开通、只打开开通窗的点击也 MUST 上报，且 description MUST 与真正开始预测区分（例如「点击轨迹预测（未开通）」）。点击「重新预测」时 MUST 上报 `growth_predict_restart_click`。上报 MUST 不等 `startPredict` 成功、不得挡住开通窗、失败不得 toast。喂养「AI智能分析」MUST NOT 使用这两条事件。

#### Scenario: Start prediction click

- **WHEN** 已登录用户在成长轨迹工作台点击「轨迹预测」且该次点击会发起预测
- **THEN** 客户端 MUST 上报 `featureId=growth_predict_btn_click`，description 为「点击轨迹预测」
- **AND** MUST NOT 等待预测接口成功后才上报

#### Scenario: Locked predict click

- **WHEN** 已登录用户点击「轨迹预测」且该次点击只打开开通窗
- **THEN** 客户端 MUST 上报 `featureId=growth_predict_btn_click`，description 标明未开通
- **AND** MUST NOT 改走 `growth_predict_restart_click`

#### Scenario: Restart click

- **WHEN** 已登录用户点击「重新预测」（已有结果，或提问阶段重来）
- **THEN** 客户端 MUST 上报 `featureId=growth_predict_restart_click`，description 为「点击重新预测」
- **AND** 即使随后预测失败也 MUST 已经发出该点击上报

#### Scenario: Feeding analyze button stays unreported

- **WHEN** 用户在喂养记录分析点击「AI智能分析」
- **THEN** 客户端 MUST NOT 上报 `growth_predict_btn_click` 或 `growth_predict_restart_click`
