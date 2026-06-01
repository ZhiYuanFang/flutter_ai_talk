# trends-center-chart-header-actions 规格

## ADDED Requirements

### Requirement: 图表头部提供事件切换入口

The trends chart header MUST provide an event selection entry through the chart title row.

趋势中心必须在图表头部标题行提供事件切换入口；标题文案必须可点击并触发事件选择交互，标题右侧必须显示向下箭头以提示“可选择”。

#### Scenario: 点击标题切换事件

- **WHEN** 用户点击趋势图标题行
- **THEN** 系统 MUST 打开事件选择交互并允许切换当前事件

#### Scenario: 可选择状态可见

- **WHEN** 用户进入趋势中心且图表头部可见
- **THEN** 标题右侧 MUST 显示向下箭头图标，表示当前趋势图可选择事件

### Requirement: 图表头部提供日期范围入口

The trends chart header MUST display a clickable date range text under the title.

趋势中心必须在图表标题下方展示日期范围文本；该文本必须可点击并打开日期范围选择 Sheet，且展示格式必须为 `MM-dd — MM-dd`。

#### Scenario: 点击日期范围打开选择

- **WHEN** 用户点击标题下方日期范围文本
- **THEN** 系统 MUST 打开日期范围选择 Sheet

#### Scenario: 日期范围确认后刷新

- **WHEN** 用户在日期范围 Sheet 中确认合法起止日期
- **THEN** 系统 MUST 更新头部日期范围文本并刷新趋势图数据

### Requirement: 图表头部展示当前事件 logo

The trends chart header MUST display the selected event logo above the title.

趋势中心必须在图表标题上方展示当前选中事件的 logo，形成“logo → 标题 → 日期范围”的头部层级。

#### Scenario: 已选事件时展示 logo

- **WHEN** 当前存在有效选中事件
- **THEN** 图表头部 MUST 展示该事件 logo，并与当前图表品牌色保持一致
