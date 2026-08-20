## ADDED Requirements

### Requirement: 某日折线以单线连接全部非零点

The day line chart SHALL place all positive hourly samples on a single polyline in time order and MUST NOT split them into one-point segments that leave dots unconnected.

计时/计数某日折线 MUST 将所有量值大于 0 的小时点按时间顺序放入**同一条**折线；MUST NOT 因中间小时为 0 而拆成仅含单点的多段导致无法连线。折线可跨越无样本的时间空隙，且 MUST NOT 经过 y=0 的补零假点。

#### Scenario: 稀疏非零点连通

- **WHEN** 某日仅在 8、10、14 时有非零量
- **THEN** 三个点 MUST 出现在同一折线上并两两相连（允许斜跨中间小时）

### Requirement: 折线选中竖线与具体时间

The day line chart SHALL support selecting a sample, show a vertical guide at the selected x, and display the concrete time for that selection.

某日折线 MUST 支持用户选中某一数据点；选中态 MUST 绘制经过该点 x 的竖线，并 MUST 展示该点对应的具体时间（小时桶可用 `HH:00`）。有数据进入图时 MUST 默认选中最后一个非零点。

#### Scenario: 默认选中末点

- **WHEN** 某日折线存在至少一个非零点且首次展示
- **THEN** 系统 MUST 默认选中时间最晚的非零点并显示其竖线与时间

#### Scenario: 用户改选

- **WHEN** 用户点选另一非零点
- **THEN** 竖线与时间展示 MUST 更新为该点
