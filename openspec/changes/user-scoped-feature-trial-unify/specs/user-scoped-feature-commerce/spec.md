## ADDED Requirements

### Requirement: Commercial features SHALL be user-scoped timed entitlements
For `care_alert_smart_remind` and `growth_trajectory_predict`, activation and access checks SHALL use user-scoped entitlements (`wx_id`). Payment unlock MUST grant **30 days**. Invite unlock MUST grant **7 days**. Ad unlock MUST NOT be offered or fulfilled. 商业功能 **必须** 用户维；支付 30 天；邀请 7 天；**不得** 广告开通。

#### Scenario: Pay grants 30 days
- **WHEN** 用户支付成功开通 care 或 growth
- **THEN** 用户权益到期时间 MUST 为开通生效起点起 30 天（按既有续期公式）

#### Scenario: Invite grants 7 days
- **WHEN** 用户邀请码成功开通 care 或 growth
- **THEN** 用户权益 MUST 为 7 天期限

#### Scenario: Ad path removed
- **WHEN** 客户端开通中心渲染未开通功能卡
- **THEN** MUST NOT 展示「看广告」；服务端 MUST NOT 再通过 ad 渠道 ActivateFeature 成功履约（或该渠道不可用）

### Requirement: Catalog SHALL expose inviteAvailable and hide invite CTA when false
The catalog SHALL expose `inviteAvailable` per feature. It MUST be false after the account has successfully redeemed any invite code for that feature once (`InviteOncePerUser`). The client MUST NOT show invite unlock buttons when `inviteAvailable` is false. 人×功能邀请成功一次后 `inviteAvailable` **必须** 为 false，客户端 **不得** 展示邀请开通入口。

#### Scenario: First invite ok
- **WHEN** 用户从未用邀请开通该功能且 unlock_methods 含 invite_code
- **THEN** `inviteAvailable` MUST 为 true，客户端可展示邀请入口

#### Scenario: Second invite hidden
- **WHEN** 用户已成功用任意邀请码开通过该功能
- **THEN** `inviteAvailable` MUST 为 false，开通中心与相关弹窗 MUST NOT 展示邀请开通按钮

### Requirement: Invite redeem SHALL drop same-baby and per-device once rules
Invite redemption SHALL reject self-codes and repeat person×code×feature use, and SHALL enforce person×feature invite-once. It MUST NOT reject solely because redeemer and owner share the same baby `device_no`, and MUST NOT enforce `InviteOncePerDevice`. 邀请 **必须** 去掉同宝宝与设备一次限制，保留自用禁止与人×功能一次。

#### Scenario: Same baby different accounts allowed
- **WHEN** 兑换人与码主人当前宝宝 device_no 相同但 wx_id 不同，且该兑换人未用过该功能邀请
- **THEN** 兑换 MUST 允许（在其它规则满足时）

#### Scenario: Self code rejected
- **WHEN** 用户兑换自己的邀请码
- **THEN** MUST 拒绝

### Requirement: Care analysis daily quota SHALL match growth user-day refresh
Care smart analysis SHALL allow at most **5** successful generations per user per Shanghai calendar day, and each successful request MUST refresh the stored latest result (no baby-day cache short-circuit that skips regeneration). Growth MUST keep the same user-day limit semantics. 值得留意 **必须** 改为用户日最多 5 次且每次刷新。

#### Scenario: Fifth success allowed sixth blocked
- **WHEN** 同一用户当日已成功生成 care 分析 5 次
- **THEN** 第 6 次 MUST 被拒绝（或返回日限错误）；客户端 MUST Toast 提示

#### Scenario: Enter detail loads cache without consuming quota
- **WHEN** 用户进入 care 或 growth 详情
- **THEN** 客户端/服务端 MUST 加载该用户该宝宝最新缓存（若有）且 MUST NOT 因此消耗日额度

### Requirement: Latest results SHALL be keyed by user and baby
Persisted latest care-alert and growth-trajectory results SHALL be stored and loaded by `(wx_id, device_no)` so users are isolated. 最新结果 **必须** 按用户+宝宝隔离。

#### Scenario: Two parents isolated
- **WHEN** 家长 A 与家长 B 绑定同一 device_no 且各自生成成功
- **THEN** 各自进入详情 MUST 只看到自己的最新结果

### Requirement: Prediction slot commerce SHALL be removed
The system SHALL NOT gate smart-prediction events by `prediction_unlock` allowed counts. Catalog MUST NOT present prediction slot purchase/invite as an active unlock product in the hub. Client slot-lock overlays and slot-full invite dialogs MUST be removed. 预测槽位开通能力 **必须** 删除。

#### Scenario: Prediction events not slot-locked
- **WHEN** 已登录用户打开智能预测页且非演示锁场景
- **THEN** 真实预测事项 MUST NOT 因 allowedCount 槽位不足而显示开通锁或满额邀码闸
