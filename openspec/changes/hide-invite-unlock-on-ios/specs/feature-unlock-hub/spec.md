## MODIFIED Requirements

### Requirement: Unlock hub SHALL omit ad unlock and honor inviteAvailable and trialAvailable
The feature unlock hub SHALL NOT show「看广告」actions. Invite unlock CTAs MUST appear only when the catalog item’s effective invite support is true: `unlockMethods` contains `invite_code`, `inviteAvailable` is true, **and** the runtime is not the native iOS App (`!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS` MUST force invite CTAs hidden regardless of catalog). Free-trial CTAs MUST follow `feature-free-trial` rules and sit as the rightmost button when shown. Payment CTAs MUST remain for locked pay-capable features. 开通中心 **不得** 看广告；邀请按钮须同时满足 catalog 邀请通道与 **非原生 iOS**；体验按钮受 `trialAvailable` 约束。

#### Scenario: No ad button
- **WHEN** 用户打开功能开通页查看未开通 care 或 growth 卡
- **THEN** MUST NOT 出现「看广告」按钮

#### Scenario: Invite hidden after used
- **WHEN** 该项 `inviteAvailable` 为 false
- **THEN** 该卡 MUST NOT 展示邀请码开通按钮

#### Scenario: Invite hidden on native iOS even when catalog allows
- **WHEN** 运行于原生 iOS App，且该项 `unlockMethods` 含 `invite_code` 且 `inviteAvailable` 为 true
- **THEN** 该卡 MUST NOT 展示邀请码开通按钮

#### Scenario: Invite shown on Android when catalog allows
- **WHEN** 运行于 Android App，且该项 `unlockMethods` 含 `invite_code` 且 `inviteAvailable` 为 true 且功能未有效开通
- **THEN** 该卡 MUST 展示邀请码开通按钮

#### Scenario: Invite shown on Web when catalog allows
- **WHEN** 运行于 Web（含 iPhone Safari），且该项 `unlockMethods` 含 `invite_code` 且 `inviteAvailable` 为 true 且功能未有效开通
- **THEN** 该卡 MUST 展示邀请码开通按钮

#### Scenario: Trial on the right
- **WHEN** `trialAvailable` 为 true 且未开通
- **THEN**「免费体验」MUST 在该卡按钮行最右侧

## ADDED Requirements

### Requirement: Client supportsInviteCode SHALL gate native iOS invite unlock
The Flutter client SHALL compute effective invite unlock support via `FeatureCatalogItem.supportsInviteCode` such that it is false on the native iOS App even when catalog lists `invite_code` and `inviteAvailable` is true. On Android and Web the getter MUST continue to require `invite_code` in `unlockMethods` and `inviteAvailable == true`. UI that offers invite unlock MUST use this getter (or equivalent) and MUST NOT bypass it with raw catalog fields alone. 客户端 **必须** 在 `supportsInviteCode`（或等价）上对原生 iOS 强制关闭邀请开通；Android/Web 仍认 catalog；UI **不得** 绕过该闸门。

#### Scenario: Getter false on native iOS
- **WHEN** 原生 iOS App 解析到含 `invite_code` 且 `inviteAvailable=true` 的 catalog 项
- **THEN** `supportsInviteCode` MUST 为 false

#### Scenario: Getter true on Android with catalog allow
- **WHEN** Android App 解析到含 `invite_code` 且 `inviteAvailable=true` 的 catalog 项
- **THEN** `supportsInviteCode` MUST 为 true
