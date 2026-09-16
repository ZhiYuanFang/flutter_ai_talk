## ADDED Requirements

### Requirement: Unlock hub SHALL omit ad unlock and honor inviteAvailable and trialAvailable
The feature unlock hub SHALL NOT show「看广告」actions. Invite unlock CTAs MUST appear only when `inviteAvailable` is true. Free-trial CTAs MUST follow `feature-free-trial` rules and sit as the rightmost button when shown. Payment CTAs MUST remain for locked pay-capable features. 开通中心 **不得** 看广告；邀请/体验按钮分别受 `inviteAvailable`/`trialAvailable` 约束。

#### Scenario: No ad button
- **WHEN** 用户打开功能开通页查看未开通 care 或 growth 卡
- **THEN** MUST NOT 出现「看广告」按钮

#### Scenario: Invite hidden after used
- **WHEN** 该项 `inviteAvailable` 为 false
- **THEN** 该卡 MUST NOT 展示邀请码开通按钮

#### Scenario: Trial on the right
- **WHEN** `trialAvailable` 为 true 且未开通
- **THEN**「免费体验」MUST 在该卡按钮行最右侧

### Requirement: Prediction unlock card SHALL not be offered
The unlock hub MUST NOT offer an active `prediction_unlock` slot product card for purchase or invite. 开通中心 **不得** 再提供预测槽位开通商品卡。

#### Scenario: No slot product
- **WHEN** catalog 不再下发或客户端过滤 `prediction_unlock`
- **THEN** 开通中心列表 MUST NOT 展示可购买/可邀请的预测槽位开通卡
