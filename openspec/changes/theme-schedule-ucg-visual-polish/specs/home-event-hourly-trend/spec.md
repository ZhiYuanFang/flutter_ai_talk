## ADDED Requirements

### Requirement: Today and yesterday hourly series SHALL render as straight line charts

`HomeEventHourlyTrendChart` MUST render both today and yesterday hourly series as polylines with straight segments between hourly buckets. The chart MUST NOT use smooth curved interpolation (`isCurved: true`) for either series.

今/昨 24 整点双序列 MUST 以折线（点间直线段）绘制，不得使用平滑曲线插值。

#### Scenario: 折线而非平滑曲线
- **WHEN** 用户打开今日 chip 触发的今/昨小时趋势 sheet 且存在非零数据
- **THEN** 图表中今日与昨日序列 SHALL 为折线连接各整点桶
- **AND** fl_chart 配置 MUST 设 `isCurved: false`（或等价）于两条序列

#### Scenario: 无数据仍为零线折线
- **WHEN** 今/昨均无符合条件记录
- **THEN** 图表 SHALL 仍绘制 24 个零值点的折线
- **AND** App MUST NOT 因改为折线而隐藏图表区域
