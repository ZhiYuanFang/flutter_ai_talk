## Context

- 现状：`RemoteTrendsRepository.loadCatalog` + `loadSeries` 已存在；`TrendsScreen` 在 `_load` 后为**每个**目录项拉取 `piece` 并以纵向列表多卡片展示单折线。
- 目标：改为**单事件选择** + **折线 + 柱状**；计时事件用量为时段。

## Goals / Non-Goals

**Goals:**

- 事件列表仍来自服务端目录接口；UI 上单选后仅加载当前 `eventId` 的 `piece` 数据。
- 从 `piece` 列表项解析 `eventNumber`、`startTime`、`endTime`，映射为 `(t, lineValue, barValue)` 或共享 `t` 的两组序列；**计时类** `barValue`（及若与折线共用 Y 轴时的折线值）来自时长计算。

**Non-Goals:**

- 不在本变更中重新定义网关 `event/options` 与 `piece` 的字段契约（仅消费现有 camelCase / 既有解析）。
- 不在此引入复杂预测或聚合算法（按条展示为主；若需按日聚合可在后续变更提出）。

## Decisions

1. **选择器形态**
  - 优先 **DropdownButton / MenuAnchor** 绑定 `TrendCatalogItem` 列表；无数据时展示空态与重试。默认选中第一项或「未选择」占位，由规格固定一种避免白屏。
2. **折线与量柱**
  - 使用 `fl_chart`：`LineChart` + `BarChart` 上下排列，或 `ComboChart` 风格（若库支持有限则上下栈叠，共享横轴时间标签）。横轴为记录时间或桶化后的时间标签（首版可按点索引 + `DateFormat` 于轴标签）。
3. **量值计算（核心）**
  - 设 `n = eventNumber`（整型）。若 `n != 0`：`barValue = n.toDouble()`（或与现有 `TrendPoint.value` 一致）。若 `n == 0`：解析 `startTime`、`endTime`（与 `history_line_format.parseHistoryInstant` 语义一致）；若结束有效，`barValue` 为 **`(end - start)` 换算为小时**（`double`）；若结束无效则 `barValue = 0` 且可选不在柱上显示（仍保留折线点策略在规格中写死）。
4. **折线值**
  - 首版可与量柱共用同一标量（简单）或折线为累计/移动平均（**非目标**）；**默认**折线与柱均使用同一 `metric`（计时为**小时**，计数为次数）以降低歧义，后续若产品拆分再迭代。
5. **性能**
  - 切换事件时取消或忽略过期异步结果；不对全目录预拉 `piece`（与现状「全量预拉」对比为改进点）。

## Risks / Trade-offs

- **[Risk] `piece` 项缺少 `endTime`** → 计时条目的量为 0 并可在 Debug 日志提示。  
- **[Risk] 与详情页「0 表示未结束」一致** → 复用同一解析函数，避免两套 0 语义。

## Migration Plan

- 纯客户端交互与计算变更；无服务端迁移。

## Open Questions

- 量柱 Y 轴单位：计时类为 **小时**；计数类为 **次数**；轴标签格式化与实现一致。

