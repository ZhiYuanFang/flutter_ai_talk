# event-branded-ui 变更规格

## MODIFIED Requirements

### Requirement: 趋势中心展示

The trends screen MUST use the global event catalog and display selected-event branding in the chart header.

趋势中心 MUST 使用全局事件目录作为选择来源；当前选中事件的 logo 必须展示在趋势图标题上方，图表强调色必须使用该事件品牌色（无色调时用主色）。事件选择入口可由图表标题触发，但目录数据不得脱离全局目录单独维护。

#### Scenario: 选择事件后看图

- **WHEN** 用户在趋势页通过图表标题切换某一事件并加载 `piece` 数据
- **THEN** 图表头部 logo 与图表主色 MUST 与该事件品牌资源一致（或主色缺省）

#### Scenario: 目录为空

- **WHEN** 全局目录为空且接口未返回列表
- **THEN** 必须保留现有空态提示，不得崩溃
