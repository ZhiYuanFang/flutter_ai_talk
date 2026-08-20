## MODIFIED Requirements

### Requirement: 图表头部提供事件切换入口

The trends chart header MUST provide an event selection entry through the chart title row with the event logo to the left of the event name.

趋势中心必须在图表头部选择行提供事件切换入口；选择行 MUST 展示「事件 logo + 事件名」，名称右侧必须显示向下箭头；整行（或名称区域）可点击并触发事件选择。向下箭头颜色 MUST 跟随当前事件 accent。

#### Scenario: 点击标题切换事件

- **WHEN** 用户点击趋势图选择行中的事件名区域
- **THEN** 系统 MUST 打开事件选择交互并允许切换当前事件

#### Scenario: 可选择状态可见

- **WHEN** 用户进入趋势中心且图表头部可见
- **THEN** 事件名右侧 MUST 显示向下箭头，且箭头颜色 MUST 为当前事件 accent

#### Scenario: 选择行含 logo

- **WHEN** 当前存在有效选中事件
- **THEN** 事件名左侧 MUST 展示该事件 logo

### Requirement: 图表头部提供日期范围入口

The trends chart header MUST display a clickable preset range label on the title row (same position as today’s range control) that opens a bottom sheet of range presets.

趋势中心必须在选择行**右侧**（位置与现网日期入口一致）展示可点击的时间范围文案；文案 MUST 为「近7日」「近15日」「近1个月」之一；点击后 MUST 打开底部预设选择 Sheet。MUST NOT 再以 `MM-dd — MM-dd` 作为该入口主文案。

#### Scenario: 点击日期范围打开选择

- **WHEN** 用户点击选择行右侧时间范围文案
- **THEN** 系统 MUST 打开底部范围预设 Sheet

#### Scenario: 日期范围确认后刷新

- **WHEN** 用户在范围 Sheet 中选择某一预设并确认
- **THEN** 系统 MUST 更新右侧文案并刷新近 N 日与某日详图数据

## REMOVED Requirements

### Requirement: 图表头部展示当前事件 logo

**Reason**: 上方独立大 logo 已取消；logo 改在选择行事件名左侧，并在双图标题内再次展示。

**Migration**: 删除 `TrendGlassBarChart.headerLogo` 上方居中展示；飞入落点改为选择行左侧 logo。
