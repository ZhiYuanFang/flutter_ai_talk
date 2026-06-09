## MODIFIED Requirements

### Requirement: Home route SHALL use PageView with feeding and UCG pages

App `/home` SHALL render a PageView with exactly two pages: index 0 SHALL be the existing feeding `HomeScreen`; index 1 SHALL be the UCG shell widget. 切换 MUST NOT 销毁 page 0 的 State（使用 `AutomaticKeepAliveClientMixin` 或等价方案）。While the home input mode dock is being dragged for reposition, the PageView MUST temporarily disable horizontal page scrolling; after drag ends, horizontal scrolling MUST be re-enabled.

#### Scenario: 默认进入喂养页

- **WHEN** 用户导航至 `/home`
- **THEN** PageView SHALL 显示 page 0（喂养 HomeScreen），且 SHALL NOT 默认停留在 UCG 页

#### Scenario: 从 UCG 返回喂养

- **WHEN** 用户在 UCG 页触发返回喂养（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 0

#### Scenario: dock 拖动期间暂停横滑

- **WHEN** 用户在 page 0 拖动 `HomeInputModeDock` reposition
- **THEN** PageView MUST NOT 响应横滑切页，直至拖动结束
