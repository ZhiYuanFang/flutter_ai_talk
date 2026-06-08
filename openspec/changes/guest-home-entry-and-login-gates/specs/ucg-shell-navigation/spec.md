## MODIFIED Requirements

### Requirement: UCG shell SHALL provide five-item bottom navigation

UCG page（PageView index 1）SHALL provide bottom navigation with items: 广场、宝藏、+（发布）、消息、我的。中间「+」SHALL open compose flow without switching to a permanent fifth tab index. Bottom navigation MUST follow `ucg-visual-system` glass dock styling (floating pill, theme primary for selection), not default Material `BottomNavigationBar`. 未登录用户点击「消息」「我的」或「+（发布）」时，App MUST 弹出确认对话框引导登录，且 MUST NOT 切换底部 Tab 选中态至对应项；用户确认后 SHALL `push('/login')`。

#### Scenario: 切换广场与我的

- **WHEN** 已登录用户点击底部「我的」
- **THEN** 壳 SHALL 显示个人页内容，且底部「我的」为选中态

#### Scenario: 点击加号打开发布

- **WHEN** 已登录且已绑定微信账号的用户点击底部「+」
- **THEN** App SHALL 打开发布页（全屏 route 或 modal），且返回后 SHALL 恢复先前 Tab 选中态

#### Scenario: 未登录点击消息 Tab

- **WHEN** 未登录用户点击底部「消息」
- **THEN** App SHALL 展示「需要登录」确认对话框，且 MUST NOT 将 Tab 切换至消息页；用户确认后 SHALL 导航至 `/login`

#### Scenario: 未登录点击我的 Tab

- **WHEN** 未登录用户点击底部「我的」
- **THEN** App SHALL 展示「需要登录」确认对话框，且 MUST NOT 将 Tab 切换至我的页；用户确认后 SHALL 导航至 `/login`

#### Scenario: 未登录点击发布

- **WHEN** 未登录用户点击底部「+」或发布入口
- **THEN** App SHALL 展示「需要登录」确认对话框，且 MUST NOT 打开发布流程；用户确认后 SHALL 导航至 `/login`

### Requirement: 宝藏 Tab SHALL show placeholder

The 宝藏 tab SHALL display static placeholder copy「尚未开通」and MUST NOT call unfinished treasure APIs in MVP.

#### Scenario: 进入宝藏

- **WHEN** 用户选中「宝藏」
- **THEN** UI SHALL 展示「尚未开通」文案
