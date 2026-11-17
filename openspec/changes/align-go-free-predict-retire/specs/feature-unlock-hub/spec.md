## MODIFIED Requirements

### Requirement: Unlock hub bottom SHALL open VIP purchase for unlock-all of catalog features

The unlock hub MUST NOT show「开通月卡解锁所有功能」and MUST NOT navigate to a VIP purchase page for unlock-all. Catalog features that remain sellable MUST unlock via their own payment / invite / trial methods only. 开通中心 **不得** 再提供月卡解锁全部功能入口，也 **不得** 导航至 VIP 购买页。

#### Scenario: 无底部月卡入口

- **WHEN** 用户打开功能开通中心
- **THEN** 页面 MUST NOT 展示「开通月卡解锁所有功能」
- **AND** MUST NOT 提供进入 `/vip/purchase`（或等价 VIP 购页）的底部入口

### Requirement: Opened care-alert and growth cards SHALL navigate to detail subpages

The unlock hub MUST NOT list or navigate to retired `care_alert_smart_remind` or `growth_trajectory_predict` detail subpages. Whole-card navigation to `/prediction/ai-analysis/feeding` or `/prediction/ai-analysis/growth` MUST NOT be offered. 开通中心 **不得** 再展示或导航至已退休的 care-alert / 成长轨迹详情。

#### Scenario: 无 care/growth 详情导航

- **WHEN** 用户打开功能开通中心
- **THEN** 客户端 MUST NOT 因整卡点击进入 `/prediction/ai-analysis/feeding` 或 `/prediction/ai-analysis/growth`

## ADDED Requirements

### Requirement: Unlock hub SHALL list predict Pro shell without basic or VIP sticky

The feature unlock hub SHALL render catalog item `predict_capability_pro` when present (including status/下架 rules). The hub MUST NOT render a commercial card for `predict_capability_basic`, MUST NOT show VIP sticky / VIP validity chrome, and MUST NOT require care-alert feeding eligibility loads for removed care rows. Pro CTAs MUST respect Go eligibility (`predict-pro/eligibility`) and catalog trial/payment fields; while Pro product is not sellable, CTAs MUST show not-launched or server message without creating invalid orders.

开通中心 MUST 展示 Pro 壳、MUST NOT 展示 basic 商业卡与 VIP sticky；Pro CTA MUST 尊重 eligibility；care eligibility 预热 MUST NOT 为已删行保留。

#### Scenario: 有 Pro 无 basic

- **WHEN** catalog 含 `predict_capability_pro` 且不含 basic
- **THEN** hub MUST 可展示 Pro 卡
- **AND** MUST NOT 渲染 basic 预测能力卡

#### Scenario: 无 VIP sticky

- **WHEN** 用户打开开通中心
- **THEN** MUST NOT 显示月卡 VIP sticky 或倒计时 VIP 条
