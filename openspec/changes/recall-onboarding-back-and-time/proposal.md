## Why

量身定做卡片把「不记得了，跳过」放在左下，与「回看上一张并改草稿」抢位；上次时间又拆成日期、时分两层 Sheet，默认还先逼人选日期。需要把跳过收到标题行、用上一步保留草稿回看、未改表单不得空点确认，并把时间收成单层、默认时分。

## What Changes

- 左下「不记得了，跳过」改为「上一步」：回到**上一张表单**且**按根保留草稿**；第一张卡、思考播放中、收尾页均**不得**展示上一步。
- 「跳过」挪到卡片**右上角**，与根事件名同行（短文案「跳过」）；语义仍为关该根推演、不播长思考、进入下一张。先跳过再上一步后确认时，**必须**重新打开该根推演。
- 点击确认时，若该卡时间/间隔相对进入时的默认快照**均未改过**，**不得**写种子；须在确认按钮上方以小红字提示「请认真回忆事件」。
- 「上次发生/结束时间」改为**一层**玻璃 Sheet：左上角时分（点击切换日期滚轮），中间为时分或日期滚轮，**默认时分**；一次确定写出完整时刻且不晚于现在。
- 「该事件包含」保持只读、不选叶子；**不得**再用按钮/`Chip` 形态；每条子事件 **必须** 展示 `EventLogo` 与名称。

## Capabilities

### New Capabilities

- `prediction-recall-card-nav`：上一步/草稿、跳过标题行位置、未改表单拦截确认、确认时恢复推演开关。

### Modified Capabilities

- `prediction-recall-card-ux`：只读子事件须带 logo，且不得呈按钮形态。
- `prediction-recall-pickers`：上次时间由「先日期再时分」改为单层时分/日期切换 Sheet，默认时分。
- `prediction-recall-onboarding`：跳过仍必须提供，但入口改为标题行；切页增加程序化「上一步」（思考中与收尾除外）。

## Impact

- UI：`app/lib/ui/prediction_recall_onboarding_panel.dart`；时间 Sheet 复用 `home_history_time_wheel.dart` 玻璃日期/时分滚轮，在同族 `showGlassAdaptiveBottomSheet` 内切换，不改添加事件表单的双入口。
- 状态：按根缓存草稿；确认 `upsertSeed` 且 `setEnabled(rootId, true)`；跳过仍 `setEnabled(rootId, false)`。
- 对照：基线 `openspec/specs/v2.1.0.md` 尚未收录量身定做（能力在未归档的 `prediction-recall-onboarding`、`recall-onboarding-card-ux`、`recall-picker-atoms`）；本变更增量叠在这些 change 之上，不改种子合成与真历史追上丢弃。
- 无后端契约；不改 `app/android/**`；不新建 `**/test/**`。
