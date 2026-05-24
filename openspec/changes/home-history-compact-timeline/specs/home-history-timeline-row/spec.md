## ADDED Requirements

### Requirement: 主页历史时间轴行

The system SHALL render each home history list item as a compact timeline row with a left time column, a center event title, and a right trailing metric or status. 系统必须把主页每条历史记录展示为**紧凑时间轴行**：**左侧**为时间、**中间**为事件名称（备注可截断）、**右侧**为数量、计时状态或用时等尾注。

#### Scenario: 计数类事件

- **WHEN** 记录的 `eventNumber` 大于 1
- **THEN** 右侧尾注必须显示指向该数量的文案（如 `→3`），且不得在单行内重复堆叠完整旧版 `时间:事件->n` 长串

#### Scenario: 计时类事件

- **WHEN** 记录的 `eventNumber` 为 0 且尚未结束
- **THEN** 右侧尾注必须显示「开始计时」或等价短文案；已结束时必须显示用时短文案

### Requirement: 紧凑行高

The system MUST keep each home history row visually compact (approximately 32–36 logical pixels tall) with at most one line for the combined center and trailing text. 系统必须将主页历史单行高度控制在约 **32–36** 逻辑像素量级；中间与右侧主文案不得超过 **1 行**，溢出必须以省略号截断。

#### Scenario: 长备注

- **WHEN** 事件备注文本超过单行宽度
- **THEN** 必须在行内截断显示，且行高不得撑开列表

### Requirement: 列表顶部渐变弱化

The system SHALL apply a top-edge visual fade on the history list so older items appear weaker while the list still uses Expanded layout. 系统必须在历史列表**顶部**施加渐变弱化效果，使较旧记录视觉上变淡；历史区仍使用 `Expanded` 占据主输入区上方剩余空间。

#### Scenario: 向上滚动查看旧记录

- **WHEN** 用户向上滚动历史列表
- **THEN** 顶部渐变必须使最上方可见项相对底部最新项更弱，且不得依赖对每条记录设置极低透明度导致全文难以辨认
