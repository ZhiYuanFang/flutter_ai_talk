## Why

智能预测页事件卡片在「有历史但暂无 nextAt」（样本不足、推演关闭等）或 overdue 时，用户看不到上次真实发生时刻；第二行相对时间（含「超时」）与开关说明均靠右堆叠，可读性差。产品要求在热态卡片上统一展示「上一次{事件名}：时间」，并理顺 caption 行左右布局。

## What Changes

- `SmartPredictionRow` 增加 `lastAt`（与 `predictAllUpcoming` 解耦，按 root 历史用 `occurrenceInstant` 计算）。
- `_PredictionEventCard`：热态卡片在 caption 区下方靠左展示 `上一次{事件名}：{formatWidgetLastAt}`；列表态与网格/瀑布态均适用。
- **豁免**：进行中计时卡片、冷态骨架（未登录/未绑定 demo）不展示「上一次」。
- **推演关闭**卡片仍展示「上一次」（与半透明样式并存）。
- 第二行 caption：相对时间/超时文案 **靠左**，「开启/关闭{事件名}预测」 **靠右**（`spaceBetween`），替代当前整段右对齐。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `smart-prediction-page`：预测事件卡片 caption 布局与「上一次」展示规则。

## Impact

- **Flutter**：`smart_prediction_rows.dart`、`smart_prediction_screen.dart`（`_PredictionEventCard`）、可选 `format_widget_relative_time.dart` 标签 helper。
- **API / Android**：无。
- **测试**：不新建 `**/test/**`；手工验收列表/网格、overdue、推演关、计时中、骨架。
