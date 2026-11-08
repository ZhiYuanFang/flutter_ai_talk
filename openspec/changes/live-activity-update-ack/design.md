## Context

Go twin `live-activity-update-ack-timeout` 已落地：仅对 APNs `event=update`（含 upsert→update）在 ContentState 注入不透明 `ack`，`send_ok` 后写 `last_sent_ack` 并 `AfterFunc`（`LIVE_ACTIVITY_ACK_TIMEOUT_MS`，默认 3000）；超时未匹配 ack 则删 `token_kind=activity` 并用同 `device_key` 的 `push_to_start` 重启。ack HTTP：`POST /app/api/push/live-activity/ack`，body `wxId`/`deviceKey`/`ack`，gateway 免 Bearer（对齐 register）。

本仓统一列表 LA（`unify-live-activity-list`）已有 `BabyLiveActivityAttributes` 与原生免鉴权 register（App Group + Keychain 缓存 wxId/deviceKey/apiBase）。ContentState 当前仅解码 `phase`/`items`，会静默丢弃 `ack`；Bridge 只观察 push token，不观察 content 更新。

产品确认：ack **随 update 消息体一并下发**；客户端在收到 ContentState 后立即回执；**Dart 不补传**；独立 change。

## Goals / Non-Goals

**Goals:**

- ContentState 解码可选 `ack`；锁屏/Island UI 忽略该字段。
- Runner 原生在 content 更新（及挂观察时扫当前 state）发现非空 `ack` 时，立即免鉴权 POST ack。
- 复用 register 身份上下文；失败仅日志，不崩溃、不阻塞 UI。

**Non-Goals:**

- Dart/MethodChannel ack 补传；设置页 ack 诊断 UI。
- Widget Extension 内发 HTTP。
- 改 Go 超时、failover、register、列表 UI、深链。
- 对 start/end（无 ack）做额外探测。

## Decisions

1. **收包钩子 = ActivityKit ContentState，不是普通 APNs alert**  
   LA update 经 ActivityKit 到达；主路径挂 `Activity<BabyLiveActivityAttributes>` 的 `contentUpdates`，并在 `attach` 时读一次 `activity.content.state`，避免错过已落地的当前帧。  
   *备选：解析 UNNotification userInfo — 否决（LA 不走该通道）。*

2. **触发条件：`ack` 非空即发**  
   与 Go「仅 update 注入 ack」对齐；start/end 无字段或空串则 skip。不在客户端区分 event 名。

3. **仅原生 HTTP，对齐 register**  
   新建或扩展与 `LiveActivityNativeRegister` 同族的 ack POST：同一 App Group/Keychain 读 `wxId`/`deviceKey`/`apiBase`；`POST {apiBase}/app/api/push/live-activity/ack`，JSON body，无 Bearer，短 timeout（建议 ≤15s，但目标是在 Go 默认 3s 窗口内发出）。  
   **禁止** Dart 监听 content 或补传 ack。  
   *备选：原生+Dart 双路径 — 否决（用户明确不要 Dart 补传；冷启动超超时）。*

4. **去重**  
   进程内对相同 `ack` 字符串成功发出后可短路，避免 contentUpdates 抖动重复打；乱序旧 ack 仍可发出，Go 侧 mismatch no-op。

5. **不在 Extension**  
   与 Go design「不在 widget extension 内实现」一致；Extension 只消费 phase/items 展示。

6. **文档**  
   `LIVE_ACTIVITY.md` 增加 ContentState.`ack` 与 ack path 表，注明仅 update、免鉴权、无 Dart。

## Risks / Trade-offs

- [原生唤醒晚于 3s] → Go 误 restart、锁屏闪；依赖可配服务端超时 + 尽早挂 content 观察（与 token early observe 同生命周期）。  
- [无 wxId/apiBase 缓存] → 发不出 ack → 超时 failover（与 register 缺上下文同级）。  
- [划掉 LA 后无 activity] → 收不到 content → 超时重启（预期探测）。  
- [ContentState 多字段] → UI 已用 decodeIfPresent；ack 缺省空串即可。

## Migration Plan

1. ContentState 加 `ack` + Bridge content 观察 + 原生 ack POST。  
2. 更新 `LIVE_ACTIVITY.md`。  
3. 与 Go 开 `PUSH_LIVE_ACTIVITY_ENABLED` 联调：update 带 ack → 原生回执 → 不 restart；划掉后超时 restart。  
4. 回滚：客户端停发 ack 仅导致更频繁 restart（服务端行为保留）；关服务端超时/开关属 Go 侧。

## Open Questions

- 无（收包=ContentState、仅原生、单独 change 已确认）。
