## Context

产品要在 iOS 锁屏展示「即将发生」与「计时中」两类 Live Activity，由服务端 Push to Start 起停。权威调度在 `go_ai_talk` change `predict-live-activity-push`。本仓现有 WidgetKit 桌面小组件与普通 APNs 点击收件箱；无 ActivityKit。

## Goals / Non-Goals

**Goals:**

- 两类 Attributes / 锁屏 UI；Push to Start token 上报。
- 本机等推送，禁止本地 request 起两类 LA。
- 点击进预测页；不因点击 dismiss Imminent。
- 能并存多条 Timing；Imminent 展示服从服务端单槽/清场。

**Non-Goals:**

- Go 限流、pending 清场、history 钩子、APNs liveactivity 发送实现（对端仓）。
- Android 锁屏。
- 改间隔预测公式或 pending JSON 字段（除非对端约定新 token 字段需客户端上报）。
- 桌面 Widget 与 LA 合并。

## Decisions

1. **仓拆分。** 服务端规格与 tasks 只在 `go_ai_talk`；本仓 specs 主语为客户端，服务端行为用「对端 change」引用。
2. **两类 Attributes。** 与产品「两类锁屏组件」一致。
3. **禁止本地 Activity.request 起推送职责内的展示。** 与对端「本机也等推送」一致，避免双实例。
4. **点击不 end。** 消除只认系统收到的 end 推送（由对端在 pending 清场/换新/Timing 闭合时发出）。
5. **Token 上报（已与对端对齐）。** `POST /app/api/push/live-activity/register`：字段 `deviceKey`、`tokenKind`（`push_to_start`|`activity`）、`attributesKind`（`imminent`|`timing`）、`token`；`tokenKind=activity` 时 `activityId` 必填。两类 Attributes 分别上报 Push-to-Start。MUST NOT 走 `/app/api/push/register`。
6. **深链。** 复用进 `/home` + 预测页分流（可与 `predict_imminent` 同族）；不新增 UCG 分流。
7. **Info.plist。** `NSSupportsLiveActivities`（及 Push to Start 所需项）在本仓 Extension/Runner 配置；APNs `.p8` 仍在对端。

## Risks / Trade-offs

- [对端开关未开] → LA 推送不达；客户端空转。联调依赖对端特性开关（Go tasks 4.x）。
- [系统未送达 end] → 锁屏可能残留至系统超时或下次 pending 清场；客户端不点开消除是产品选择。
- [per-activity update token 未及时上报] → 对端 end 可能失败；实现须在 Activity 建立后尽快 `tokenKind=activity` 注册。

## Migration Plan

1. 对端 `predict-live-activity-push` 已实现主路径；本仓 Extension + LA register + 深链后联调开开关。
2. 回滚：停上报 LA token / 停用 Extension；对端关 LA 开关可恢复 iOS alert。

## Open Questions

- Live Activity 深链 payload 字段表（eventId / deviceNo 等）与对端 fanout 载荷最终键名：联调前对照 Go `FanoutLiveActivity` 文档化即可。
