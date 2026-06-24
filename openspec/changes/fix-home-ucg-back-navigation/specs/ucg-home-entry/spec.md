## MODIFIED Requirements

### Requirement: Home route SHALL use PageView with feeding and UCG pages

App `/home` SHALL render a PageView with exactly two pages: index 0 SHALL be the existing feeding `HomeScreen`; index 1 SHALL be the UCG shell widget. 切换 MUST NOT 销毁 page 0 的 State（使用 `AutomaticKeepAliveClientMixin` 或等价方案）。While the home input mode dock is being dragged for reposition, the PageView MUST temporarily disable horizontal page scrolling; after drag ends, horizontal scrolling MUST be re-enabled.

On **Android**, when the user presses the system back button at the UCG module root (PageView page 1 and the root `Navigator` cannot pop), the client MUST animate PageView to page 0 and MUST NOT exit the application. When the root `Navigator` can pop (e.g. chat screen, post detail, or a GoRouter child route pushed from feeding), the client MUST pop that route first and MUST NOT switch PageView pages.

在 **Android** 上，当用户位于 UCG 模块根层（PageView page 1 且根 `Navigator` 不可 pop）并按系统返回时，客户端**必须**将 PageView 切回 page 0（喂养），**不得**直接退出 App。当根 `Navigator` 仍可 pop（如聊天页、详情页、或从喂养 push 的 GoRouter 子路由）时，**必须**优先 pop 该路由，**不得**切换 PageView 页。

#### Scenario: 默认进入喂养页

- **WHEN** 用户导航至 `/home`
- **THEN** PageView SHALL 显示 page 0（喂养 HomeScreen），且 SHALL NOT 默认停留在 UCG 页

#### Scenario: 从 UCG 返回喂养

- **WHEN** 用户在 UCG 页触发返回喂养（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 0

#### Scenario: Android 物理返回在 UCG 根层回喂养

- **WHEN** Android 用户在 PageView page 1 且根 `Navigator.canPop` 为 false 时按物理返回键
- **THEN** PageView SHALL animateTo page 0
- **AND** App SHALL NOT 调用 `SystemNavigator.pop()` 退出应用

#### Scenario: UCG 内层路由优先 pop

- **WHEN** Android 用户在 UCG 相关子页（如 `UcgChatScreen`）按物理返回键且 `Navigator.canPop` 为 true
- **THEN** App SHALL pop 该子页
- **AND** PageView SHALL 保持在 page 1

#### Scenario: dock 拖动期间暂停横滑

- **WHEN** 用户在 page 0 拖动 `HomeInputModeDock` reposition
- **THEN** PageView MUST NOT 响应横滑切页，直至拖动结束

## ADDED Requirements

### Requirement: Feeding page Android back SHALL require double confirmation within 3 seconds to exit

On **Android**, when the user presses the system back button at the feeding module root (PageView page 0 and the root `Navigator` cannot pop), the client MUST NOT exit on the first press within a new confirmation window. The client MUST show a global **AppToast** with message「再试一次退出胖宝」on the first press (or when the previous press was more than 3 seconds ago). The client MUST call `SystemNavigator.pop()` only when a second back press occurs within 3 seconds of the previous back press at the same root context.

在 **Android** 上，当用户位于喂养模块根层（PageView page 0 且根 `Navigator` 不可 pop）并按物理返回时，**不得**首次按压即退出 App。首次按压（或距上次按压超过 3 秒）**必须**通过全局 **AppToast** 提示「再试一次退出胖宝」；仅当 3 秒内第二次按压返回时**方可**调用 `SystemNavigator.pop()` 退出应用。

#### Scenario: 首次按返回提示 Toast

- **WHEN** Android 用户在 page 0 根层且 `Navigator.canPop` 为 false 时首次按物理返回键
- **THEN** App SHALL 通过 `apiToastProvider` / AppToast 展示「再试一次退出胖宝」
- **AND** App SHALL NOT 退出应用

#### Scenario: 3 秒内第二次按返回退出

- **WHEN** Android 用户在上述根层于 3 秒内第二次按物理返回键
- **THEN** App SHALL 调用 `SystemNavigator.pop()` 退出应用

#### Scenario: 超过 3 秒重新计时

- **WHEN** Android 用户首次按返回后超过 3 秒再次按返回
- **THEN** App SHALL 再次展示 AppToast「再试一次退出胖宝」
- **AND** SHALL NOT 退出应用

#### Scenario: 子路由仍优先 pop

- **WHEN** Android 用户在 page 0 但从喂养 push 了 GoRouter 子路由（如 `/settings`）且 `Navigator.canPop` 为 true
- **THEN** App SHALL pop 子路由
- **AND** SHALL NOT 触发双击退出或 AppToast

### Requirement: UCG square tab re-tap SHALL return to feeding page

When the UCG bottom dock「广场」tab is already selected, a subsequent tap on the same「广场」tab MUST invoke the same navigation as「返回喂养」: PageView SHALL animate to page 0. When another UCG tab is selected, tapping「广场」SHALL only switch to the square tab as today.

当 UCG 底部 Dock「广场」Tab 已选中时，用户再次点击「广场」**必须**执行与「返回喂养」相同的行为：PageView 切回 page 0。当选中其他 Tab 时点击「广场」，**仅**切换到广场 Tab，行为与现网一致。

#### Scenario: 广场 Tab 再点回喂养

- **WHEN** 用户在 PageView page 1 且 UCG Dock 当前 Tab 为「广场」（index 0）时再次点击「广场」
- **THEN** PageView SHALL animateTo page 0

#### Scenario: 从其他 Tab 点广场仅切换

- **WHEN** 用户在 PageView page 1 且 UCG Dock 当前 Tab 为「消息」或「我的」时点击「广场」
- **THEN** UCG Shell SHALL 切换到广场 Tab
- **AND** PageView SHALL 保持在 page 1
