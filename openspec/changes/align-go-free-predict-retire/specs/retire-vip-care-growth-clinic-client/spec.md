## ADDED Requirements

### Requirement: Client SHALL remove VIP App surface and isVip overlay

The Flutter client MUST NOT call App VIP commercial APIs (`GET /cash/app/api/vip/product`, `GET /cash/app/api/vip/status`, `POST /cash/app/api/vip/orders`) and MUST NOT ship VIP purchase pages, unlock-hub VIP sticky/bottom unlock-all, or helpers that treat `isVip` as unlocking catalog features or prediction. Existing `unlocked || isVip` synthesis MUST be removed. Bootstrap MUST NOT warm VIP status for prediction or feature gates. Note: `POST /cash/app/api/vip/apple/verify` is a **historical URL** retained by Go for feature/Xiaozhi Apple verify and is governed by the Apple-verify requirement below—not as a VIP API.

客户端 MUST NOT 再调用 VIP 商品/状态/建单 API、购页、sticky，以及 `isVip` 覆盖开通；bootstrap MUST NOT 为预测/功能门闸预热 VIP。`…/vip/apple/verify` 为 Go 历史兼容验单路径（功能/小智），见下方验单 Requirement，**不得**当作 VIP 业务 API。

#### Scenario: 开通中心无 VIP 入口

- **WHEN** 用户打开功能开通中心
- **THEN** UI MUST NOT 展示「开通月卡解锁所有功能」或 VIP sticky
- **AND** MUST NOT 导航至 VIP 购买页

#### Scenario: catalog 开通不依赖 isVip

- **WHEN** 某 catalog 项 `unlocked=false`
- **THEN** 客户端 MUST 视为未开通
- **AND** MUST NOT 因本地 isVip 缓存将其当作已开通

### Requirement: Client SHALL remove care-alert growth clinic and AI analysis hub

The client MUST remove user-reachable care-alert（值得留意）、growth trajectory、clinic/companion、feeding-analysis、and AI analysis hub surfaces, including routes, providers, and prediction-page entries that open them. The「接下来3小时」title row MUST NOT show「AI分析」. The client MUST NOT call retired care-alert / growth / clinic App APIs from these removed surfaces.

客户端 MUST 删除 care-alert、成长轨迹、诊疗/陪伴、喂养分析与 AI 分析 Hub 可达表面；3h MUST NOT 显示「AI分析」；MUST NOT 再打已删表面的退休 API。

#### Scenario: 预测页无 AI分析与值得留意

- **WHEN** 用户打开已绑定智能预测页
- **THEN** 「接下来3小时」标题行 MUST NOT 显示「AI分析」
- **AND** 页内 MUST NOT 展示「值得留意」卡片入口

#### Scenario: 路由不可达

- **WHEN** 用户尝试打开已删除的 `/prediction/ai-analysis`、feeding/growth 子页或 clinic 路由
- **THEN** 客户端 MUST NOT 再提供可正常使用的对应业务页（重定向首页或移除路由）

### Requirement: Feature and Xiaozhi Apple verify SHALL reuse historical vip/apple/verify path

After StoreKit purchase/restore for feature unlock or Xiaozhi MCP permanent unlock, the iOS client MUST `POST /cash/app/api/vip/apple/verify` with `transactionId`, `productId`, and `signedTransaction` when available, and MAY include `orderNo` (Go historical path; fulfills feature/Xiaozhi only, not VIP). When verify fails with `ApiBusinessException` and a non-empty `message`, the client MUST surface that `message` to the user. On success the client MUST refresh feature catalog and/or Xiaozhi unlock state as applicable, and MUST NOT refresh VIP status or treat the call as VIP entitlement.

功能单/小智 IAP 验单 MUST 继续使用历史路径 `POST /cash/app/api/vip/apple/verify`；业务失败 MUST 展示服务端 message；成功后 MUST 刷新 catalog/小智且 MUST NOT 刷新 VIP status。

#### Scenario: 验单成功刷新非 VIP

- **WHEN** 用户完成功能开通或小智的 StoreKit 购买且 verify 成功
- **THEN** 客户端 MUST 刷新 feature catalog 和/或小智 unlock
- **AND** MUST NOT 调用 `GET /cash/app/api/vip/status`

#### Scenario: 验单业务失败展示服务端文案

- **WHEN** verify 返回 `ApiBusinessException` 且 `message` 非空
- **THEN** 用户可见提示 MUST 为该 `message`（或以其为主体）
