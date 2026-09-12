## Why

已绑定用户在预测 range 真历史为空时，主内容常落到「回忆宝宝习惯」缺省页，视觉单调、无法展示预测能力；同时空库量身定做 Dialog 与卡片内补齐路径抢心智。需要改为**永远按目录非子事件出全量预测卡**，在卡上引导补记录/补间隔，并退役量身定做 Dialog。

## What Changes

- **BREAKING**：退役空库「量身定做」Dialog / 会话自动弹层（含软关再弹、空态「回忆宝宝习惯」入口对 Dialog 的再打开）；不再用全屏/遮罩队列采集 lastAt+interval。
- 去掉已绑定热态下因 `rows.isEmpty` 展示的 `AppEmptyStateGallery`（「回忆宝宝习惯」）缺省页。
- **行构建永远 catalog-complete**：已绑定热态预测行 **必须** 覆盖目录全部非子（`parentId == null`）根事件；有无历史只影响卡上数据与 CTA，不决定「有没有这张卡」。已关推演的 root **仍出卡**（便于再开开关）。
- 无 `lastAt` 且推演开启：展示心跳「补充上一次」，行为与点卡相同（`handleEventGridTap` 加喂养）；**不得**展示「补充大概多久一次」。
- 有 `lastAt`、无 `prediction`、推演开启：保留既有「补充大概多久一次」→ 全量 `PredictionRecallSeed`（不引入仅间隔草稿契约）。
- 推演关闭：两种补齐 CTA 均不展示；整卡点击的加事件引导与补齐语义对齐（关推演不走补齐点击）。
- 预测事件卡 **原子化**：由入参/派生 flags 驱动 chrome 与 actions，避免按「空库/有历史/缺间隔」分型绘制多套 Widget。
- 热态卡「上一次{事件}：时间」在存在该 root **真喂养**最近记录时可点，打开与喂养页相同的 `showHomeHistoryEditSheet`；「暂无」或仅种子伪记录时不可点。本 change **不**删除量身定做 Dialog 残留源码（仅已断入口）。

## Capabilities

### New Capabilities

- （无；补齐 CTA 与行完备规则落在既有 smart-prediction / per-card 能力增量。）

### Modified Capabilities

- `smart-prediction-page`：热态主内容不得因空历史展示回忆缺省页；行列表必须目录非子完备；卡片补齐 CTA 与原子 chrome；量身定做 Dialog 不得再叠在热态上；「上一次」可点进历史编辑 Sheet。
- `prediction-recall-onboarding`：**BREAKING** 空库不得再自动展示量身定做 Dialog/会话队列；相关软关再弹与空态再开路径退役。
- `prediction-recall-per-card-interval`：明确 `lastAt == null` 时 **不得** 展示间隔 CTA；与「补充上一次」门闸并列（间隔仍要求 `lastAt`）。
- `prediction-demo-skeleton`：已绑定且真历史为空时 **不得** 再依赖「空库骨架 + Dialog」作为主路径；未登录/未绑定冷态骨架规则可保留。

## Impact

- **Flutter**：`smart_prediction_rows.dart` / `smartPredictionRowsProvider`、`smart_prediction_screen.dart`（空态、`_PredictionEventCard`、gate/Dialog 编排）、`prediction_recall_provider` 及相关 Dialog/会话 UI 入口。
- **种子契约**：不改 `PredictionRecallSeed`（仍要求 `lastAt`）；不新增仅间隔草稿存储。
- **API / Android**：无。
- **测试**：不新建 `**/test/**`；手工验收空库全量卡、半记录完备、关推演无 CTA、补上次=点卡、有 lastAt 补间隔出预测、Dialog 不再出现、点「上一次」打开与喂养同款编辑 Sheet。
