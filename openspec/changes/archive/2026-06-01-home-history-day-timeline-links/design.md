## Context

- 主页历史：`HomeHistoryScroll` 按 `buildHomeHistoryDayGroups` 分日；`_buildDayRecordsCard` 将同一日 `recordsOldestFirst` 渲染为 `Column` of `HomeHistoryTimelineTile`。
- 每行左侧 14px 宽区域内有圆点（5–7px），颜色为 `resolveEventColor(context, event)`。
- 列表正向滚动，日块在视觉上旧→新；卡片内 `recordsOldestFirst` 亦为时间升序。
- 已有 `home-history-compact-timeline` 变更定义紧凑行高与圆点；本变更为纯 UI 增强。

## Goals / Non-Goals

**Goals:**

- 同一日卡片内，相邻行圆点中心用竖线连接。
- 线段颜色：上端 = 上一行事件色，下端 = 下一行事件色（`LinearGradient` 沿竖向）。
- 线宽适中（约 2px），圆角/端点可选圆头；不干扰行点击与水波纹。
- 首条记录上方、末条记录下方不延伸多余线段。

**Non-Goals:**

- 跨日历日连线。
- 跨日块全局连续时间轴。
- 修改历史数据、WS 或编辑 Sheet 行为。
- 动画（飞行动画期间连线可静态重绘，无需特殊动效）。

## Decisions

### 1. 绘制层级

在 `_buildDayRecordsCard` 内用 `Stack`：

```
Stack
├── Positioned.fill → CustomPaint / _DayTimelineLinksPainter（连线）
└── Column → 现有 tiles（透明圆点列背景，圆点仍由 tile 绘制）
```

连线 painter 输入：相邻行事件色列表、行高 `HomeHistoryTimelineTile.rowHeight`、圆点中心 x（与 tile 内 dot 对齐，约 7px from card inner left + padding）。

**备选**：每行 tile 自绘「下半段/上半段」线 — 渐变在行间拆分难，否决。

### 2. 渐变方向

`recordsOldestFirst` 索引 `i` 与 `i+1` 之间：gradient 从 `color[i]`（top）到 `color[i+1]`（bottom)。与阅读方向一致（上旧下新）。

### 3. 颜色来源

对每条 record 调用 `lookupEventForRecord(catalog, record)` + `resolveEventColor`；未知事件用 `Theme.colorScheme.outline` 或现有 fallback。

### 4. 对齐常量

抽取或复用：

- `kTimelineDotColumnWidth = 14`
- `kTimelineDotCenterX = 7`（列内居中）
- `kTimelineRowHeight = 37`

Painter 计算第 `i` 行圆点中心：`dy = i * rowHeight + rowHeight / 2`。连线从 `dy_i + dotRadius` 到 `dy_{i+1} - dotRadius`（避免穿过圆点实心）。

### 5. 性能

- 每个日卡片一个 `RepaintBoundary` + `CustomPaint`；记录数通常 < 50/日。
- `shouldRepaint` 仅在 records 或 eventCatalog 色变化时 true。

## Risks / Trade-offs

- **[Risk] 行高变更导致错位** → 连线与 tile 共用 `rowHeight` 常量，单点定义。
- **[Risk] ClipRRect 卡片圆角裁切连线** → 连线在 `ClipRRect` 内，padding 内绘制，不贴边。
- **[Trade-off] 仅竖直线** → 足够表达时间轴；曲线增加复杂度收益有限。

## Migration Plan

- 纯客户端 UI 发布；无数据迁移。
- 手工验证：单日 1 条（无线）、2 条（一条渐变线）、多条；跨日两块各自独立；深色/浅色主题。

## Open Questions

- （默认）线宽 2px、圆点与线间隙 1px；实现阶段可按视觉微调。
