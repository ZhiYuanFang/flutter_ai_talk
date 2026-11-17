## Why

预测页下拉只滚历史与预约，准确率柱依赖内存里的 `expect*`；服务端已有预计但本页未对齐时，今日柱空白，需下拉后显式走准确率对齐。点「接下来3小时」开墙时功能包（feature catalog）仍 cache-first，运营改文案/logo 后墙内容可能过期。

## What Changes

- 预测页卡片区下拉刷新成功拉取滚动历史后，MUST 触发准确率对齐路径：调度既有 `schedulePredictPostHistoryMutation`（expect-batch 管线），使合格样本/柱图随统一池历史更新；预约 next/last 静默刷新保留。
- 非 syncing 时点击「接下来3小时」整卡开两档墙前（或与开墙并行），MUST `featureCatalog` **force** 刷新（`ensureLoaded(force: true)` / `refresh()`）；失败 MUST 保留旧 cache 仍可开墙。
- **不改**：示例空态页级门闩、小结叶子身份、乐观本地写 expect（本版仍以 batch→WS/再读历史为主）、开墙其它交互。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：下拉含准确率对齐；三小时 tap force 刷新功能包再开墙。
- `predict-list-accuracy-bars`：下拉后准确率图区 MUST 能反映刷新后统一池中的合格样本。
- `predict-post-mutation-scheduler`：允许由预测页显式下拉调度静默管线（非仅 CRUD 突变）。

## Impact

- Flutter：`smart_prediction_screen.dart`（`onCardsPullRefresh`、`_NextThreeHoursTimeline`）；复用 `schedulePredictPostHistoryMutation`、`featureCatalogStateProvider.refresh`。
- 无 Go / 原生；Release N/A。
