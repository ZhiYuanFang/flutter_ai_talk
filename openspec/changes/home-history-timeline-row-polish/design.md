## Context

- 行布局（现）：`圆点(14) | logo(16) | time(44) | 事件名 | 尾注`；`timelineDotCenterX = 2 + 7 = 9`。
- 连线：`home_history_day_timeline_links.dart`，`_lineWidth = 2`，纯色渐变无 alpha。
- 列表记录：`HomeHistoryScroll` 按日分组渲染；全局索引 `fromBottom` 仍用于圆点大小/字号渐隐，**不再**作为相对时间标签的唯一条件。
- 展示时刻：`historyHomeDisplayInstant(record)`（与行内 `HH:mm` 一致）。
- 事件身份：与 `lookupEventForRecord` / `history_record_metric` 一致 — `historyRecordEventId(record)` 非空则用其字符串；否则 `record.eventName.trim()`；空名视为独立键 `''`（极少见，仍参与比较）。
- 主题：`AppVisualTokens.onShell` / `recordsCardColor` 等。

## Goals / Non-Goals

**Goals:**

- 新顺序：`时分 | 圆点 | logo | 事件名 | 尾注`。
- 连线 1px，渐变两端色均乘 0.7 alpha。
- 在**当前主页历史列表的全部已加载记录**上，对**每个不同事件键**，仅**展示时刻最新**的一条在 tile 下方显示相对时间 chip；同屏可有多条 badge。**进行中计时**记录（`isActiveTimingRecord`）**排除**在 badge 展示之外。
- 文案：`{hours}时{minutes}分前`（本地 `now - instant`，不足 1 小时仍显示 `0时{m}分前`，首版用 `diff.inHours` 与 `diff.inMinutes % 60`，负值钳 0）。

**Non-Goals:**

- 每条历史都显示相对时间（仅各事件的「列表内最新」一条）。
- 跨分页/未加载历史的「全局最新」（仅以当前列表数据为准）。
- 修改日期吸顶 header 或编辑 Sheet。
- 改变事件名字号阶梯（`fromBottom` 渐隐规则保持）。

## Decisions

### 1. 行内布局常量

| 常量 | 说明 |
|------|------|
| `timelineTimeColumnWidth` | 44（沿用 `_timeWidth`） |
| `timelineTimeToDotGap` | 4 |
| `timelineDotColumnWidth` | 14 |
| `timelineDotCenterX` | `padding + timeWidth + gap + dotWidth/2` → **2+44+4+7=57** |

`HomeHistoryTimelineTile` Row children 顺序调整；`home_history_day_timeline_links` 使用新 `timelineDotCenterX`。

### 2. 连线

```dart
static const lineWidth = 1.0;
static const lineColorOpacity = 0.7;
// gradient colors: [c0.withOpacity(0.7), c1.withOpacity(0.7)]
```

### 3. 相对时间文案

`history_line_format.dart`:

```dart
String formatHistoryRelativeAgo(DateTime instant, DateTime now) {
  var d = now.difference(instant);
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}时${m}分前';
}
```

展示用 `【$text】` 或 UI 用圆角容器包一层，规格写文案含「时」「分」「前」。

**布局（bugfix）**：含 badge 行使用 `slotHeightFor`（`rowHeight + timelineBadgeSlotHeight`）占满列表槽位，badge 在行内、不与下一 item 重叠；`HomeHistoryDayTimelineLinks` 按 `rowSlotHeights` 累计计算圆心 Y，连线不断裂。行与 badge 共用外层 `InkWell`。

### 4. 「每种事件的列表内最新」判定

在 `HomeHistoryScroll` 构建列表前（或 `_buildDayRecordsCard` 外层一次），遍历**当前传入的全部 `HistoryRecord`**（与列表展示集合相同，含各日 `recordsOldestFirst` 展平顺序无关）：

1. `eventKey(record) = historyRecordEventId(record).isNotEmpty ? id : record.eventName.trim()`
2. 对每条记录 `r`，`instant = historyHomeDisplayInstant(r)`
3. 维护 `Map<String, String> newestIdByKey`：若键首次出现或 `instant` **严格晚于** 已存记录的 instant，则更新为 `r.id`；若 instant **相等**，保留**列表顺序上更靠底部**的一条（与 `fromBottom` 更小 / 全局索引更大一致，实现时可在相等时 prefer 更大 `recordIndex` 或显式比较 `fromBottom`）。

构建 tile 时：

```dart
showRelativeAgo: newestIdByKey[eventKey(record)] == record.id
    && !isActiveTimingRecord(record);
```

**进行中计时排除**：`isActiveTimingRecord(record)` 为真（`eventNumber == 0` 且 `endTime` 未设置）时，**无论**该条是否为该事件键在列表内的最新一条，`showRelativeAgo` MUST 为 false。若该事件仅有一条且为进行中计时，则该事件键**无** badge；若最新一条为进行中计时、同键存在更早已结束记录，badge **也不**回退到较早记录（仅最新且非进行中才显示）。

**示例**：列表含「喂奶」10:00、「睡觉」09:00、「喂奶」08:00 → 仅 10:00 的喂奶行与 09:00 的睡觉行显示 badge（前提均非进行中计时）。

### 5. 标签 UI

- `showRelativeAgo == true`：`Column(mainAxisSize: min, children: [row, badge])`。
- 背景：`onShell.withValues(alpha: 0.2)` — 与正文一致、随主题。
- 文字：`onShell` full opacity；`fontSize: eventFontSize - 1`。
- 内边距：`horizontal 8, vertical 3`；`borderRadius 6`。
- 对齐：与事件名左缘对齐（`padding + time + gap + dot + logo + gaps`）。

### 6. 刷新

`HomeHistoryScroll` 在存在任意 `showRelativeAgo` 行时，与 active timing 共用或独立 `Timer.periodic(1min)` 触发 badge 重建；秒级精度非必须。

## Risks / Trade-offs

- **[Risk] 多事件 badge 增加列表高度** → 每种事件至多一行额外 ~22–26px，通常可接受。
- **[Risk] dotCenterX 变更导致连线错位** → 常量单点维护，与 painter 同步改。
- **[Risk] 同 eventId 不同 eventName 的脏数据** → 以 eventId 为准分组，与 catalog 查找一致。
- **[Trade-off] 0时0分前** → 刚创建记录显示「0时0分前」；可选「刚刚」留待后续。

## Migration Plan

- 纯 UI；手工验证：多事件各一条 badge、同事件仅最新、非该事件最新无标签、**进行中计时不显示 badge**（含其为该事件最新一条时）、同日连线、深浅色主题。

## Open Questions

- （已决）相对时间为**列表内按事件键的最新一条**，非全局唯一 `fromBottom == 0`。
