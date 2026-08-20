## Why

趋势中心近 N 日柱图与某日折线图仅有数值刻度，缺少稳定的纵轴单位提示；用户需依赖柱顶/折点量标才能判断「时长 / 次 / 自定义单位」。在 Y 轴顶部增加固定单位文案，可与首页小时趋势的 `yAxisHint` 体验对齐，并明确计数空单位时的回退文案。

## What Changes

- 在**有数值 Y 轴**的趋势图（近 N 日柱图、计时/计数某日折线图）Y 轴**顶部**展示固定单位文案：
  - 计时（`time`）→ `时长`
  - 计数（`number`）→ `EventDefinition.unit`；trim 后为空则 → `量`
  - 计次（`one`）→ `次`（仅 N 日柱图；某日详图为时间轴时不适用）
- 计次某日**时间轴** MUST NOT 增加数值 Y 轴单位文案。
- **MODIFIED**：相对既有「界面 MUST NOT 额外展示纵轴含义说明」约束，改为允许并要求上述**固定单位短文案**（非「纵轴：小时」类长说明）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `trends-center-glass-bars`：有数值 Y 的趋势图 MUST 在 Y 顶展示按事件类型解析的单位文案；计数空 `unit` 回退「量」；时间轴除外。

## Impact

- **Flutter**：`trend_metric_format.dart`（或同级）解析单位文案；`trend_n_day_bar_chart.dart`、`trend_day_detail_chart.dart`（折线态）布局；`trends_screen.dart` 传 `eventType`/`unit`（若尚缺）。
- **不改**：后端契约、Android 原生、首页小时趋势文案（可复用解析思路，本变更不强制改首页）。
- **测试**：不新建 `**/test/**`。
