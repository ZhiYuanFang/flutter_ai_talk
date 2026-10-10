## ADDED Requirements

### Requirement: 开通态查询与四态展示

The client SHALL load Xiaozhi MCP unlock state via `GET /cash/app/api/xiaozhi-mcp/unlock` and MUST render one of four user-visible states from `unlocked`, `trialAvailable`, and `expiresAt`. This flow MUST NOT depend on `GET /cash/app/api/feature/catalog`. 客户端 **必须** 经独立 unlock 接口展示开通四态，**不得**依赖功能开通 catalog。

#### Scenario: 可免费体验

- **WHEN** `unlocked=false` 且 `trialAvailable=true`
- **THEN** 页面 MUST 提示可免费体验约 24 小时，并允许在资格满足时发起添加
- **AND** MUST 同时提供永久开通入口（若返回可售 product）

#### Scenario: 体验进行中

- **WHEN** `unlocked=true` 且 `expiresAt>0`
- **THEN** 页面 MUST 展示体验中及到期相关文案
- **AND** MUST 允许添加绑定并提供永久开通入口（若可售）

#### Scenario: 已永久开通

- **WHEN** `unlocked=true` 且 `expiresAt` 为 0 或表示永久的约定哨兵
- **THEN** 页面 MUST 展示已永久开通
- **AND** MUST NOT 强制用户再次购买才可管理绑定

#### Scenario: 体验已用完

- **WHEN** `unlocked=false` 且 `trialAvailable=false`
- **THEN** 客户端 MUST 禁用添加绑定，直至用户成功永久开通（或服务端再次返回可添加资格）
- **AND** MUST 引导用户走永久开通支付（若 SKU 可售）

### Requirement: 试用在首次添加时开始且须确认

The client MUST NOT call a separate App「claim trial」API. When `trialAvailable` is true and the user is about to add the first binding that would start the trial, the client MUST show a confirmation that adding will start the one-time 24-hour trial. When the user is already `unlocked`, that confirmation MUST be skipped. 客户端 **不得** 调用独立领取试用接口；试用可用且即将添加触发体验时 **必须** 二次确认；已开通则跳过。

#### Scenario: 试用可用时确认

- **WHEN** `trialAvailable=true` 且用户确认提交添加表单
- **THEN** 客户端 MUST 先展示「将开始 24 小时免费体验、每账号一次」类确认
- **AND** 用户取消则 MUST NOT 发出 POST bindings

#### Scenario: 已开通跳过确认

- **WHEN** `unlocked=true` 且用户提交添加
- **THEN** 客户端 MUST NOT 再弹出试用开始确认

### Requirement: 永久开通支付走独立建单

The client SHALL create permanent unlock orders via `POST /cash/app/api/xiaozhi-mcp/orders` with channel `alipay` or `apple_iap`, following the same platform split as other App commerce (Android Alipay; iOS StoreKit with existing Apple verify path). The MCP SKU MUST NOT appear in the feature unlock hub catalog as a managed feature tile. 永久开通 **必须** 走 MCP 专用建单；**不得** 作为开通功能管理 catalog 瓷砖出现。

#### Scenario: Android 支付宝开通

- **WHEN** Android 用户在可售状态下选择永久开通且已安装支付宝
- **THEN** 客户端 MUST 以 `alipay` 建单并调起支付串
- **AND** 支付成功后 MUST 刷新 unlock 态

#### Scenario: iOS Apple 开通

- **WHEN** iOS 用户在可售状态下选择永久开通且 SKU 含有效 `appleProductId`
- **THEN** 客户端 MUST 以 `apple_iap` 建单并走 StoreKit 购买与既有验单路径
- **AND** 成功后 MUST 刷新 unlock 态

#### Scenario: 不进入功能开通 catalog

- **WHEN** 用户打开「功能开通」中心
- **THEN** 客户端 MUST NOT 因本变更而把小智 MCP 永久 SKU 列为 catalog 功能项
