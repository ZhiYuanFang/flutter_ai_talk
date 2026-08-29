## REMOVED Requirements

### Requirement: VIP purchase route and CTAs SHALL be unreachable while pause gate is active

**Reason**: 商业化重开月卡与功能支付；`kVipPurchaseEnabled` 翻回 true。

**Migration**: 恢复 `/vip/purchase` 可达与开通 CTA；见本文件 ADDED Requirements。

## ADDED Requirements

### Requirement: VIP purchase route and CTAs SHALL be reachable when purchase gate is enabled

When `kVipPurchaseEnabled` is true, the client MUST allow navigation to `/vip/purchase` (deep link and in-app pushes) and MUST present the purchase UI. Unlock hub「开通月卡解锁所有功能」and other product CTAs that target VIP purchase MUST NOT be blocked by the former pause redirect-to-home behavior.

当 `kVipPurchaseEnabled` 为 true 时，`/vip/purchase` **必须** 可达并展示购买 UI；开通中心月卡入口 **不得** 再被暂停期 redirect 拦截。

#### Scenario: 深链可打开购买页

- **WHEN** 购买闸门已翻回且用户打开 `/vip/purchase`
- **THEN** 客户端 MUST 展示 VIP 购买页可支付界面

#### Scenario: 开通中心可进 VIP

- **WHEN** 用户从开通中心点击「开通月卡解锁所有功能」
- **THEN** 客户端 MUST 进入 VIP 购买页而非被重定向离开

### Requirement: VIP purchase page SHALL list included more-features

The VIP purchase page MUST display a list of more-features included with the monthly card, sourced from the commercial feature catalog titles (same catalog as the unlock hub; UCG eligibility MUST NOT appear as a catalog row). The list is informational for VIP benefits and MUST NOT require per-feature device grants to be written on purchase (`isVip` remains the unlock-all override for catalog features and prediction locks only — not UCG entry).

VIP 购买页 **必须** 列出月卡包含的更多功能（catalog 标题，不含 UCG）；购买成功 **不得** 要求回写 per-feature 设备权益（`isVip` 仅覆盖功能目录与预测锁，**不**覆盖 UCG 入场）。

#### Scenario: 购买页展示包含功能

- **WHEN** 用户打开 VIP 购买页且 catalog 返回至少一个功能标题
- **THEN** 页面 MUST 展示这些功能作为月卡包含项

#### Scenario: VIP 不宣称绕过 UCG 门槛

- **WHEN** 用户查看 VIP 购买页权益说明
- **THEN** 客户端 MUST NOT 将 UCG 入场资格表述为月卡直接解锁项（入场仍由 eligibility 决定）
