## Context

兄弟仓 `go_ai_talk` 已上线 cash-service VIP：经 gateway-app 暴露

- `GET /cash/app/api/vip/product`（可匿名）：`priceFen` / `originalPriceFen` / `appleProductId` 等
- `GET /cash/app/api/vip/status`（需登录）：`isVip` / `expireAt`
- `POST /cash/app/api/vip/orders`：`channel`=`alipay`|`apple_iap`
- `POST /cash/app/api/vip/apple/verify`：StoreKit 后验单

Flutter 护理留意详情（`/prediction/alert`）已存在；本变更仅客户端闭环，不改 Go。

## Goals / Non-Goals

**Goals:**

- 非 VIP 在留意详情见「开通 VIP」悬浮 CTA；VIP 隐藏。
- 购买页展示现价与可选划线原价；按平台发起支付并开通。
- 成功后刷新状态，详情 CTA 消失。
- 复用 `ApiClient` + Bearer；遵守 Debug 日志白名单与 Android R8 约定。

**Non-Goals:**

- 不做订阅管理页、退款、多 SKU、Web 支付。
- 不在 Flutter 硬编码价格（以 product API 为准）。
- 不新建 `**/test/**` 测试文件。
- 不改 go_ai_talk（除非发现阻塞性 API bug）。

## Decisions

### D1：入口与路由

- 入口：仅留意详情页底部悬浮 CTA（`floatingActionButton` 或 `bottomNavigationBar` 风格条），文案「开通 VIP」。
- 路由：`/vip/purchase`（需登录；未登录走既有 redirect → `/login`）。
- 从详情 `context.push('/vip/purchase')`；购买成功 `pop` 并刷新 VIP provider。

### D2：VIP 状态与商品

- Provider：`vipStatusProvider`（AsyncNotifier / FutureProvider），登录后可拉取；详情页 watch。
- 商品：`vipProductProvider`，购买页拉取；`originalPriceFen > 0` 才展示划线。
- 金额展示：分 → 元，保留两位小数（如 `1900` → `¥19.00`）。
- product 可匿名，但 App 统一走 `authorizedApiClient`（有 token 则带上即可）。

### D3：支付通道

| 平台 | channel | 客户端步骤 |
|------|---------|------------|
| iOS | `apple_iap` | 建单 → `InAppPurchase.buyNonConsumable/buy`（以 API `appleProductId` 为准）→ 取 transactionId / productId / JWS（若插件可得）→ `apple/verify` → 刷新 status |
| Android | `alipay` | 建单 → `tobias` 调起 `alipayOrderStr` → 回前台后轮询 status（间隔约 1.5s，最多约 8 次）→ 成功刷新 |
| 其他 | — | 提示暂不支持 |

- Web：不展示 CTA 或 CTA 提示「请使用手机 App」。
- Apple：ASC 商品 ID **必须**与后端 `appleProductId` / `CASH_APPLE_PRODUCT_ID` 一致；价格以 ASC 为准，App 展示现价来自 DB。
- Alipay：服务端签名 orderStr；客户端不持有支付宝私钥。`tobias` 需 Android Manifest / iOS URL Scheme 按插件文档配置。

### D4：副作用 HTTP 与轮询

- 详情页进入拉取 status：允许；失败不 Toast 刷屏，CTA 默认按「非 VIP」展示或隐藏策略：**失败时显示 CTA**（宁可误开入口，建单再鉴权）。
- Alipay 回前台轮询：single-flight；离开购买页取消；达上限停止并提示「若已支付请稍后查看」。
- 禁止无限重试环。

### D5：依赖与原生

- `in_app_purchase`：官方 StoreKit / Play Billing；本期 Android **不用** Google Play 计费，仅 iOS 走 IAP。
- `tobias`：支付宝；Android ProGuard 按插件补 `-keep`；Release 须 `flutter build apk --release` 验证。
- Debug tag：`[CashVip]`，三联改 `AppDebugLog` / logcat 脚本 / README。

### D6：默认商品码

- 建单默认 `productCode: vip_monthly_19`（与后端一期一致）；若 product API 返回 `productCode` 则用之。

## Risks / Trade-offs

- **ASC / 支付宝未配置**：支付必失败 → README + runbook 注明 blocker，不阻塞 UI 落地。
- **JWS 获取**：`in_app_purchase` 新版可通过 `PurchaseDetails.verificationData.serverVerificationData`；若沙箱无 JWS，依赖后端 `CASH_PAYMENT_DEV_BYPASS`（仅非生产）。
- **划线价与 ASC 标价不一致**：展示以 DB；人肉对齐 ASC。

## Migration Plan

无数据迁移。发版前确认 gateway `CASH_SERVICE_URL`、支付宝 notify、ASC 商品。回滚：隐藏 CTA / 去掉路由即可。

## Open Questions

无（产品路径已冻结）。运维侧 ASC productId 与支付宝 AppId 属环境配置，非客户端决策。
