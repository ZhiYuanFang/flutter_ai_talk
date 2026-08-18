## ADDED Requirements

### Requirement: VIP purchase route and CTAs SHALL be unreachable while pause gate is active

While the temporary VIP purchase pause gate is active, the client MUST NOT present any in-app navigation affordance to the VIP purchase screen (including prediction care-alert fail upsell and care-alert detail CTA). Navigating to `/vip/purchase` (deep link, `context.push`, or equivalent) MUST NOT present the purchase UI; the client MUST redirect away (e.g. to `/home`) or otherwise leave the purchase page unreachable. Existing VIP status read APIs MAY remain; payment SDKs MUST NOT be invoked via this paused purchase entry.

VIP 购买暂停闸门开启时，客户端 **必须 NOT** 提供进入购买页的 UI 入口；打开 `/vip/purchase` **必须 NOT** 展示购买 UI（须 redirect 离开或等价不可达）。VIP 状态只读 MAY 保留；**不得** 经该暂停入口调起支付。

#### Scenario: 深链不可达购买页

- **WHEN** 暂停闸门开启且用户打开 `/vip/purchase`
- **THEN** 客户端 MUST NOT 展示 VIP 购买页可支付界面
- **AND** MUST 离开该路由或回到安全页（如 `/home`）

#### Scenario: 预测页无开通入口

- **WHEN** 暂停闸门开启且 care-alert daily 失败
- **THEN** 预测页 MUST NOT 提供点击进入 `/vip/purchase` 的开通文案行
