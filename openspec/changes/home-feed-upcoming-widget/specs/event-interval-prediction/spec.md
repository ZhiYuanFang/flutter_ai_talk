## ADDED Requirements

### Requirement: Client SHALL infer next event time from weighted interval history

The Flutter client SHALL compute a predicted next occurrence time (`nextAt`) per distinct `eventId` from locally available `HistoryRecord` items by analyzing inter-occurrence intervals with time-of-day bucketing, recency weighting, and age-adjusted half-life. The client MUST NOT call backend APIs solely for widget prediction.

客户端 MUST 基于本地历史记录推断各 `eventId` 的下一次触发时刻 `nextAt`，采用分时段桶、时间衰减权重与月龄自适应半衰期；不得为小组件预测单独请求后端。

#### Scenario: 使用发生时刻构建间隔

- **WHEN** 预测模块处理 `one` 或 `number` 类型记录
- **THEN** 发生时刻 MUST 取 `startTime`，缺失时用 `createdAt`
- **WHEN** 预测模块处理已结束的 `time` 类型记录
- **THEN** 发生时刻 MUST 取 `endTime`

#### Scenario: 过滤过短间隔

- **WHEN** 相邻两次发生间隔小于 15 分钟
- **THEN** 该间隔 MUST NOT 参与加权统计

#### Scenario: 加权中位数与样本不足

- **WHEN** 某 `eventId` 在同锚点时段桶（及相邻桶）下有效间隔样本不少于 2
- **THEN** 客户端 MUST 使用加权中位数作为典型间隔并计算 `nextAt = lastAt + interval`
- **WHEN** 样本不足 2
- **THEN** 客户端 MAY 放宽为全时段桶仅 recency 权重后重试
- **WHEN** 仍不足 2
- **THEN** 该事件 MUST 标记为不可预测且 MUST NOT 出现在 predict 行

### Requirement: Recency half-life SHALL adapt to baby age in months

The client SHALL derive `halfLifeDays` from `BabyProfile.birthDate` using fixed month-age bands: 0–2 months → 7 days; 2–4 → 10; 4–6 → 14; 6–12 → 21; 12+ → 30. Recency weight MUST use `exp(-ln(2) * ageDays / halfLifeDays)`. When birth date is missing or placeholder-invalid, half-life MUST default to 14 days.

半衰期 MUST 随宝宝月龄分段调整；无效生日 MUST 回退 14 天半衰期。

#### Scenario: 新生儿较短半衰期

- **WHEN** 宝宝月龄小于 2 个月且 birthDate 有效
- **THEN** 半衰期 MUST 为 7 天

#### Scenario: 无效生日回退

- **WHEN** birthDate 缺失或为 placeholder 无效值
- **THEN** 半衰期 MUST 为 14 天
- **AND** 预测 MUST 仍可运行（若样本足够）

### Requirement: Active timing records SHALL take priority over predictions

Records with `eventNumber == 0` and unset end time per `historyInstantUnset` MUST be treated as active timing sessions. They MUST NOT contribute interval samples. They MUST appear as widget rows before prediction rows and MUST suppress a predict row for the same `eventId`.

进行中计时 MUST 优先占行且 MUST NOT 与同窗 eventId 的 predict 行并存。

#### Scenario: 睡眠进行中占行

- **WHEN** 存在未结束的 `time` 类型睡眠记录
- **THEN** 小组件 MUST 展示 active 行（事件名 + 进行中 elapsed）
- **AND** MUST NOT 为同一 eventId 展示 predict 行

### Requirement: Overdue predictions SHALL sort before upcoming by nextAt

When `nextAt` is before current time, the client MUST mark status `overdue`. All predictable events MUST sort globally by `nextAt` ascending (overdue included). Widget native UI MUST render overdue copy as 「已超时 · 约 X 分钟/小时/天」 computed at render time from `nextAt`.

过期事件 MUST 按 nextAt 参与全局排序；overdue 文案 MUST 在 native 渲染时动态计算。

#### Scenario: 已超时喂奶排前

- **WHEN** 喂奶 `nextAt` 已过去 25 分钟且换尿布 `nextAt` 在未来
- **THEN** predict 排序 MUST 使喂奶排在换尿布之前

#### Scenario: overdue 文案单位

- **WHEN** native 渲染 overdue 且超出 60 分钟未达 24 小时
- **THEN** 文案 MUST 使用「约 N 小时」而非仅分钟
