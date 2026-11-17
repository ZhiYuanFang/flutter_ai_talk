## ADDED Requirements

### Requirement: Predict capability trial SHALL use seven-day click start not soft claim

For `predict_capability_basic` and `predict_capability_pro`, the client SHALL treat trial as an explicit click-start that calls `POST /cash/app/api/feature/trial/start` and expects about **7 days** of user entitlement from the click moment, per Go contract. The client MUST NOT apply care/growth soft-detail entry or first-successful-generation 24h claim semantics to these two feature ids. Unlock-hub「免费体验」for basic, when shown, MUST confirm then call trial/start (or equivalent) rather than only opening a detail page that soft-claims later. Pro trial CTA MUST follow hub not-launched rules in this change and MUST NOT successfully start trial while Pro is product-gated as not launched.

预测两档试用 MUST 为 7 日点试用；MUST NOT 套用 care/growth soft+24h；基础版免费体验 MUST 点试用；Pro 本轮未上线 MUST NOT 成功领取。

#### Scenario: 基础版免费体验点试用

- **WHEN** 开通中心 basic 卡 `trialAvailable=true` 且用户确认免费体验
- **THEN** 客户端 MUST 调用 trial/start(featureId=predict_capability_basic)
- **AND** MUST NOT 仅进入某详情页而不领取

#### Scenario: care 语义不变

- **WHEN** 用户对 care_alert_smart_remind 使用免费体验
- **THEN** MUST 仍走既有 soft 进详情与首次成功 claim 24h 路径
