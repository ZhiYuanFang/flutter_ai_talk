## ADDED Requirements

### Requirement: Unlock hub SHALL list predict capability basic and pro from catalog

The feature unlock hub SHALL render catalog items for `predict_capability_basic` and `predict_capability_pro` when present (including status/下架 rules already applied to catalog). Basic locked cards MUST offer payment and invite CTAs per existing unlockMethods / inviteAvailable rules, and free-trial when `trialAvailable` per predict click-start rules.

开通中心 MUST 展示预测基础版与 Pro catalog 项；基础版 MUST 可支付/邀请/点试用（在资格允许时）。

#### Scenario: 基础版支付

- **WHEN** basic 未开通且 products 非空且 unlockMethods 含 payment
- **THEN** 开通卡 MUST 可发起既有功能建单支付流

### Requirement: Pro unlock and trial CTAs SHALL report not launched

While Pro server-side customized prediction is not product-launched, tapping Pro payment, invite redeem, or free-trial actions on the unlock hub MUST show a user-visible message that the feature is not yet available (e.g.「功能尚未上线」) and MUST NOT create a feature order, redeem an invite code, or call trial/start for `predict_capability_pro`.

Pro 开通/试用点击 MUST 提示尚未上线，MUST NOT 建单/兑码/trial/start。

#### Scenario: 点 Pro 试用

- **WHEN** 用户点击 Pro 卡「免费体验」或等价开通按钮
- **THEN** 客户端 MUST 提示功能尚未上线
- **AND** MUST NOT 调用 trial/start 或 feature/orders
