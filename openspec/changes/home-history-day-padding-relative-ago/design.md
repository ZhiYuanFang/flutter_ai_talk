## Context

- 日卡片：`home_history_scroll.dart` 中 `_buildDayRecordsCard` 为 `DecoratedBox` + `ClipRRect` + `Stack`（连线 + `Column` tiles），**卡片内容区当前无内边距**；卡片与列表之间已有 `horizontal: 12` 外边距。
- 相对时间：`formatHistoryRelativeAgo` 固定返回 `{h}时{m}分前`；tile 展示为 `[$label]`。
- 连线：`HomeHistoryDayTimelineLinks` 与 tiles 共用同一 `Stack`，圆心 Y 由 `rowSlotHeights` 累计。

## Goals / Non-Goals

**Goals:**

- 日卡片内容区增加统一 inner padding（建议 **horizontal 8、vertical 8**，与现有 `AppVisualTokens` / 卡片视觉一致，实现时可微调 ±2）。
- `formatHistoryRelativeAgo(instant, now)` 按差值分三档输出（见 proposal）。
- 内边距后连线与圆点仍对齐（连线层与 `Column` 同处 padding 内）。

**Non-Goals:**

- 修改日期吸顶 header、卡片外边距、badge 主题样式或「每事件最新一条」展示规则。
- 秒级刷新「刚刚」→「1分前」（仍沿用现有分钟级 tick）。

## Decisions

### 1. 卡片内边距结构

```text
DecoratedBox
  └ ClipRRect
       └ Padding(cardInnerPadding)   // 新增
            └ Stack
                 ├ HomeHistoryDayTimelineLinks (top: 0)
                 └ Column(tiles)
```

`cardInnerPadding` 常量置于 `_buildDayRecordsCard` 或 `HomeHistoryTimelineTile` 旁文档化；**不得**仅 pad `Column` 而不 pad 连线层。

### 2. 相对时间分档

基于 `now.difference(instant)`（负值钳 0）：

| 条件 | 返回值 |
|------|--------|
| `< 60s` | `刚刚` |
| `≥ 60s` 且 `inHours == 0` | `{m}分前`（`m = inMinutes.remainder(60)`，至少 1） |
| `inHours >= 1` | `{h}时{m}分前` |

展示：`HomeHistoryTimelineTile` 继续 `'[$relativeAgoLabel]'`。

### 3. 测试与 tick

- 单元测试不在本变更默认范围（仓库规则）；以 `flutter analyze` + 手工验证分档边界（59s、60s、59m、1h）。

## Risks / Trade-offs

- **[Risk] 卡片变高** → 仅每块 +16px 量级 vertical padding，可接受。
- **[Risk] 首/末行与圆角贴边** → padding 使内容离 `ClipRRect` 更远，改善圆角处裁切观感。
- **[Trade-off] 「刚刚」在 tick 前不变** → 与现有 1 分钟刷新一致；若需秒级可后续单独变更。

## Migration Plan

- 纯客户端 UI/文案；热重载即可验证。

## Open Questions

- （默认）inner padding 8px；若设计稿另有数值，实现阶段可替换常量。
