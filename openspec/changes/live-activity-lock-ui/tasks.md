## 1. 契约与 Attributes

- [x] 1.1 更新 `LIVE_ACTIVITY.md`：Timing 固定字段含 `eventId`；推送不带 logo/color；`startTime`/`nextAt` 为 unix 秒；客户端按 App Group 索引解析视觉
- [x] 1.2 `PredictTimingAttributes` 增加 `eventId`（缺省解码兜底，兼容旧推送）

## 2. App Group 视觉索引（Flutter）

- [x] 2.1 新增写入 App Group 的 `eventId → color / logoFile` 索引（建议键 `laEventVisuals`），复用 `widgetLogoFileForEvent` 预热 logo
- [x] 2.2 在 catalog 同步 / home-widget enrich / LA `startIfEligible`（或等价开通路径）触发索引刷新；缺失时允许 Extension 兜底

## 3. Extension UI 与共用 helper

- [x] 3.1 从 `PangbaoWidget.swift` 抽取 `loadLogoImage` / `eventLogo` / `parseColor` 及 LA 用「过深提亮」到共享 Swift 文件；桌面入口改调共用实现
- [x] 3.2 Extension 按 `eventId` 读 App Group 索引加载 logo 与提亮后事件色
- [x] 3.3 重做 Imminent / Timing 锁屏与 Island：左图、中标题、右大字时间；删除右箭头；整卡 `widgetURL` 保留
- [x] 3.4 Imminent：倒计时至 `nextAt`；到点显示「已过时」
- [x] 3.5 Timing：右侧大字已计时（优先系统 `timerInterval` 或等价），不以标题下小字展示

## 4. 验收

- [x] 4.1 说明：对端 Timing 须带 `eventId` 且时间字段为秒；本仓不实现 Go fanout
- [x] 4.2 真机/模拟器目视：双侧布局、无箭头、有缓存时出事件图与事件色、Imminent 过期「已过时」；`dart analyze` 相关 Dart 无新增问题
