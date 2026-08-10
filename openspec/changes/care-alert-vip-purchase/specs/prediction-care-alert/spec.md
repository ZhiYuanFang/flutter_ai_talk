## ADDED Requirements

### Requirement: Care alert detail SHALL show VIP CTA when user is not VIP

On the care-alert detail screen, the client MUST load VIP status. When the user is not VIP (including status load failure treated as non-VIP for CTA visibility), the screen MUST show a floating bottom call-to-action labeled「开通 VIP」. When `isVip` is true, the CTA MUST be hidden. Tapping the CTA MUST navigate to the VIP purchase route.

留意详情在非 VIP 时 **必须** 展示「开通 VIP」悬浮 CTA；VIP **必须** 隐藏；点击 **必须** 进入购买页。

#### Scenario: 非 VIP 见 CTA

- **WHEN** 用户打开留意详情且 status `isVip` 为 false
- **THEN** UI MUST 展示底部「开通 VIP」入口

#### Scenario: VIP 隐藏 CTA

- **WHEN** 用户打开留意详情且 status `isVip` 为 true
- **THEN** UI MUST NOT 展示「开通 VIP」CTA

#### Scenario: 点击开通

- **WHEN** 用户点击「开通 VIP」
- **THEN** 客户端 MUST 导航至 VIP 购买页路由
