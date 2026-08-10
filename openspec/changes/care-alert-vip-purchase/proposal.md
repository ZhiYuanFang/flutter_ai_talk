## Why

护理留意详情已上线，但非 VIP 用户缺少开通入口与支付闭环。后端 cash-service（经 gateway）已提供商品/状态/建单/Apple 验单接口；Flutter 需落地「非 VIP CTA → 购买页 → 平台支付 → 刷新权益」以完成商业闭环。

## What Changes

- 留意详情页进入时拉取 VIP 状态；非 VIP 展示底部悬浮「开通 VIP」CTA；已是 VIP 则隐藏。
- 新增 VIP 购买页：展示现价；若接口返回 `originalPriceFen > 0` 则展示划线原价。
- 支付与开通：
  - iOS：`apple_iap` 建单 + StoreKit（`in_app_purchase`）+ `POST /cash/app/api/vip/apple/verify`
  - Android：`alipay` 建单 + 支付宝 SDK 调起；回前台后轮询 `GET /cash/app/api/vip/status`
- 支付成功后刷新 VIP 状态并关闭 CTA / 购买页成功态。
- 新增 cash VIP API 仓储与 debug 日志 tag；依赖 `in_app_purchase` 与支付宝 Flutter 插件（`tobias`）。

## Capabilities

### New Capabilities

- `cash-vip-client`：对接 `/cash/app/api/vip/*` 的商品、状态、建单、Apple 验单；模型字段与网关契约对齐。
- `vip-purchase-ux`：购买页展示、平台支付编排、成功后状态刷新与用户反馈。

### Modified Capabilities

- `prediction-care-alert`：留意详情页增加非 VIP 底部「开通 VIP」悬浮 CTA，并导航至购买页。

## Impact

- UI：`prediction_care_alert_screen.dart`；新增 VIP 购买屏；`app_router.dart` 增加路由。
- 数据/Provider：新增 VIP repository / provider；复用 `authorizedApiClientProvider`。
- 依赖：`pubspec.yaml` 增加 `in_app_purchase`、`tobias`；Android/iOS 原生配置与 ProGuard（支付宝）。
- 后端：只消费既有 gateway 契约，不改 `go_ai_talk`（除非发现阻塞性 API bug）。
- 运维前置：ASC `appleProductId`、支付宝应用配置须已就绪；Flutter 侧文档说明联调步骤。
