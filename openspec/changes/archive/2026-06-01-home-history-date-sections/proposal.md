## Why

主页历史时间轴将日期与时间挤在约 50px 宽的时间列（如「昨天20:00」），易被截断且难扫读。用户需要按**本地自然日**分块：先显示日期行（如「昨天」），其下记录行仅显示 **HH:mm**；日期行在滚动时**吸顶**，便于对照时间点所属日期。须保留既有「最新在底部」、向上变弱与顶部渐变等产品约束。

## What Changes

- 拆分时间展示：`formatHistoryDaySectionLabel`（日期分块行）与 `formatHistoryTimeHm`（记录行左列，仅 `HH:mm`）。
- 将 `_items` 转为按日分组的扁平列表（记录行 + 日期头），适配 `reverse: true` 下「新在底、日在该日块上方」的视觉顺序。
- 历史列表由固定 `itemExtent` 的 `ListView` 改为 `CustomScrollView` + **pinned** 日期 `SliverPersistentHeader` + 记录 `SliverList`（或等价结构）。
- 日期头样式与记录行区分；记录行仍用紧凑时间轴（logo、事件色、尾注）；`fromBottom` 层次**仅**作用于记录行。
- 详情页与 `historyLineSpans` 可继续使用完整 `formatHistoryInstant`，不在本变更强制修改。

## Capabilities

### New Capabilities

- `home-history-date-sections`：主页历史按日分块、日期吸顶、记录行仅显示时分。

### Modified Capabilities

- `home-history-timeline-row`（变更内 delta）：时间列改为仅 `HH:mm`；与日期头分行展示。
- `home-input-history-sse`（变更内 delta）：历史区列表结构允许日期头 + Sliver 吸顶，仍须最新锚定底部。

## Impact

- `app/lib/data/history_line_format.dart`
- `app/lib/ui/home_screen.dart`
- `app/lib/ui/home_history_timeline_tile.dart`
- 新建 `app/lib/ui/home_history_date_header.dart`（或等价）
- 新建/扩展列表条目构建逻辑（如 `home_history_list_entries.dart`）
- OpenSpec delta：`home-history-compact-timeline` 相关能力的行为补充
