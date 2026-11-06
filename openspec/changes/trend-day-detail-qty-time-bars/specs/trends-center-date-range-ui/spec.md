## MODIFIED Requirements

### Requirement: Bucket mode follows date span

The system SHALL bucket the N-day overview by local calendar day for all presets. The selected-day detail for `time`/`number` SHALL plot sparse sample bars on that local calendar day without requiring a fixed 24 hourly-bucket axis; `one` events SHALL keep the 0–24 hour occurrence timeline.

近 N 日总量图横轴 MUST 按**自然日**分桶（各预设均为跨多日）。某日详图：计量/计时 MUST 为该自然日上的**稀疏样本柱**（有数据才出柱，柱标到分，X MUST NOT 强制 24 整点桶）；计次 MUST 仍为 **0–24 时**时间轴发生点。近 N 日图与计时/计量某日图的 Y 轴刻度 MUST 固定为 **3**。

#### Scenario: N-day daily buckets

- **WHEN** 用户选择近7日/近15日/近1个月任一预设
- **THEN** 近 N 日图横轴 MUST 为按日分桶

#### Scenario: Selected day detail domain

- **WHEN** 用户选中区间内某一自然日且事件为计量或计时
- **THEN** 某日详图 MUST 按该自然日的有效样本展示稀疏柱图（无数据小时不出柱），MUST NOT 再强制以 24 整点折线/整点桶为主表达

#### Scenario: Selected day count timeline

- **WHEN** 用户选中区间内某一自然日且事件为计次
- **THEN** 某日详图 MUST 仍按该日 0–24 时域时间轴展示
