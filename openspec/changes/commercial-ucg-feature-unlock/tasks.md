## 1. 闸门翻回与主壳恢复

- [x] 1.1 将 `kUcgHomePagerEnabled` / `kVipPurchaseEnabled` / `kHistorySquareSyncEnabled` 改为 `true`，并更新注释说明商业化已重开
- [x] 1.2 确认 `UcgHomeShell` / `HomePagerPage` 三页导航、懒挂载 UCG、`requestPage(ucg)`、Android 从 UCG 回预测均可用
- [x] 1.3 恢复预测 Auth 滑动引导副文案「左滑进广场 · 右滑去喂养」（不恢复底 tip 跑马灯）
- [x] 1.4 恢复历史编辑「同步广场」开关与 sync ON 时的 UCG 副作用路径

## 2. 权益客户端与 API 接线（对齐已落地 Go）

- [x] 2.1 新增 repository/模型：`GET /cash/app/api/feature/catalog`（含嵌套 `products[]`）、`GET /cash/app/api/ucg/eligibility`、`POST .../feature/orders`、`POST .../invite-codes/redeem`、`POST .../ad/complete`（lowerCamelCase；**无**独立 entitlements/activation_code/App products 路径；不在 query/body 传 deviceNo）
- [x] 2.2 实现 cache-first + 异步刷新；single-flight、失败熔断；provider create 不自动打副作用 HTTP；按 `deviceNo` 键控本地缓存
- [x] 2.3 实现 `effectiveUnlocked = catalog.unlocked || isVip`（**仅功能/预测**）；UCG 闸门 **只**看 eligibility.`qualified`；`expiresAt` 0/缺失=永久；预测 `allowedCount` 取自 `featureId=prediction_unlock`
- [x] 2.4 解析 `unlockMethods` 逗号串；UI 将 `invite_code` 展示为激活码/邀请码
- [x] 2.5 解析 catalog `products[]`（productCode/priceFen/originalPriceFen/durationDays/grantKind/grantQuantity/appleProductId）；支付 CTA 仅当含 payment 且 products 非空；默认选 `products` 第一项；POST feature/orders；成功后刷新 catalog（禁止 Admin API / 硬编码运营码）

## 3. 统一 FeatureLockOverlay

- [x] 3.1 实现共享 `FeatureLockOverlay`：真实背景高斯模糊 + 浅透罩 + **仅中心锁**（无交叉锁链）；取色走 `AppColor` / lockScrim
- [x] 3.2 预测卡变体中心文案「点击开通」；UCG 全屏变体支持天数区与「返回预测页」槽位
- [x] 3.3 去掉交叉锁链绘制，保留中心锁图标

## 4. UCG 入口闸门

- [x] 4.1 滑入 UCG 后挂载壳；`qualified=false`（或失败 fail-closed）时叠全屏锁并展示 eligibility 天数/`message`
- [x] 4.2 「返回预测页」调用既有回预测逻辑；**仅** `qualified=true` 时不展示全屏锁（`isVip` 不得解除）
- [x] 4.3 锁态（未 qualified）不请求定位、不拉广场 Feed；合格后才按既有逻辑 ensureLocation + refresh

## 5. 预测事件锁

- [x] 5.1 在真实 `smartPredictionRowsProvider` 行上叠锁（非骨架替换）；跳过 demo/skeleton 计数
- [x] 5.2 按 catalog `prediction_unlock.allowedCount` 解锁前 N 条；`isVip` 全开；点击锁定导航开通中心
- [x] 5.3 冷启落在预测页时首帧 ensure catalog（勿仅依赖 onPageChanged），避免 allowedCount=0 全锁

## 6. 开通中心与 VIP

- [x] 6.1 新增开通中心路由与玻璃拟态页；列表来自 catalog
- [x] 6.2 支付 / 广告 / 邀请码弹窗均展示时长；邀请码 hint「可向群主获取免费激活码」且 redeem 带 `featureId`；广告确认 POST ad/complete
- [x] 6.3 已开通卡展示「已开通」+ 方式标签（payment/ad/invite_code/vip→月卡），隐藏开通 CTA
- [x] 6.4 底部「开通月卡解锁所有功能」进 `/vip/purchase`；VIP 页列出 **catalog** 标题（不含 UCG）
- [x] 6.5 移除暂停期对 `/vip/purchase` 的 redirect 拦截

## 7. 设置中心摘要

- [x] 7.1 在 `_BabyProfileReadonlyCard` 头像下增加已开通摘要；VIP 优先「月卡 · 剩余 X 天」
- [x] 7.2 拆分点击：摘要 → 开通中心；资料区 → `/settings/baby`

## 8. UCG 广场布局切换

- [x] 8.1 广场 AppBar actions 增加列表↔瀑布流切换并本地持久化偏好
- [x] 8.2 实现瀑布流双列；`isDebate` PK/辩论帖全宽打断；列表模式保持全宽

## 9. 日志与验收

- [x] 9.1 若新增 Debug tag：三联改 `app_debug_log.dart`、`logcat_api_http.ps1`、`app/README.md`；禁止裸 `print`/`debugPrint`
- [x] 9.2 手工验收：三页与 UCG 资格锁（VIP 不绕过）、预测前 N/VIP 全开预测、开通三路径、设置摘要点击分离、瀑布流 PK 全宽、同步广场开关
- [x] 9.3 本变更若未改 `app/android/**` 可跳过；若改动原生/SDK 则必须 `flutter build apk --release` 通过并更新 `proguard-rules.pro`
