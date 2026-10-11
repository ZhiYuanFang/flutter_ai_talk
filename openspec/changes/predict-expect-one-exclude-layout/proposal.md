## Why

`predict-expect-amount-duration` 落地后，目录 `eventType=one` 的记录因落库 `eventNumber=1`，被误计入 amount 线，预测卡出现无意义的「预计约1…」。同时「预计约…」次级文案目前插在标题区（大 logo 之上），与「贴着倒计时读预计长度」的阅读顺序不符。

## What Changes

- **算法**：采 duration / amount 样本与可计量模态决胜时，MUST 按目录叶子 `eventType` 排除 `one`；`one` 根/叶子不得产出或胜出任何 expect（数量与时长皆无）。
- **同步**：无胜出 expect 时 pending 继续省略 expect 字段；指纹随清空自然更新（既有规则）。
- **布局**：热态卡在有胜出 expect 且展示倒计时区块时，将「预计约…」移到**倒计时正上方**（有大 logo 时为 logo 与倒计时之间）；MUST NOT 再放在标题区与 logo 之间。
- **不改**：间隔 `nextAt`、预约根、进行中计时 ETA（「预计约 HH:mm 结束」）、横屏省略叶子名等既有约定。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `event-expect-prediction`：明确 `one` 不得进入量样本、不得胜出 expect（修正 `predict-expect-amount-duration` 引入的能力；该 capability 尚未并入 v2.1.3 基线，以同仓活跃 change 与实现为准）。
- `smart-prediction-page`：有胜出 expect 时次级文案的**放置位置**相对倒计时 / logo 的约束。

## Impact

- 代码：`event_next_predictor.dart`（样本收集 / `countableExpectKind` / `attachWinningExpect` 需目录或 eventType 入参）、`smart_prediction_screen.dart` 卡片 Column 顺序。
- 依赖：假定 `predict-expect-amount-duration` 的 expect 模型与卡文案已存在于工作树；本变更为其行为修正，不新增 HTTP 字段。
- 无 Android 原生 / R8 改动；无新 debug tag。
- 兄弟仓 Go：无契约变更（仅客户端少报 one 的假 amount）。
