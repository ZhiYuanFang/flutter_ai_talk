## 1. 依赖与调试基建

- [x] 1.1 在 `app/pubspec.yaml` 增加 `in_app_purchase`、`tobias`；执行 `flutter pub get`
- [x] 1.2 新增 `AppDebugLog.cashVip`（`[CashVip]`），同步 `logcat_api_http.ps1` 的 `$Tags` 与 `app/README.md` Debug 表格
- [x] 1.3 Android：按 `tobias` 文档核对 Manifest / URL Scheme；补充 `proguard-rules.pro` 支付宝 keep；记录 Release 验证要求
- [x] 1.4 iOS：按需补充 StoreKit capability / 说明 ASC `appleProductId` 对齐（README 简短验收）

## 2. Cash VIP 客户端

- [x] 2.1 新增模型与 `CashVipRepository`（product / status / createOrder / appleVerify），路径对齐网关契约
- [x] 2.2 新增 Riverpod：`vipStatusProvider`（可刷新）、`vipProductProvider`；复用 `authorizedApiClientProvider`
- [x] 2.3 支付编排服务：iOS IAP + verify；Android Alipay + 有界 status 轮询（single-flight）

## 3. UI 与路由

- [x] 3.1 新增 VIP 购买页：现价、可选划线原价、开通按钮与加载/错误态
- [x] 3.2 `app_router` 注册 `/vip/purchase`（需登录）
- [x] 3.3 留意详情页：拉取 VIP 状态；非 VIP 底部悬浮「开通 VIP」；点击进入购买页；VIP 隐藏 CTA
- [x] 3.4 开通成功后刷新 status，返回详情后 CTA 消失

## 4. 文档与验收

- [x] 4.1 README 补充 VIP 联调：iOS sandbox / Android 支付宝、环境前置与已知 blocker
- [x] 4.2 自检：对照 specs（CTA / 划线价 / 双端支付 / 刷新隐藏）勾选本任务列表
