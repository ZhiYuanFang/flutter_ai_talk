## ADDED Requirements

### Requirement: Home route SHALL use PageView with feeding and UCG pages

App `/home` SHALL render a PageView with exactly two pages: index 0 SHALL be the existing feeding `HomeScreen`; index 1 SHALL be the UCG shell widget. 切换 MUST NOT 销毁 page 0 的 State（使用 `AutomaticKeepAliveClientMixin` 或等价方案）。

#### Scenario: 默认进入喂养页
- **WHEN** 用户导航至 `/home`
- **THEN** PageView SHALL 显示 page 0（喂养 HomeScreen），且 SHALL NOT 默认停留在 UCG 页

#### Scenario: 从 UCG 返回喂养
- **WHEN** 用户在 UCG 页触发返回喂养（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 0

### Requirement: 右侧拉条 SHALL 仅在喂养页展示

The app SHALL show a right-edge expandable pull tab on page 0 only, displaying text「进入广场」. The tab SHALL behave like an expandable floating strip (narrow peek + expand on drag/tap). On page 1 the tab MUST NOT be visible.

#### Scenario: 拉条点击进入广场
- **WHEN** 用户在 page 0 点击「进入广场」拉条
- **THEN** PageView SHALL animateTo page 1

#### Scenario: UCG 页隐藏拉条
- **WHEN** PageView 当前页为 page 1
- **THEN** 「进入广场」拉条 SHALL NOT 渲染在界面上
