## ADDED Requirements

### Requirement: 趋势事件目录由服务端驱动

The system SHALL fetch the trend-capable event catalog from the server (mock in M1) before rendering charts and SHALL NOT hardcode a canonical feeding-event taxonomy for production. 系统在绘制图表前必须从服务端（M1 可为 Mock）获取可趋势化的事件列表（含标识符与展示用标签）。生产行为中客户端不得内置固定喂养事件类型全表；M1 的 Mock JSON 可模拟任意服务端返回的 key。

#### Scenario: 动态列表渲染

- **WHEN** 趋势中心页面加载
- **THEN** 系统必须从仓库请求事件目录，并为每个返回的事件渲染一块图表区域

### Requirement: 按时间范围的趋势可视化

The system SHALL render a time-ranged trend visualization per catalog event using server-provided series (mock acceptable in M1). 对目录中每个事件，系统必须展示趋势图，其序列与坐标轴数据由服务端在给定或默认时间范围内提供的历史点驱动（M1 允许 Mock 数据）。

#### Scenario: 查看某一事件的曲线

- **WHEN** 目录中某事件在当前所选时间范围内有关联序列数据
- **THEN** 系统必须在趋势中心为该事件绘制对应数据

#### Scenario: 当前范围无数据

- **WHEN** 某事件在所选时间范围内无数据点
- **THEN** 系统必须展示明确的空状态且不得崩溃
