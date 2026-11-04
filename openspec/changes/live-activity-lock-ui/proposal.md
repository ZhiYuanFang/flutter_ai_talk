## Why

锁屏 Live Activity（Imminent / Timing）目前仅展示 BrandLogo、灰阶小字与右箭头：无事件图、无事件色、计时挤在标题下方且易卡在 `00:00`（载荷起点问题）。产品需要双侧统一为「左图 + 中文案 + 右侧大字时间」、本地按 `eventId` 解析视觉，并改善深色底上的对比度。

## What Changes

- **Imminent / Timing 锁屏与 Dynamic Island 布局**：去掉右箭头；左侧事件 logo（缺失则色球/品牌兜底）；中间标题；右侧大字时间（垂直居中）。
- **Imminent**：右侧为距 `nextAt` 的倒计时；到点后显示「已过时」，不再负计时。
- **Timing**：右侧为自 `startTime`（unix 秒）起的已计时；优先系统计时 API，布局为大字靠右。
- **视觉解析**：推送 **不** 下发 logo/color；Go 保证带 `eventId`（Timing 须补）；Flutter 将 catalog 色与 App Group `home_widget_logos/{id}.{ext}` 预置到 Extension 可读索引，展示时 Extension 按 `eventId` 查找。
- **对比度**：事件色过深时在 LA 深色 tint 上提亮后再用于文案。
- **契约文档**：更新 `LIVE_ACTIVITY.md`；本仓不修 Go 扇出实现，但规格注明对端 Timing `eventId` 与时间单位（unix 秒）依赖。
- **非目标**：不改 token 注册路径；不本地 `Activity.request`；不下发远程图 URL。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-imminent-live-activity`：锁屏 UI 从「品牌 logo + 即将发生 + 右箭头」改为「事件图 + 标题 + 右侧倒计时/已过时」；视觉按 `eventId` 本地解析。
- `predict-timing-live-activity`：锁屏 UI 从「品牌 logo + 小字已计时 + 右箭头」改为「事件图 + 标题 + 右侧大字已计时」；依赖推送 `eventId`；视觉本地解析。

> 说明：上述 capability 已在未归档 change `predict-ios-live-activity` 等中落地，尚未并入 `v2.1.4` 基线；本变更对其 Requirement 做 MODIFIED delta。

## Impact

- iOS：`PredictLiveActivityViews.swift`、`PredictLiveActivityAttributes.swift`（Timing 增加 `eventId` 解码）、从 `PangbaoWidget.swift` 抽取共用 logo/色 helper、`LIVE_ACTIVITY.md`
- Flutter：App Group 事件视觉索引写入；logo 预热（复用 `widgetLogoFileForEvent`）；触发点与 home-widget / catalog 同步对齐
- 对端 `go_ai_talk` / `predict-live-activity-push`：Timing 起活动须带 `eventId`；`startTime`/`nextAt` 为 unix **秒**（修 00:00）；**不得**要求推送 logo/color
- Android / Web：无
