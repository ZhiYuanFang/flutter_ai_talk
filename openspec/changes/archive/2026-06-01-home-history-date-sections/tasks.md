## 1. 时间与条目模型

- [x] 1.1 在 `history_line_format.dart` 新增 `formatHistoryDaySectionLabel`、`formatHistoryTimeHm`
- [x] 1.2 `historyHomeRowDisplay` 时间列改用 `formatHistoryTimeHm`（展示时刻规则不变）
- [x] 1.3 新增 `HomeHistoryListEntry` 与 `buildHomeHistoryListEntries(List<HistoryRecord> itemsAsc)`

## 2. UI 组件

- [x] 2.1 新建 `HomeHistoryDateHeader`（日期分块行）与 `SliverPersistentHeader` delegate
- [x] 2.2 确认 `HomeHistoryTimelineTile` 时间列仅渲染 `HH:mm`（宽度可略收紧）

## 3. 主页列表重构

- [x] 3.1 `home_screen`：`ListView` → `CustomScrollView(reverse: true)` + 按日 `SliverMainAxisGroup`（pinned 头 + 记录列表）
- [x] 3.2 `fromBottom` 仅对记录行计数；保留 `HomeHistoryTopFadeMask`
- [x] 3.3 WS/SSE 更新 `_items` 后重建 entries，验证最新条仍在底部

## 4. 收尾

- [x] 4.1 运行 `openspec validate home-history-date-sections --strict`
- [x] 4.2 真机/模拟器：跨天数据、吸顶「昨天」、时间列 `20:00` 完整可见
