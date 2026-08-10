## REMOVED Requirements

### Requirement: Prediction chart Y-axis SHALL show at most five time labels

**Reason**: 产品改为固定 3 个时刻刻度，替代「≤5」。

**Migration**: 见同 capability 新增 Requirement「固定三个时刻标签」。

## ADDED Requirements

### Requirement: Prediction chart Y-axis SHALL show exactly three time labels

For each forecast-enabled chart on the smart prediction page, the left/time-of-day axis SHALL display **exactly three** time-of-day tick labels under normal ranges (bottom / middle / top of the visible Y scale). The client MUST derive tick spacing as approximately half the visible Y span (then snap to a readable minute step) so three labels are shown. Degenerate ranges（near-zero span）MAY show fewer than three labels solely as a numeric stability fallback.

预测页折线 Y 轴时刻刻度在正常范围内 **必须** 固定为 **3** 个；仅零跨度等退化情形 MAY 更少。

#### Scenario: 正常窗口三档标签

- **WHEN** 折线 Y 轴可见范围大于退化阈值
- **THEN** 左侧时刻刻度标签数量 MUST 为 3

#### Scenario: 零跨度退化

- **WHEN** 可见 Y 跨度接近 0
- **THEN** 客户端 MAY 显示少于 3 个标签以避免除零或重叠
