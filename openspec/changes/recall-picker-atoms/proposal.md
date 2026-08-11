## Why

量身定做里「上次时间 / 大概多久一次」仍用系统 `CupertinoModalPopup` 白底滚轮，与添加事件玻璃 Sheet 时分轮、用量单滚轮风格分裂，重复实现且浅色主题下观感不一致。需要共用原子壳与单滚轮交互，间隔与用量同为「单滚轮单选」。

## What Changes

- 量身定做「大概多久一次」改为与用量一致的玻璃 Sheet + **单列滚轮**（数值域仍为间隔分钟，不得套用 5–500 ml 档）。
- 量身定做「上次时间」改为复用添加事件侧玻璃时间/日期原子（需覆盖日期+时刻；不得再走系统白底 `CupertinoDatePicker` popup）。
- 抽取可复用的单滚轮玻璃 Sheet 原子（或等价），用量与间隔共用壳；用量档位逻辑仍由 `HomeEventNumberPicker` 特化承载。
- 不新增量身定做「喂养用量」业务字段。

## Capabilities

### New Capabilities

- `prediction-recall-pickers`：量身定做时间/间隔选择器与添加事件玻璃原子对齐的行为契约。

### Modified Capabilities

- （无）

## Impact

- UI：`prediction_recall_onboarding_panel.dart`；可能新增通用单滚轮 Sheet；复用 `showGlassAdaptiveBottomSheet`、`home_history_time_wheel` 日期/时分 Sheet、`HomeEventNumberPicker` 视觉约定（`fieldFill` / `textOnSheet` / selectionOverlay）。
- 无后端契约变更；回忆种子仍为 `lastAt` + `interval`。
