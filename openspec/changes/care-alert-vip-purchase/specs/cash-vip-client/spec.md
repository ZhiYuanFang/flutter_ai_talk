## ADDED Requirements

### Requirement: Client SHALL call cash VIP product and status APIs via gateway envelope

The Flutter client MUST request VIP product and status through the App gateway paths `GET /cash/app/api/vip/product` and `GET /cash/app/api/vip/status`, parsing the standard `{ code, message, data }` envelope. Product fields MUST include at least `productCode`, `title`, `priceFen`, `originalPriceFen`, `appleProductId`. Status fields MUST include `isVip` and `expireAt`. The client MUST NOT invent prices locally when the product API succeeds.

客户端 **必须** 经网关拉取 VIP 商品与状态；成功时 **不得** 本地编造价格。

#### Scenario: 商品含划线原价

- **WHEN** product API 返回 `originalPriceFen` 大于 0
- **THEN** 客户端 MUST 将该值作为可选划线原价暴露给 UI 层

#### Scenario: 状态为 VIP

- **WHEN** status API 返回 `isVip` 为 true
- **THEN** 客户端 MUST 将当前账号视为已开通 VIP（直至下次刷新）

### Requirement: Client SHALL create VIP orders with platform channel

When starting payment, the client MUST `POST /cash/app/api/vip/orders` with `productCode` and `channel` of `alipay` or `apple_iap` according to the running platform. On success, Android MUST use `alipayOrderStr` when present; iOS MUST use `appleProductId` and `orderNo` when present.

建单时 channel **必须** 与平台一致，并消费对应支付字段。

#### Scenario: Android 建单

- **WHEN** 用户在 Android 发起开通且建单成功
- **THEN** 响应 data MUST 被解析出 `alipayOrderStr` 供 SDK 调起（若服务端返回）

#### Scenario: iOS 建单

- **WHEN** 用户在 iOS 发起开通且建单成功
- **THEN** 响应 data MUST 被解析出 `appleProductId` 与 `orderNo`

### Requirement: iOS client SHALL verify Apple purchases with the server

After a successful StoreKit purchase, the iOS client MUST `POST /cash/app/api/vip/apple/verify` with `transactionId`, `productId`, and `signedTransaction` when available, and MAY include `orderNo` from the create-order step. After verify succeeds, the client MUST refresh VIP status.

StoreKit 成功后 **必须** 服务端验单并刷新状态。

#### Scenario: 验单成功

- **WHEN** Apple verify API 返回成功
- **THEN** 客户端 MUST 再次拉取 status 且以最新 `isVip` 为准
