## ADDED Requirements

### Requirement: Cash client SHALL support per-feature SKU purchase via feature orders API

In addition to the monthly VIP product path (`/cash/app/api/vip/*`), the client MUST support creating feature orders via `POST /cash/app/api/feature/orders` with `{ productCode, channel }` where `channel` is `alipay` or `apple_iap`. The `productCode` and display prices MUST come from the same feature’s `products[]` on `GET /cash/app/api/feature/catalog`. After pay/verify succeeds, the client MUST refresh feature/catalog for the current device session. The client MUST NOT invent local prices when catalog returns `priceFen`, MUST NOT hard-code operational product codes when products are present, and MUST NOT call Admin product APIs. VIP purchase MUST continue to use VIP endpoints; feature purchase MUST NOT be sent as a VIP monthly productCode.

除月卡外，客户端 **必须** 经 `POST /cash/app/api/feature/orders` 建单；`productCode` 与标价 **必须** 来自 catalog 同项 `products[]`；成功后 **必须** 刷新 catalog。接口成功时 **不得** 本地编造价格或硬编码运营码；**不得** 调 Admin products。功能单 **不得** 当作月卡 VIP productCode 下单。

#### Scenario: 功能 SKU 下单

- **WHEN** 用户为某功能发起支付且该功能 catalog `products` 含非空 `productCode` 与 `priceFen`
- **THEN** 客户端 MUST 使用该 `productCode` POST `/cash/app/api/feature/orders` 并拉起平台支付
- **AND** MUST NOT 调用 Admin products API
- **AND** MUST NOT 仅用本地写死价格代替接口价

#### Scenario: 支付成功刷新 catalog

- **WHEN** 功能订单支付/验单成功
- **THEN** 客户端 MUST 刷新当前会话的 feature/catalog（开通中心与预测 `allowedCount` 随之更新）

#### Scenario: 与 VIP 路径隔离

- **WHEN** 用户购买月卡
- **THEN** 客户端 MUST 仍走既有 VIP 建单/验单 API
- **AND** MUST NOT 期望服务端为 VIP 写入 feature_entitlement / allowedCount
