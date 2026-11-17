## MODIFIED Requirements

### Requirement: Feature catalog SHALL be the sole App read model for unlock state

The client MUST load commercial feature state from `GET /cash/app/api/feature/catalog` (login + bound device session). The client MUST NOT call a dedicated App `entitlements` or `allowed-count` endpoint as the primary read path. Each catalog item MUST be modeled with at least: `featureId`, `title`, `description`, `unlockMethods` (comma-separated string), `unlocked`, optional `unlockMethod`, optional `expiresAt`, optional `allowedCount`, and `products` (array, possibly empty) of App-sellable SKUs with `productCode`, `priceFen`, `originalPriceFen`, `durationDays`, `grantKind`, `grantQuantity`, optional `appleProductId`. Cache MUST be keyed by current `deviceNo`. Effective unlock for a **catalog** feature MUST be time-valid `item.unlocked` (respecting `expiresAt`); the client MUST NOT OR `isVip` into effective unlock. The client MUST NOT treat VIP status as unlocking all catalog features or prediction locks. TTL MUST be permanent when `expiresAt` is missing or zero. Settings/hub summary MUST use catalog (and remaining non-VIP commercial status APIs as applicable) without requiring `vip/status`. The client MUST NOT treat UCG entry as a catalog feature.

商业权益主读模型 **必须** 为 feature/catalog；有效开通 **必须** 为时间有效 `unlocked`，**不得** `|| isVip`；**不得** 用 VIP 全开目录或预测锁；UCG **不得** 当作 catalog 项。

#### Scenario: deviceNo 键控

- **WHEN** 用户切换宝宝导致 `deviceNo` 变化
- **THEN** 客户端 MUST 读取新 deviceNo 对应的 catalog 缓存/接口

#### Scenario: unlocked false 即未开通

- **WHEN** 某 catalog 项 `unlocked=false`
- **THEN** 开通中心该项 MUST 视为未开通
- **AND** MUST NOT 因任何 VIP 缓存将其视为已开通

#### Scenario: isVip 不覆盖 UCG 入场

- **WHEN** UCG eligibility `qualified=false`
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
- **THEN** 客户端 MUST 使用 feature/catalog 作为主读模型
- **AND** MUST NOT 依赖专用 summary 或独立 entitlements 列表 API 才能渲染
- **AND** MUST NOT 依赖 `vip/status` 才能渲染 catalog 开通态

### Requirement: Effective unlock side-effect paths SHALL await VIP settlement

Side-effect ensure or automatic refresh paths that branch on catalog effective unlock MUST use time-valid catalog `unlocked` only and MUST NOT await VIP settlement or treat loading VIP as `isVip=false` for unlock decisions. The client MUST NOT introduce per-screen VIP settlement protocols for feature gates. Prediction display MUST NOT be entitlement-gated on VIP or basic.

副作用门闸 MUST 仅看 catalog 时间有效 unlocked；MUST NOT await VIP settle；预测展示 MUST NOT 再按 VIP/basic entitlement 门闸。

#### Scenario: unlocked false 不因 VIP 放行

- **WHEN** 某 catalog 项 `unlocked=false` 且副作用 ensure 运行
- **THEN** 路径 MUST 将该项视为未开通
- **AND** MUST NOT 等待或查询 VIP status 来改写该结论

#### Scenario: 预测展示无 VIP settle

- **WHEN** 智能预测页渲染亲和预测或亲和进度
- **THEN** 客户端 MUST NOT 为展示门闸 await VIP settlement

### Requirement: Client entitlement helpers SHALL prefer user-scoped catalog fields

Client feature entitlement helpers SHALL treat remaining catalog features as unlocked from time-valid catalog `unlocked` and MUST consume `trialAvailable` and `inviteAvailable` for CTA visibility where those features still exist. They MUST NOT depend on VIP overlay, device-scoped care entitlement rows, or `prediction_unlock.allowedCount` for commercial gating. Helpers MUST NOT require care-alert or growth feature ids after those surfaces are retired.

客户端权益辅助 MUST 以 catalog 时间有效 unlocked 为准；MUST NOT 依赖 VIP 覆盖、care 设备权益或预测槽位；退休 care/growth id MUST NOT 再作为必选门闸。

#### Scenario: Trial CTA uses trialAvailable

- **WHEN** 仍存活的 catalog 项 `trialAvailable=true` 且产品允许试用
- **THEN** 开通 CTA MUST 可展示免费体验（按该功能既有规则）

#### Scenario: 无 VIP 合成

- **WHEN** 调用 `isFeatureEffectivelyUnlocked` 或等价 helper
- **THEN** 结果 MUST NOT 因 isVip 变为 true

## ADDED Requirements

### Requirement: Client SHALL recognize predict Pro catalog id without basic commercial path

The client SHALL recognize feature id `predict_capability_pro` from catalog. The client MUST NOT require `predict_capability_basic` for prediction chrome, trial, or entitlement helpers. Free-tier prediction MUST NOT be modeled as a catalog unlock. Predict display MUST NOT use a `basic∨pro∨VIP` entitlement helper.

客户端 MUST 识别 Pro catalog id；MUST NOT 依赖 basic 商业路径；免费预测 MUST NOT 建模为 catalog 开通；MUST NOT 再使用 basic∨pro∨VIP 展示覆盖 helper。

#### Scenario: 无 basic 常量路径

- **WHEN** 代码路径计算预测是否可展示
- **THEN** MUST NOT 读取 `predict_capability_basic` 的 unlocked 作为展示前提
- **AND** 亲和 nextAt / 进度 MUST 在未购 Pro 时仍可用
