## Why

`trends-dual-chart-ux` 真机验收暴露：返回键不对齐且浅色不可见、日期入口不像可点控件、点柱无法驱动下图、折线空态画幽灵线且零值硬连、非时间轴缺事件色轴线、计次时间轴落点/时刻位置需微调。本变更在双图能力上做验收补丁，不扩大范围预设或数据契约。

## What Changes

- 返回键纳入选择行纵向居中；图标色随壳语义（浅色为深色字，非写死白）。
- 日期范围入口改为圆角底 chip，右侧带向下箭头。
- 近 N 日柱图与某日折线图：X/Y 轴线使用事件 accent。
- **FIX**：点击近 N 日柱 MUST 更新选中日并刷新某日详图（修复 fl_chart TapUp spot 为空）。
- 计时/计数折线：无数据时展示空坐标系（x 0–24、y 0–10），MUST NOT 画默认/幽灵折线；有数据时仅连接真实非零点（参考预测页，避免零值硬连）。
- 计次时间轴：发生点在四段背景带垂直中心；点下细线长度保持现状；时刻文案留在背景带内（不得跨出带外）；轴刻度可略下移与带分离。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `trends-dual-chart-layout`：chrome 行对齐与返回色、日期 chip、点柱联动。
- `trends-center-glass-bars`：非时间轴事件色轴线；折线空态与有点连线规则。
- `trends-count-day-timeline`：落点居中、时刻在带内、细线长度不变。

## Impact

- **Flutter**：`trends_screen.dart`、`trend_n_day_bar_chart.dart`、`trend_day_detail_chart.dart`；可能用 `AppColor.textPrimary`。
- **依赖**：仍基于 `trends-dual-chart-ux` 已落地的双图结构。
- **测试**：不新建 `**/test/**`；不改 `app/android/**`。
