## MODIFIED Requirements

### Requirement: Home route SHALL use PageView with feeding and UCG pages

App `/home` SHALL render a PageView with exactly two pages: index 0 SHALL be the existing feeding `HomeScreen`; index 1 SHALL be the UCG shell widget. The UCG shell widget MUST NOT be built or mounted until the user first navigates to page 1 (horizontal swipe or「进入广场」). Cold start on page 0 MUST NOT instantiate `UcgShell`, MUST NOT run square feed initial load, and MUST NOT trigger UCG location consent. Switching MUST NOT destroy page 0 State (`AutomaticKeepAliveClientMixin` or equivalent). While the home input mode dock is being dragged for reposition, the PageView MUST temporarily disable horizontal page scrolling; after drag ends, horizontal scrolling MUST be re-enabled.

App `/home` SHALL 使用 PageView：page 0 为喂养 `HomeScreen`，page 1 为 UCG 壳。UCG 壳 MUST NOT 在用户首次进入 page 1 之前 build/mount；冷启动停留在 page 0 时 MUST NOT 实例化 `UcgShell`、不得拉广场 Feed、不得触发 UCG 定位。page 0 State MUST 保持（`AutomaticKeepAliveClientMixin` 或等价）。dock reposition 拖动期间 PageView MUST 暂停横滑，结束后恢复。

#### Scenario: 默认进入喂养页

- **WHEN** 用户导航至 `/home`
- **THEN** PageView SHALL 显示 page 0（喂养 HomeScreen），且 SHALL NOT 默认停留在 UCG 页
- **AND** `UcgShell` MUST NOT 被构建

#### Scenario: 从 UCG 返回喂养

- **WHEN** 用户在 UCG 页触发返回喂养（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 0

#### Scenario: dock 拖动期间暂停横滑

- **WHEN** 用户在 page 0 拖动 `HomeInputModeDock` reposition
- **THEN** PageView MUST NOT 响应横滑切页，直至拖动结束

#### Scenario: 首次进入广场才挂载 UCG

- **WHEN** 用户从 page 0 横滑或点击「进入广场」首次进入 page 1
- **THEN** App SHALL 挂载 `UcgShell` 并开始广场首屏加载
- **AND** 在此之前 MUST NOT 构建 `UcgShell`
