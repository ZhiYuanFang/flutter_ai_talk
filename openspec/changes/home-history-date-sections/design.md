## Context

- 现状：`home_screen` 使用 `ListView.builder(reverse: true, itemExtent: 34)`；`historyHomeRowDisplay` → `formatHistoryInstant` 合并日+时。
- `_items` 为时间**升序**（旧→新）；`itemBuilder` 用 `count - 1 - index` 使 index 0 在视觉底部为最新。
- 规范：`home-input-history-sse` 要求最新在底、向上变弱；`HomeHistoryTopFadeMask` 包在列表外。

## Goals / Non-Goals

**Goals:**

- 每个本地自然日一块：**pinned 日期行** + 多条记录行（左列 `HH:mm`）。
- 日期文案：`今天` / `昨天` / `M月D日` / `Y年M月D日`（与现有 `formatHistoryInstant` 的「日」规则一致，不含时分）。
- 滚动时当前区块的日期行吸顶于历史区可视区域上沿（Material `pinned: true`）。
- 保留 reverse 语义：最新记录在输入区附近；WS/SSE 合并逻辑不变。

**Non-Goals:**

- 不改历史 API、`pageSize`、详情页主排版。
- 不新增第三方 sticky 包（使用 Flutter 内置 Sliver）。
- 不要求「今天」一定显示日期头（默认可与「昨日」等同样展示 `今天`，若与上方「今日」汇总重复可再调）。

## Decisions

### 1. 时间字段拆分

| 用途 | 函数 | 示例 |
|------|------|------|
| 日期头 | `formatHistoryDaySectionLabel(t, now)` | `昨天` |
| 记录左列 | `formatHistoryTimeHm(t)` | `20:00` |

记录行展示时刻的选取规则与现 `historyHomeRowDisplay` 一致（按 `eventNumber` 用 end/start/createdAt）。

### 2. 扁平条目与 visual 顺序

```dart
sealed class HomeHistoryListEntry { record | dayHeader }
```

构建步骤：

1. 将 `_items` 按本地自然日分组（`DateTime(y,m,d)`）。
2. 日从**新到旧**遍历；日内记录从**新到旧** push `record`。
3. 该日记录 push 完毕后 push `dayHeader(label)`。

在 `reverse: true` 的 Sliver 子树中，按上述顺序排列，使 **index/visual 底部 = 最新记录**，日期头紧贴在该日最旧记录**上方**（更靠列表顶部）。

### 3. 滚动结构

```
HomeHistoryTopFadeMask
  └─ CustomScrollView(reverse: true)
       └─ for each day (newest → oldest):
            SliverMainAxisGroup[
              SliverPersistentHeader(pinned: true) → 日期行,
              SliverList → 记录行 (固定高度 34),
            ]
```

- 去掉全局 `itemExtent`；记录 tile 仍 `rowHeight = 34`。
- 日期头高度约 28–32px；delegate `minExtent == maxExtent`。
- `fromBottom`：仅对记录行递增计数（日期头不参与），用于字号/对比度梯度。

### 4. 吸顶行为

- 使用 `SliverPersistentHeader(pinned: true)`；同一时刻可视区顶部为**当前滚入区块**的日期标签。
- 若 `reverse` + pinned 联调异常，备选：历史区顶部 Overlay + `ScrollController` 计算当前日（记入 tasks 风险项，非首选）。

### 5. 与今日汇总的关系

- 「今日」汇总 panel 仍在列表上方；日期头可显示「今天」，与汇总 complementary（汇总=聚合数字，日期头=列表分节）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| reverse + Sliver 顺序错误 | 跨天假数据录屏；单测构建扁平序列 |
| 渐变遮罩作用于 header | ShaderMask 仅包 scrollable；header 背景不透明 |
| 新记录插入 | 重建 entries；保持 append `_items` 末尾 |
| Web pinned 表现 | Chrome 冒烟 |

## Migration Plan

无持久化迁移；发版后即新列表 UI。

## Open Questions

- 是否在首个自然日为「今天」时隐藏日期头（仅显示非今日）——**默认显示「今天」**，与联调反馈可再改。
