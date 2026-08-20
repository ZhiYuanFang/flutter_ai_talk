## ADDED Requirements

### Requirement: Chrome 行返回与选择控件纵向对齐

The trends chrome row SHALL place the back control in the same horizontal row as the event selector and range chip, vertically centered with them.

趋势页返回控件 MUST 与事件选择、日期范围入口处于同一选择行，并 MUST 纵向居中对齐；MUST NOT 仅用与选择行脱节的绝对定位导致视觉错位。

#### Scenario: 纵屏对齐

- **WHEN** 用户打开趋势中心且选择行可见
- **THEN** 返回图标与事件名行、日期 chip MUST 处于同一水平行并纵向居中

### Requirement: 返回图标随壳可读

The back icon color SHALL follow shell semantic text color so it remains visible on light shells.

返回图标颜色 MUST 使用壳层语义主文字色（如 `AppColor.textPrimary`）；浅色壳下 MUST 为深色可读色，MUST NOT 写死为白色以致不可见。

#### Scenario: 浅色壳

- **WHEN** 当前为浅色壳主题
- **THEN** 返回图标 MUST 为深色系且在玻璃背景上可读

### Requirement: 日期范围入口为可点 chip

The range preset entry SHALL render as a rounded chip with a trailing expand_more affordance.

日期范围文案 MUST 置于圆角底布局中，右侧 MUST 显示向下箭头，以表明可点击打开预设 Sheet。

#### Scenario: Chip 可见

- **WHEN** 选择行渲染完成
- **THEN** 右侧范围入口 MUST 呈圆角底并带向下箭头

### Requirement: 点击近 N 日柱更新某日详图

Selecting a bar on the N-day chart SHALL update the selected day and refresh the day-detail chart.

用户点击近 N 日图某一柱后，选中日 MUST 变为该柱对应自然日，且某日详图 MUST 切换为该日数据或骨架。

#### Scenario: 点柱切换日

- **WHEN** 用户点击近 N 日图中日期 D 的柱
- **THEN** 某日详图标题与内容 MUST 对应该日 D
