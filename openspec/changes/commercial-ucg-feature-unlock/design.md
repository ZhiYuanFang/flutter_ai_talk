## Context

主壳当前被 `pause-ucg-vip-slim-prediction-chrome` 闸门关成两页（`kUcgHomePagerEnabled=false`），VIP 购买与历史同步广场亦关闭。Cash VIP（`vip/status`、`vip/product`、支付栈）已存在但入口不可达。

**服务端已落地**（兄弟仓 Go `commercial-feature-entitlement`，tasks 全勾选）：cash-service 提供 UCG 资格、合成 catalog、功能建单、邀请码兑换、广告完成；Admin「开通功能 / 邀请码」双页。本 Flutter 变更 **以已实现 HTTP 契约为准** 对齐客户端，不再假设独立 entitlements / activation_code 路径。

对照基线 `openspec/specs/v2.1.0.md` 与探索定稿：`isVip` 仅覆盖 **功能列表与预测锁**；UCG 入场 **仅** `eligibility.qualified`；预测锁仅 `allowedCount`。

## Goals / Non-Goals

**Goals:**

- 翻回 UCG/VIP/同步广场相关闸门，恢复三页导航与「左滑进广场 · 右滑去喂养」。
- UCG 可滑入；未 `qualified` 时全屏锁 +「返回预测页」；cache-first 再异步刷新。
- 预测真实行按 catalog 中 `prediction_unlock.allowedCount` 叠统一 `FeatureLockOverlay`；`isVip` 全开预测锁。
- 开通中心对接合成 catalog；方式 `payment` / `ad` / `invite_code`（UI 可称激活码）；月卡入口接 VIP 页。
- 设置头像下摘要；广场列表↔瀑布流（PK 全宽）。
- 权益与资格按 `deviceNo`（只经已登录绑机会话；服务端读内部头）。

**Non-Goals:**

- 恢复预测底 tip / 留意常驻失败条。
- 在 Flutter 实现 Admin；新建 summary 聚合 API。
- VIP 购买后回写 per-feature / allowedCount（服务端亦不写）。
- 真实广告 SDK；`isVip` 绕过 UCG 入场（**与 Go 对齐：禁止**）。
- 新建 `**/test/**`。

## Decisions

### D1：闸门翻回策略

- `kUcgHomePagerEnabled = true`、`kVipPurchaseEnabled = true`、`kHistorySquareSyncEnabled = true`。
- **为何三项一起翻**：商业闭环需要广场可达、支付可达、历史可同步发帖。

### D2：相对 pause change 的 supersede 边界

| pause 内容 | 本变更 |
|------------|--------|
| 两页壳 / 禁 UCG | **supersede** → 恢复三页 |
| 同步广场关 | **supersede** → 恢复 |
| VIP 不可达 | **supersede** → 恢复 |
| 大卡去掉广场文案 | **supersede** → 恢复「左滑进广场 · 右滑去喂养」 |
| 无底 tip / 留意仅非空 | **保留** |

### D3：UCG 闸门 = eligibility only（对齐 Go）

- **废弃**「UCG 作为 catalog `featureId` / `isVip` 解除 UCG 锁」的旧探索假设。
- 权威：`GET /cash/app/api/ucg/eligibility` → `qualified` / `requiredDays` / `effectiveDays` / `remainingDays` / optional `message`。
- 全屏锁条件：`qualified == false`（失败 fail-closed：接口错误时不得当合格放行；可展示错误+返回预测）。
- `isVip` **不得** 关闭 UCG 全屏锁（Go：VIP/功能权益不参与资格）。
- catalog **不含** UCG 项。
- 锁态下挂载的 `UcgShell` **不得** 触发广场定位权限 / Feed 刷新（及壳未读校准）；`qualified=true` 后再按既有逻辑执行。

### D4：统一 `FeatureLockOverlay`

- 真实内容之上：高斯模糊 + 浅透罩 + **仅中心锁**（无交叉锁链）；预测卡「点击开通」。
- UCG 全屏变体：天数进度（优先用 API `message`，否则本地拼 N/X/Y）+「返回预测页」→ `HomePagerPage.prediction`。
- 取色经 `AppColor` / `panelGlass`。

### D5：预测锁 = catalog `allowedCount`

```
catalog 项 featureId == "prediction_unlock" → allowedCount（缺省 0）
if isVip → 全部真实行无浮层
else:
  rows = smartPredictionRowsProvider（nextAt 序）
  跳过 demo/skeleton
  前 allowedCount 条无浮层；其后 FeatureLockOverlay → 开通中心
```

- **不**调独立 allowed-count / entitlements API。
- `prediction_unlock.unlocked` 服务端语义为 `allowedCount > 0`；客户端仍以 **数量** 驱动浮层，不以该 bool 单独决定「全开」。

### D6：权益与 VIP 覆盖（功能域）

```
effectiveUnlocked(feature) = catalogItem.unlocked || isVip   // 不含 UCG
predictionUnlockedAll      = isVip
displayMethod:
  catalog 已开通且有 unlockMethod → payment|invite_code|ad
  仅 isVip → vip（UI「月卡」）
UI 标签：payment→支付开通, ad→看广告, invite_code→激活码（或邀请码）, vip→月卡
```

- 键：`deviceNo`；切换宝宝换缓存。
- TTL：`expiresAt == 0` / 缺失 → 永久。
- Cache-first：本地 catalog/eligibility 先渲染再异步刷新；single-flight + 熔断；provider create 不自动打 HTTP。

### D7：开通中心与支付（对齐已落地路径）

| 用途 | Method | Path |
|------|--------|------|
| UCG 资格 | GET | `/cash/app/api/ucg/eligibility` |
| 合成目录 | GET | `/cash/app/api/feature/catalog` |
| 功能建单 | POST | `/cash/app/api/feature/orders` body: `{ productCode, channel }` channel=`alipay`\|`apple_iap` |
| 邀请码兑换 | POST | `/cash/app/api/feature/invite-codes/redeem` body: `{ code, featureId }`（须 wx 登录） |
| 广告完成 | POST | `/cash/app/api/feature/ad/complete` body: `{ featureId, idempotencyKey? }` |
| VIP | 既有 | `/cash/app/api/vip/*`（notify/verify **共用**，服务端按订单表分流） |

**Catalog 项（已实现字段）:**

```
featureId, title, description, unlockMethods (逗号串如 "payment,invite_code,ad"),
unlocked, unlockMethod?, expiresAt?, allowedCount? (仅预测类),
products: [{ productCode, priceFen, originalPriceFen, durationDays, grantKind, grantQuantity, appleProductId? }]
```

- 解析 `unlockMethods` 决定展示哪些 CTA；**无**独立 `supportsAd` bool。
- 支付展示与建单入参全部来自同项 `products[]`（见 D7b）。
- 邀请码弹窗文案仍可用「可向群主获取免费激活码」（产品文案）；API 字段为 `invite_code` / `invite-codes/redeem`，body **必须**带当前行的 `featureId`。
- 广告确认 = 已观看 → POST ad-complete；成功后刷新 catalog。
- 已开通：角标 +「开通方式」；隐藏 CTA。
- 页底「开通月卡解锁所有功能」→ `/vip/purchase`；VIP 页列出 **catalog 标题**（不含 UCG）。

### D7b：功能 SKU = catalog 嵌套 `products[]`（Go 已补齐）

Go 变更 `feature-catalog-embed-products` 已落地：`GET /cash/app/api/feature/catalog` 每项含 `products`（无启用 SKU 时为 `[]`，不得省略成 null 导致解析失败）。**不**新增独立 App products GET。

**SKU 元素字段（lowerCamelCase）：**

| 字段 | 用途 |
|------|------|
| `productCode` | 建单必填 |
| `priceFen` / `originalPriceFen` | 标价展示 |
| `durationDays` | 支付弹窗时长（0=永久） |
| `grantKind` / `grantQuantity` | 展示开通效果（如 `allowed_count_delta` ×N） |
| `appleProductId` | iOS IAP 映射（可空） |

**客户端规则：**

1. 支付 CTA：仅当 `unlockMethods` 含 `payment` **且** `products` 非空时展示；多 SKU 时列出可选档位（默认选第一项或最低价——实现选「列表第一项」，与服务端 `OrderAsc(product_code)` 一致）。
2. 建单：`POST .../feature/orders` 只用所选 `productCode`；价格以服务端建单回执/`priceFen` 为准，禁止硬编码。
3. 广告/邀请码弹窗时长：无 SKU 时可用「永久」或文案不强调天数；有 `products[0].durationDays` 时可作参考；已开通用 `expiresAt`。
4. **禁止**调 Admin products API。

### D8：设置摘要

- 拆分点击：摘要 → 开通中心；资料 → `/settings/baby`。
- VIP 优先：「月卡 · 剩余 X 天」；非 VIP：已开通项摘要 /「永久」；空态「暂无已开通能力 · 去开通」。
- 合并 `vip/status` + **catalog only**（无独立 entitlements）。

### D9：广场布局

- `UcgTabPage.actions` 主题色前加布局切换；prefs 持久化；默认列表。
- 瀑布流双列；`post.isDebate` 全宽打断。

### D10：鉴权与网关

- 上述 cash App 路径均须登录；资格/catalog **须绑机**（网关注入 `X-Internal-Device-No`）；Flutter 沿用 `authorizedApiClient` + 既有设备会话，**不**在 query/body 传 `deviceNo`。
- 兑码须 `wx_id`；纯设备无微信会话时邀请码入口须提示需登录微信账号。

## Risks / Trade-offs

- [多 SKU 选型] → 默认取 `products` 第一项；若运营要「选档」UI 再加选择器即可。
- [allowedCount 随 nextAt 重排] → 产品接受。
- [广告可刷] → MVP 接受。
- [VIP 不解除 UCG] → 与早期 Flutter 探索稿冲突；以 Go 定稿为准，避免广场被月卡绕过喂养门槛。
- [换绑设备 / 邀请码人维去重] → 新设备可能无权益且不能再码开同一 feature → 支付/广告/VIP(预测) 兜底。
- [主题违规] → 强制 `AppColor` / glass 原子。

## Migration Plan

1. 翻 flag → 三页与 VIP/同步。
2. Overlay → UCG gate（eligibility）→ prediction lock（catalog allowedCount）→ 开通中心 → 设置摘要 → 广场布局。
3. 对接 Go API（含 `products[]`）并接通支付。
4. 验收：滑入 UCG 锁与返回、预测前 N、VIP 全开预测/功能但 UCG 仍看资格、开通三路径、设置摘要、瀑布流 PK。
5. 回滚：flags 改回 `false`。

## Open Questions

- 路由名：`/features/unlock`（apply 时按 `app_router` 风格定）。
- 多 SKU 时是否强制选档 UI——默认第一项即可，非阻塞。
