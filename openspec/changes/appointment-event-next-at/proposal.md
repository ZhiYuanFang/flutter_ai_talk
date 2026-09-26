## Why

后端已支持事件字典 `isAppointment` 与按宝宝持久化的预约下次约定 API。疫苗等预约事件若不按作息间隔预测，客户端预测卡片与推送仍会误用间隔补全。本变更将孪生仓 `go_ai_talk` 的 `appointment-event-next-at` 契约同步到 Flutter，并按需求确认后的交互落地：正常新增不改原页、专用补约 sheet、编辑页可见可改且仅编辑页可清空。

**上游（已实现）**：`go_ai_talk` change `appointment-event-next-at`（device-service + gateway；predict 服务端未改）。

## What Changes

- 解析事件 options 的 `isAppointment`（缺省非预约）；**不得**用 `eventType=one` 推断；预约读写与 pending 一律使用 **catalog 根 eventId**。
- 预约事件：预测 **不** 走间隔推演与「补充大概多久一次」；有 `nextAt>0` 则预测结果取该时间（含已过期，UI 标过期仍推）；无约定则无推送节点，预测卡仍展示并提供「补充下次」。
- **新增**：不修改原有新增页/一键落库流程；成功后若该根事件下次约定为空或已过期，弹出 **专用下一次预约 sheet**。
- **补充上一次**：成功后同样仅在空/过期时弹同一专用 sheet。
- 专用 sheet：上「`{logo}`下一次`{事件名}`预约时间」，下年月日时分滚动选择；确认后经 `PUT /device/app/api/appointment/next` 写入并同步 pending。
- **编辑 history**：展示下次预约时间，点击可改（进同一套时间选择）；**仅此路径提供清空**（`nextAt=0` + pending omit）。预测卡/打点后专用 sheet **不得**提供清空。
- 清空约定：预约 API 写 `0`，pending 整表同步时 **从列表移除** 该 `eventId`。

## Capabilities

### New Capabilities

- `appointment-event-client`：Flutter 侧预约识别、预测分流、专用补约 sheet、编辑页展示/修改/清空、与 pending 两步协作。

### Modified Capabilities

- `event-interval-prediction`：预约事件排除间隔推演。
- `predict-imminent-client-sync`：无约定/清空时 pending omit；有约定（含过期）纳入 pending。
- `prediction-recall-per-card-interval`：预约卡以「补充下次」为主路径，非间隔补充。

## Impact

- 模型：`EventDefinition` / options / `catalogSnapshotsEqual` 增加 `isAppointment`。
- 网络：`GET/PUT /device/app/api/appointment/next` repository（Bearer；`deviceNo` 绑机；秒级 unix）。
- UI：专用下一次预约 sheet；`smart_prediction_screen` 预约卡 CTA；`home_history_edit_sheet` 展示/改/清；新增与补充成功后的引导弹层。
- 预测：`event_next_predictor` / `smart_prediction_rows` / `predict_imminent_*`。
- **不在本 change 实现服务端**；后端契约以 `go_ai_talk` 为准。
