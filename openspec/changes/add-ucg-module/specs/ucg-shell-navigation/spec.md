## ADDED Requirements

### Requirement: UCG shell SHALL provide five-item bottom navigation

UCG page（PageView index 1）SHALL provide bottom navigation with items: 广场、宝藏、+（发布）、消息、我的。中间「+」SHALL open compose flow without switching to a permanent fifth tab index. Bottom navigation MUST follow `ucg-visual-system` glass dock styling (floating pill, theme primary for selection), not default Material `BottomNavigationBar`.

#### Scenario: 切换广场与我的
- **WHEN** 用户点击底部「我的」
- **THEN** 壳 SHALL 显示个人页内容，且底部「我的」为选中态

#### Scenario: 点击加号打开发布
- **WHEN** 用户点击底部「+」
- **THEN** App SHALL 打开发布页（全屏 route 或 modal），且返回后 SHALL 恢复先前 Tab 选中态

### Requirement: 宝藏 Tab SHALL show placeholder

The 宝藏 tab SHALL display static placeholder copy「尚未开通」and MUST NOT call unfinished treasure APIs in MVP.

#### Scenario: 进入宝藏
- **WHEN** 用户选中「宝藏」
- **THEN** UI SHALL 展示「尚未开通」文案
