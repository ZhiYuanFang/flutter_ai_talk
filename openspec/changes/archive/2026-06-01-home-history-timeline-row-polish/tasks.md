## 1. 文案与格式

- [x] 1.1 `history_line_format.dart` 新增 `formatHistoryRelativeAgo(instant, now)`

## 2. 行布局（时分在圆点前）

- [x] 2.1 调整 `HomeHistoryTimelineTile` 子节点顺序与 `timelineDotCenterX` 等常量
- [x] 2.2 更新 `home_history_day_timeline_links` 使用新圆心 x

## 3. 连线样式

- [x] 3.1 线宽 1px、渐变设色 alpha 0.7

## 4. 相对时间标签（按事件最新）

- [x] 4.1 `HomeHistoryScroll`：遍历当前列表全部记录，按 `historyRecordEventId`（非空）或 `eventName.trim()` 分组，用 `historyHomeDisplayInstant` 选出各键最新 `record.id`（同时刻 prefer 更靠列表底部）
- [x] 4.2 `_buildRecordTile` 传入 `showRelativeAgo: record.id == newestIdForKey && !isActiveTimingRecord(record)`；`HomeHistoryTimelineTile` 在 `showRelativeAgo` 为 true 时在行下渲染主题 chip（背景 onShell 0.2、字号小于事件名）
- [x] 4.4 验证：进行中计时（`eventNumber == 0` 且 `endTime` 未设置）为某事件最新一条时不显示 badge；同键最新为进行中时不回退到较早记录
- [x] 4.3 存在任意 `showRelativeAgo` 行时，`HomeHistoryScroll` 每分钟 tick 刷新所有可见 badge（可与现有 tick 合并）

## 5. 验证

- [x] 5.1 `flutter analyze` 相关文件
- [x] 5.2 手工：行顺序、连线、同事件仅最新有标签、多事件各一条标签、进行中计时无 badge、深浅色主题、点击与停止

## 6. Bugfix（连线与点击）

- [x] 6.1 相对时间 badge 不撑开 timeline 行槽位（`OverflowBox` + 固定 `rowHeight`，连线几何不变）
- [x] 6.2 行与 badge 共用同一 `InkWell`，点击 badge 打开编辑 Sheet

## 7. Bugfix（行间距）

- [x] 7.1 含 badge 行使用 `slotHeightFor` 占满布局高度，移除 `OverflowBox` 行间重叠
- [x] 7.2 `HomeHistoryDayTimelineLinks` 按 `rowSlotHeights` 累计计算圆心 Y，连线不断裂

## 8. Bugfix（badge 背景）

- [x] 8.1 相对时间标签背景改用 `TextStyle.backgroundColor` 紧贴文字，移除 chip 内边距与圆角容器

## 9. Bugfix（badge 文案与样式）

- [x] 9.1 文案括号改为半角 `[xx时xx分前]`；背景恢复 `DecoratedBox` + 圆角与内边距
