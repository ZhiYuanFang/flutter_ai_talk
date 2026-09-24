## MODIFIED Requirements

### Requirement: Catalog SHALL expose inviteAvailable and hide invite CTA when false
The catalog SHALL expose `inviteAvailable` per feature. It MUST be false after the account has successfully redeemed any invite code for that feature once (`InviteOncePerUser`). The client MUST NOT show invite unlock buttons when `inviteAvailable` is false. Independently, the native iOS App MUST NOT show invite unlock buttons even when `inviteAvailable` is true (see `feature-unlock-hub` platform gate). 人×功能邀请成功一次后 `inviteAvailable` **必须** 为 false；客户端在 `inviteAvailable=false` 时 **不得** 展示邀请开通入口；原生 iOS 另受平台闸门约束。

#### Scenario: First invite ok on non-iOS
- **WHEN** 用户从未用邀请开通该功能且 unlock_methods 含 invite_code，且运行于 Android 或 Web
- **THEN** `inviteAvailable` MUST 为 true，客户端可展示邀请入口

#### Scenario: Second invite hidden
- **WHEN** 用户已成功用任意邀请码开通过该功能
- **THEN** `inviteAvailable` MUST 为 false，开通中心与相关弹窗 MUST NOT 展示邀请开通按钮

#### Scenario: Native iOS hides invite despite inviteAvailable
- **WHEN** `inviteAvailable` 为 true 且 unlock_methods 含 invite_code，但运行于原生 iOS App
- **THEN** 客户端 MUST NOT 展示邀请开通按钮
