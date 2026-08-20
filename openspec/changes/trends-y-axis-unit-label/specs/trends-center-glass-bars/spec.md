## ADDED Requirements

### Requirement: Trends charts with numeric Y show fixed unit label at Y top

Charts that expose a numeric Y axis in the trends center SHALL show a fixed unit label at the top of the Y axis. The label MUST resolve as: `time` → `时长`; `number` → trimmed `EventDefinition.unit` or `量` when empty; `one` → `次`. Count-event day timelines MUST NOT show this numeric Y unit label.

趋势中心凡展示数值 Y 轴的图（近 N 日柱图、计时/计数某日折线图）MUST 在绘图区上方、Y 轴正上方展示固定单位文案：计时为「时长」；计数为 `EventDefinition.unit`（trim 后空则「量」）；计次为「次」。文案 MUST 对齐左侧 Y 刻度列，MUST NOT 与居中图标题或顶档 Y 刻度数字重合。计次某日时间轴 MUST NOT 展示该数值 Y 单位文案。

#### Scenario: 计时柱图与折图

- **WHEN** 选中计时事件且近 N 日柱图或某日折线图可见
- **THEN** 绘图区上方、Y 轴正上方 MUST 显示「时长」，且 MUST NOT 叠在居中标题上

#### Scenario: 计数有自定义单位

- **WHEN** 选中计数事件且 `EventDefinition.unit` trim 后为「ml」
- **THEN** 近 N 日柱图与某日折线图 Y 顶 MUST 显示「ml」

#### Scenario: 计数空单位回退

- **WHEN** 选中计数事件且 `unit` 为空或仅空白
- **THEN** 上述有数值 Y 的图 Y 顶 MUST 显示「量」

#### Scenario: 计次柱图有单位、时间轴无

- **WHEN** 选中计次事件
- **THEN** 近 N 日柱图 Y 顶 MUST 显示「次」，且某日时间轴 MUST NOT 显示数值 Y 单位文案

## MODIFIED Requirements

### Requirement: Bar chart axes and metric semantics unchanged

The system SHALL preserve axis calculation and metric semantics. Trends center charts with a numeric Y axis MUST show the fixed short Y-top unit label defined by「Trends charts with numeric Y show fixed unit label at Y top」, and MUST NOT show longer y-axis meaning helper copy such as「纵轴：小时 (h)」.

量柱/折线 MUST 继续保持既有横轴标签策略与纵轴数值语义（计时为持续小时，否则为数值量）。有数值 Y 的趋势图 MUST 展示固定短单位文案（时长 / unit|量 / 次）；MUST NOT 额外展示「纵轴：…」类长说明。

#### Scenario: Switch time range

- **WHEN** 用户切换日期范围后触发数据刷新
- **THEN** 系统 MUST 重新请求并更新图数据，且 Y 顶单位文案 MUST 仍按当前事件类型与 unit 解析

#### Scenario: Timer event volume

- **WHEN** 选中事件为计时类
- **THEN** 柱图/折图纵轴量值 MUST 仍基于记录时段（小时），且 Y 顶 MUST 为「时长」
