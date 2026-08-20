## Why

趋势中心现为单全屏柱图 + 自由日历选日 + 范围记忆，难以同时看到「近 N 日总量」与「某日日内分布」，且计次事件缺少发生时刻可视化。产品需要预设近 N 日、双图联动（总览 ↔ 选中日详图），并按事件类型（计时/计数/计次）区分画法。

## What Changes

- **BREAKING**：日期范围由自由起止日历改为预设文案 **近7日（默认）/ 近15日 / 近1个月**；**近3个月不出现**；**不再持久化**上次范围。
- **BREAKING**：去掉图表上方大 logo；事件 logo 置于选择行事件名左侧，且上/下图标题内亦带 logo；logo 飞入落点改为选择行左侧 logo。
- **BREAKING**：由单图改为双图——近 N 日总量趋势 + 选中某日详图；纵屏上下均分、横屏左右均分；各图标题在所属区域内横向居中并以事件色着色。
- 近 N 日图：展示 Y 轴且固定 **3** 刻度；柱状；柱顶量标**仅选中柱**显示；计次事件另在柱内按 24 小时比例放置散点。
- 某日详图：计时/计数为折线+折点量标；计次为 **0–24 时间轴**（无数值 Y）+ 凌晨/早/午/晚四段底（与事件色交叉）+ 发生点下细线与时刻文案。
- 选中日：默认今日、不记忆；换事件保持选中日；换范围时若选中日不在新区间则重置今日；选中日无数据时下图为**图表骨架**（不得空态文案）。
- 时间范围入口位置不变（标题行右侧），交互改为底部预设 Sheet。

## Capabilities

### New Capabilities

- `trends-dual-chart-layout`：双图布局、方向均分、图标题文案与选中日联动状态机、下图骨架态。
- `trends-count-day-timeline`：计次某日时间轴（四时段底、发生点、点下细线与时刻）。

### Modified Capabilities

- `trends-center-chart-header-actions`：去掉上方大 logo；选择行 logo+事件名；范围入口改为预设文案；展开箭头随事件色。
- `trends-center-date-range-ui`：预设近7/15/1个月；取消范围记忆与自由日历；默认近7日；跨度仍 ≤30 日。
- `trends-center-glass-bars`：近 N 日柱图增加 Y 轴（3 刻度）、选中柱顶标、计次柱内散点；不再作为页面唯一图表。

## Impact

- **Flutter**：`trends_screen.dart`、`trend_glass_bar_chart.dart`、`trends_date_range_*`、`trends_date_range_store.dart`、`trend_series_bucket.dart` / `remote_trends_repository.dart`（保留 raw 发生点）、`trends_event_logo_fly_overlay.dart` 落点、可能新增日详图/时间轴 widget。
- **API**：仍用现有 `GET /device/history/api/piece`；查询窗口为今日回溯 N 日（含今日），N∈{7,15,30}。
- **测试**：不新建 `**/test/**`；手工验证纵/横屏双图、三类事件画法、选中日与骨架。
- **Android**：不改原生，不强制 release APK。
