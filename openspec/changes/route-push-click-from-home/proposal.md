## Why

离线（以及前台横幅）通知被点击后，应用只会被拉到前台并停在默认预测页，用户无法按业务类型进入 UCG 消息列表或确认回到预测主页。`bizType` 在 Go 侧已经存在，但点击回调里端上经常读不到；小米、vivo、oppo 尚未上架，不能把这三家的真实下发当成验收。

## What Changes

- 点击可见通知后，客户端必须先进入 `/home`，由主页在会话已知后决定去向，不得在点击回调里直接 `push` 子路由。
- `bizType=ucg_alert` 且已登录：切到 UCG 页；`UcgShell` 挂上后走与用户点消息 Tab 相同的处理，进入消息列表。资格未过时停在该页锁层，不另开页面。
- `bizType=predict_imminent`：切到预测主页，不进入 UCG 链。
- 未登录、缺 `bizType`、或不认识的类型：只打开应用，停在默认预测页，不弹登录。
- 静默角标（`ucg_silent_badge`）没有可点通知条，不参与跳转。
- 后一次点击覆盖尚未消化的 `bizType`，不排队。
- Go（`go_ai_talk`）：华为与 APNs 的可见推送必须把 `bizType` 放进点击时端上能读到的载荷。vivo、oppo 只留通道占位（dispatcher 空位，`Send` 打日志跳过），不接厂商 REST，客户端不为它们 `register`。小米已有 Sender，可见消息的 `payload` 可顺手写入 `bizType`，但不作为本变更验收。

## Capabilities

### New Capabilities

- `push-click-home-route`：通知点击暂存、主页按 `bizType` 分流、UCG 壳就绪后进入消息 Tab；未登录与未知类型的停页规则。

### Modified Capabilities

- `ucg-launcher-badge-push`：可见推送在已上线通道（APNs、HMS）上必须携带可被点击回调读到的 `bizType`；vivo/oppo 仅为占位，不改变现有 register 允许的通道集合。

## Impact

- Flutter：`china_push` 点击监听、iOS `userInfo` 转发与前台横幅、主壳 `/home` 消费、`UcgShell` 消息 Tab。日志走现有 `AppDebugLog`，不新增裸 `print`。
- Go：`go_ai_talk` 的 `internal/services/push`（HMS / APNs 点击载荷；vivo/oppo 占位；小米 `payload` 可选）。不改 `PUT /device/api/predict/imminent/pending`，不扩大 `POST /app/api/push/register` 的通道白名单。
- 与未归档变更 `android-china-push-predict-imminent` 叠加：该变更把「点击深链」和 vivo/oppo Sender 列为非目标；本变更只做主页分流，且 vivo/oppo 仍不实现真实下发。
