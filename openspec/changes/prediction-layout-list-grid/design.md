## Context

智能预测页已有每事件推演开关、纵向卡片、`下次 ·` + 相对时间、近 7 日折线（含 Y 轴）。并行 change `prediction-care-alert-marquee-list` 在 tip 与卡片区之间放全宽跑马灯。本变更改布局与开关模型，并与跑马灯并存。

## Goals / Non-Goals

**Goals:**

- 去掉推演开关；全事件始终推演。
- 右上角图标切换 list ↔ grid；默认 **grid**；本地持久化。
- 纵向：删除 `下次 ·` 前缀，保留相对时间行；7 日图 + Y 轴不变。
- 网格：2 列；X = 前天/昨天/今天；无 Y 轴；短相对时间文案。
- 跑马灯区域不受网格列影响（全宽）。

**Non-Goals:**

- 不改推演公式、range 拉取、留意规则阈值。
- 不做 3 列及以上网格。
- 不改小组件文案契约（可复用/新写 App 内短格式化函数）。

## Decisions

### D1：布局状态

- `PredictionCardsLayout { list, grid }`，默认 `grid`。
- SharedPreferences（或既有本地 store 模式）持久化；Riverpod `StateNotifier` / `AsyncNotifier`。
- 标题行：`智能预测` + `IconButton`；grid 时图标示意「切到列表」，list 时示意「切到网格」。

### D2：移除推演开关

- UI 去掉 Switch /「推演」标签。
- `buildSmartPredictionRows` / tip / 排序：**始终当作 enabled**（`disabledForecastIds` 视为空，或删除 provider 读写）。
- 旧持久化键可读后忽略，无需迁移弹窗。

### D3：文案

- 纵向：`formatWidgetPredictSubtitle(...)`（或等价），**不**加 `下次 ·` 前缀。
- 网格短文案（默认）：
  - overdue：`超时 ${n} 分钟` / `超时 ${n} 小时` / `超时 ${n} 天`（去「已」「约」）
  - upcoming：`${n} 分钟后` / `${n} 小时后` / `${n} 天后`（去「约」）
  - &lt;1 分钟：`超时 1 分钟` / `1 分钟后`

### D4：图表按布局

- **list**：窗口 `[today-6d, today]`（既有 7 日逻辑）；显示 Y 轴（3 刻度等既有规则）；触控 tooltip 可保留。
- **grid**：窗口自然日 `{today-2, today-1, today}`；`dailyPointsNearAnchorTod`（或等价）仅在这 3 日内取点；**隐藏 Y 轴标签与轴线**；X 仅 3 个日标签；图高更矮以适应双列。

### D5：网格布局

- `GridView` 或 `SliverGrid` / 手动 `Wrap`+两列 `Row`；`crossAxisCount: 2`；间距与玻璃卡风格对齐纵向。
- 奇数个事件：最后一格可单列占位或仅左列（实现选更简单者：最后一项左列、右列空）。

### D6：与跑马灯并存

- 页面结构：`标题(+图标) → tip → 留意跑马灯 → 卡片区(list|grid)`。
- 本 change **不实现**跑马灯，但布局代码不得把留意塞进 Grid。

## Risks / Trade-offs

- [双列图过挤] → 降图高、藏 Y、短文案。
- [用户找不到关推演] → 产品接受全开；无替代关闭入口。
- [两 change 同改 smart_prediction_screen] → apply 时先/后合并注意冲突，按结构分区改。

## Migration Plan

- 默认写 grid；旧推演关闭状态失效。
- 回滚：恢复 Switch + 仅 list。

## Open Questions

- （无）网格短文案用词已给默认，实现可微调空格。
