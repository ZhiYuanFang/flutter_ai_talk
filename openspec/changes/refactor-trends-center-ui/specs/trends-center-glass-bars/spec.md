# trends-center-glass-bars 变更规格

## MODIFIED Requirements

### Requirement: Trends center chart area uses glassmorphism

The system SHALL render the trends center chart area as an immersive near-fullscreen glass panel without a page app bar.

趋势中心主图表区 MUST 使用沉浸式近全屏玻璃布局，页面 MUST 移除顶部 AppBar；图表玻璃容器仍须保持磨砂、圆角、事件色渐变、浅色前景字，与 `HistoryEditGlassPanel` 视觉一致。

#### Scenario: View trends with selected event

- **WHEN** 用户已选事件且序列加载完成
- **THEN** 系统 MUST 在沉浸式玻璃主视图中展示柱图，且 MUST NOT 使用独立顶部标题栏分割图表区

#### Scenario: Loading and empty

- **WHEN** 序列加载中或当前范围无数据点
- **THEN** 系统 MUST 在图表占位区显示加载指示或空态文案，且玻璃容器结构仍可见

### Requirement: Bar chart axes and metric semantics unchanged

The system SHALL preserve axis calculation semantics while removing redundant y-axis meaning helper text.

量柱图 MUST 继续保持既有横轴标签策略与纵轴数值语义（`event_number==0` 为时段小时，否则为次数）；界面 MUST NOT 额外展示“纵轴含义说明”文案。

#### Scenario: Switch time range

- **WHEN** 用户切换日期范围后触发数据刷新
- **THEN** 系统 MUST 重新请求并仅更新柱图数据

#### Scenario: Timer event volume

- **WHEN** 选中事件为计时类（`event_number == 0`）
- **THEN** 柱图纵轴量值 MUST 仍基于记录时段（小时），不得回退为次数语义
