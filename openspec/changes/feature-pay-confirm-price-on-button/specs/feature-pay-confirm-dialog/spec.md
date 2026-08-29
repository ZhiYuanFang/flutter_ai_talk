## ADDED Requirements

### Requirement: Feature pay confirm shows price beside confirm action
When the user confirms a feature payment from the unlock hub, the client SHALL present a glass confirm dialog via payment-specific `showGlassDialog` (MUST NOT rely on string-only `showGlassConfirmDialog` confirmLabel for this layout). The primary confirm control MUST show the action label「去支付」(or Web「仅 App 可支付」) with the price as smaller text in parentheses immediately to its right, using `¥…/个` for `prediction_unlock` and `¥…` otherwise. The dialog body MUST describe the grant effect and MUST NOT repeat a separate「价格：」line. 开通中心支付确认须用支付专用玻璃弹窗；确认键为「去支付」+ 右侧小字括号价；正文不得再写独立「价格：」行。

#### Scenario: Prediction per-unit confirm
- **WHEN** the user opens pay confirm for `prediction_unlock` with a product price
- **THEN** the confirm button shows「去支付」and a smaller ` (¥{price}/个)` to its right, and the message does not contain「价格：」

#### Scenario: Non-prediction confirm
- **WHEN** the user opens pay confirm for a non-prediction feature
- **THEN** the confirm button shows「去支付」and a smaller ` (¥{price})` to its right

#### Scenario: Web blocks real pay
- **WHEN** the platform is Web and the user confirms
- **THEN** the dialog may show「仅 App 可支付」with the parenthetical price, and the client MUST NOT start a real purchase after confirm
