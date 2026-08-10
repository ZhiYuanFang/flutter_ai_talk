## Why

「值得留意」首版只展示全局 Top1，会漏掉同屏其他过阈值事项；家长需要在固定一行高度内看到**全部需留意事件**，并能滑到/点进某一条看完整原因。同事件多规则命中时，列表应一句话概括，详情再展开全量依据。

## What Changes

- **BREAKING（相对 `prediction-care-alert-banner`）**：取消全局「最多 1 条 / Top1」；引擎输出全部过阈值候选，再 **按事件聚合**。
- 智能预测页 tip 与推演列表之间改为固定高度「值得留意」**跑马灯区块**：
  - **严格裁切只见一行**（不露出下一条一截）；
  - ≥2 条时上下自动轮播；1 条静止；
  - 支持手动滚到目标条；点击当前条进入该事件详情。
- 同事件多规则：区块内 **单行摘要**（多问题用顿号/逗号连接，过长尾部省略）；详情页 **全量**展示该事件全部结构化原因。
- 类型优先级（间隔拉长 > 进行中过久 > 突然消失）改为 **排序与同事件文案顺序**，不再用于全局丢弃其他类型。
- 无候选时整块仍隐藏；语气仍为「值得留意」。

## Capabilities

### New Capabilities

- （无）本变更在既有护理留意能力上增量。

### Modified Capabilities

- `prediction-care-alert`：由 Top1 改为全量候选 + 按事件聚合摘要；详情承载单事件多原因。
- `smart-prediction-page`：单 Banner 改为严格单行裁切的跑马灯区块；点击进对应事件详情。

## Impact

- 引擎/聚合：`app/lib/data/prediction_care_alert.dart`（返回列表 + 事件聚合 DTO）。
- Provider：`prediction_care_alert_provider.dart`（`List` / 聚合项，而非可空单条）。
- UI：`smart_prediction_screen.dart`（跑马灯）；`prediction_care_alert_screen.dart`（多原因）。
- 路由：`/prediction/alert` 的 `extra` 改为事件聚合对象（含 `List<CareAlertReason>`）。
- 不改 HTTP / 推演公式 / tip SSE；不自动新建测试文件。
- **并存**：与 `prediction-layout-list-grid` 同时落地时，留意跑马灯仍全宽置于 tip 与事件卡片区之间；卡片区 list/grid 切换 **不得** 改变留意区块位置或裁切规则。
