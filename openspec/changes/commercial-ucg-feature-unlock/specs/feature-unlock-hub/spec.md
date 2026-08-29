## ADDED Requirements

### Requirement: Unlock hub SHALL list catalog features with configured unlock methods

The client MUST provide a glass-morphism「开通更多功能 / 开通中心」page whose feature list comes from `GET /cash/app/api/feature/catalog`. For each locked feature, the client MUST offer unlock methods present in that item’s `unlockMethods` comma-separated string among `payment`, `ad`, and `invite_code`. Each method dialog MUST show unlock duration when available (`products[].durationDays` for payment; 0 or missing → 永久). The invite-code dialog MUST include the hint「可向群主获取免费激活码」and MUST redeem via `POST /cash/app/api/feature/invite-codes/redeem` with `{ code, featureId }` for the current row. Confirming the ad dialog MUST be treated as watched and MUST `POST /cash/app/api/feature/ad/complete` with `{ featureId }` (optional `idempotencyKey`). Payment MUST use a `productCode` from that feature’s catalog `products[]` and `POST /cash/app/api/feature/orders` with `{ productCode, channel }`, then complete pay/verify via the existing cash stack. The client MUST NOT hard-code operational product codes when catalog returns products, and MUST NOT call Admin product APIs.

客户端 **必须** 提供玻璃拟态开通中心，列表来自 feature/catalog（含 `products[]`）；按 `unlockMethods` 提供 payment / ad / invite_code；支付 **必须** 用同项 `products` 的 `productCode` 建单；弹窗展示时长；邀请码弹窗 **必须** 含指定 hint 且 redeem 带 `featureId`；广告确认 **必须** POST ad-complete。

#### Scenario: 按 unlockMethods 展示开通方式

- **WHEN** 某功能 `unlockMethods` 含 `payment,invite_code,ad` 且 `products` 非空
- **THEN** 锁定卡片 MUST 提供支付、看广告、邀请码（激活码）入口

#### Scenario: products 为空时不展示可支付

- **WHEN** `unlockMethods` 含 `payment` 但 `products` 为空
- **THEN** 客户端 MUST NOT 展示可完成的支付开通入口（或展示不可用态），MUST NOT 硬编码 productCode

#### Scenario: 邀请码提示与兑码

- **WHEN** 用户打开邀请码开通对话框并提交码
- **THEN** 对话框 MUST 展示「可向群主获取免费激活码」
- **AND** 客户端 MUST 调用 invite-codes/redeem 且 body 含该功能 `featureId`

#### Scenario: 广告确认即完成

- **WHEN** 用户在广告开通对话框点击确认
- **THEN** 客户端 MUST 调用 ad/complete（携带 featureId）
- **AND** 成功后 MUST 刷新 catalog 并更新列表态

#### Scenario: 支付走功能建单

- **WHEN** 用户选择支付开通且该功能 `products` 含非空 `productCode`
- **THEN** 客户端 MUST 使用所选 `productCode` POST feature/orders 并拉起平台支付
- **AND** MUST NOT 仅本地假开通
- **AND** MUST NOT 调用 Admin products API

### Requirement: Unlocked feature cards SHALL show method and hide unlock CTAs

When a feature is effectively unlocked (`catalog.unlocked || isVip`), the unlock hub card MUST show「已开通」and a human-readable unlock method label, and MUST hide payment / ad / invite-code CTAs. Method labels MUST map: `payment`→支付开通, `ad`→看广告, `invite_code`→激活码, `vip`→月卡. If unlocked only via `isVip` without catalog unlockMethod, the displayed method MUST be「月卡」.

功能有效开通后 **必须** 展示「已开通」与开通方式并隐藏 CTA；仅 VIP 覆盖时方式 **必须** 为「月卡」。

#### Scenario: 设备权益已开通

- **WHEN** catalog 项 `unlocked=true` 且 `unlockMethod=payment`
- **THEN** 卡片 MUST 显示「已开通」与支付开通类文案
- **AND** MUST NOT 显示开通按钮

#### Scenario: 仅 VIP 覆盖

- **WHEN** 某功能 catalog `unlocked=false` 但 `isVip` 为 true
- **THEN** 卡片 MUST 显示「已开通」且开通方式为「月卡」
- **AND** MUST NOT 显示开通 CTA

### Requirement: Unlock hub bottom SHALL open VIP purchase for unlock-all of catalog features

The unlock hub MUST show「开通月卡解锁所有功能」navigating to the existing VIP purchase page. The VIP purchase page MUST list more-features included with the monthly card from **catalog titles** (UCG eligibility MUST NOT appear as a VIP-included catalog row).

开通中心底部 **必须** 进 VIP 购买页；VIP 页 **必须** 列出 catalog 标题作为月卡包含功能（不含 UCG 资格项）。

#### Scenario: 底部进 VIP

- **WHEN** 用户点击「开通月卡解锁所有功能」
- **THEN** 客户端 MUST 导航至 `/vip/purchase`（或现有 VIP 购买路由）

#### Scenario: VIP 页列出包含功能

- **WHEN** 用户打开 VIP 购买页且 catalog 返回至少一个功能标题
- **THEN** 页面 MUST 展示这些标题作为月卡包含的更多功能
