## Why

兄弟仓 `go_ai_talk` 变更 `live-activity-clear-activity-on-app-open` 将下线 Live Activity update 的 ContentState.`ack`、免鉴权 `POST /app/api/push/live-activity/ack` 与短超时 failover；改为鉴权 `POST /app/api/push/live-activity/activity/clear`。本仓已有（或进行中的）`live-activity-update-ack` 原生回执将失效且易误打已删除路由。产品接受划掉到打开 App 的空窗；需在 App 前台且本机无统一 LA 时，由已登录 Flutter 带 Bearer 清服务端该机 `activity` token，使下次推送走 `start`。

## What Changes

- **BREAKING（移除 ack 客户端）**：删除 ContentState.`ack` 解码/观察回执、原生 `POST …/live-activity/ack`、相关去重与 `LIVE_ACTIVITY.md` ack 文档；**不再**经 Dart 或原生补传 ack。本变更 **取代** `live-activity-update-ack` 的送达回执方向。
- **新增 clear**：登录态下，冷启动就绪与 `AppLifecycleState.resumed` 时查询本机是否仍有 `BabyLiveActivityAttributes` Live Activity；**若不存在**则 `POST /app/api/push/live-activity/activity/clear`（Bearer + body `deviceKey`）；存在则不调。
- **副作用 HTTP**：clear 须 single-flight、短窗去抖、失败熔断/可观测日志，遵守 `openspec/project.md` 副作用 HTTP 治理。
- **非目标**：不在划掉瞬间后台 HTTP；不立刻本地 `Activity.request`；不改 register / 锁屏 UI（除去掉 ack）；不改 Android（无 ActivityKit）。

## Capabilities

### New Capabilities

- `live-activity-clear-activity-on-app-open`：App 打开/回前台且本机无统一 LA 时，鉴权 clear 服务端 activity token；并明确客户端 MUST NOT 再发 update ack。

### Modified Capabilities

- （无）基线 `v2.1.8` 锁屏展示需求不变；进行中的 `live-activity-update-ack` 由本变更在客户端侧替代（同发时以本变更为准，勿再合入 ack 回执）。

## Impact

- iOS：`PredictLiveActivityAttributes` / Bridge / `LiveActivityNativeRegister` 去掉 ack；新增「是否有活动中 LA」查询（供 Dart MethodChannel）。
- Dart：lifecycle / 登录后触发 clear；鉴权 HTTP API 客户端；deviceKey 来源与现有推送注册一致。
- 文档：`app/ios/PangbaoWidget/LIVE_ACTIVITY.md`。
- Twin：`go_ai_talk` / `live-activity-clear-activity-on-app-open`（须同发或 Go 先上 clear 再发 Flutter）。
- 基线：相对 `openspec/specs/v2.1.8.md` 为新增自愈行为，不破坏既有锁屏样式需求。
