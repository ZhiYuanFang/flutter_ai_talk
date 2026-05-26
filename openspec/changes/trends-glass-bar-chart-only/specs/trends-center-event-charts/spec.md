## REMOVED Requirements

### Requirement: Selected event shows trend line and bar volume

**Reason**: 趋势中心统一为玻璃态单柱图；折线不再属于本能力范围。

**Migration**: 由变更 `trends-glass-bar-chart-only` 下 `trends-center-glass-bars` 规格替代；实现删除趋势页 `LineChart`。

## ADDED Requirements

### Requirement: Trends center defers line charts to other surfaces

The system MUST NOT provide a line trend chart on the trends center route.

趋势中心路由 MUST NOT 提供折线趋势图；对照分析如需折线，须使用主页今日事件小时趋势 Sheet 等其他入口。

#### Scenario: Open trends from home app bar

- **WHEN** 用户从主页进入 `/trends`
- **THEN** 页面 MUST 仅含量柱玻璃图表，不得出现折线图区域
