## ADDED Requirements

### Requirement: Feature catalog SHALL be the sole App read model for unlock state

The client MUST load commercial feature state from `GET /cash/app/api/feature/catalog` (login + bound device session). The client MUST NOT call a dedicated App `entitlements` or `allowed-count` endpoint as the primary read path. Each catalog item MUST be modeled with at least: `featureId`, `title`, `description`, `unlockMethods` (comma-separated string), `unlocked`, optional `unlockMethod`, optional `expiresAt`, optional `allowedCount`, and `products` (array, possibly empty) of App-sellable SKUs with `productCode`, `priceFen`, `originalPriceFen`, `durationDays`, `grantKind`, `grantQuantity`, optional `appleProductId`. Cache MUST be keyed by current `deviceNo`. Effective unlock for a **catalog** feature MUST be `item.unlocked || isVip`. When `isVip` is true, the client MUST treat all catalog features and all prediction event locks as unlocked without requiring per-feature device grants. TTL MUST be permanent when `expiresAt` is missing or zero. Settings/hub summary MUST merge `vip/status` + catalog only. The client MUST NOT treat UCG entry as a catalog feature.

商业权益主读模型 **必须** 为 `GET /cash/app/api/feature/catalog`（含嵌套 `products[]`）；**不得**以独立 entitlements / allowed-count / App products GET 为必调主路径。缓存 **必须** 按 `deviceNo` 键控。目录功能有效开通 = `unlocked || isVip`。`isVip` **必须** 全开目录功能与预测锁且 **不得** 要求回写权益。`expiresAt` 0/缺失 **必须** 视为永久。摘要 **必须** 仅合并 vip/status + catalog。UCG 入场 **不得** 当作 catalog 功能项。

#### Scenario: deviceNo 键控

- **WHEN** 用户切换宝宝导致 `deviceNo` 变化
- **THEN** 客户端 MUST 读取新 deviceNo 对应的 catalog 缓存/接口

#### Scenario: isVip 覆盖功能与预测锁

- **WHEN** `vip/status` 返回 `isVip=true`
- **THEN** 开通中心各 catalog 功能 MUST 视为已开通
- **AND** 预测事件锁 MUST 全部解除
- **AND** MUST NOT 依赖服务端已写入全部 feature grants

#### Scenario: isVip 不覆盖 UCG 入场

- **WHEN** `isVip=true` 且 UCG eligibility `qualified=false`
- **THEN** 客户端 MUST 仍展示 UCG 全屏入场锁（资格由 eligibility API 单独决定）

#### Scenario: 永久 TTL

- **WHEN** 某项 `unlocked=true` 且 `expiresAt` 为 0 或缺失
- **THEN** 客户端 MUST 按永久开通展示

#### Scenario: catalog 含 products

- **WHEN** 某功能存在启用中的功能 SKU
- **THEN** 对应 catalog 项的 `products` MUST 可被客户端解析并用于标价与建单 `productCode`
- **AND** MUST NOT 再请求独立 App products 列表接口

#### Scenario: 无独立 entitlements 主路径

- **WHEN** 设置中心或开通中心需要摘要/列表
- **THEN** 客户端 MUST 使用 vip/status 与 feature/catalog 本地合并
- **AND** MUST NOT 依赖专用 summary 或独立 entitlements 列表 API 才能渲染

### Requirement: Catalog and eligibility refreshes SHALL be cache-first and side-effect governed

Automatic catalog/eligibility refreshes MUST be single-flight, MUST circuit-break on repeated failures, and MUST NOT fire on provider create without session activation or entering the gated surface / unlock hub visibility. The client MUST NOT send `deviceNo` in query/body for these cash App APIs (server trusts gateway internal headers).

catalog / eligibility 自动刷新 **必须** single-flight 与失败熔断；provider 创建 **不得** 无会话激活时自动打 HTTP；**不得** 在 query/body 传 `deviceNo`。

#### Scenario: 进入开通中心再刷新

- **WHEN** 用户打开开通中心
- **THEN** 客户端 MAY 用缓存先渲染并异步刷新 catalog
- **AND** 并发刷新 MUST single-flight
