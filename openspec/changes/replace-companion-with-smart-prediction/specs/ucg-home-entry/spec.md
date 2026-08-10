## MODIFIED Requirements

### Requirement: Home route SHALL use PageView with feeding and UCG pages

App `/home` SHALL render a PageView with exactly three pages: index 0 SHALL be the smart prediction page; index 1 SHALL be the existing feeding `HomeScreen` (default landing); index 2 SHALL be the UCG shell widget. The prediction page MUST NOT be built or mounted until the user first navigates to index 0. The UCG shell widget MUST NOT be built or mounted until the user first navigates to index 2. Cold start on index 1 MUST NOT instantiate prediction UI or `UcgShell`, MUST NOT run square feed initial load, MUST NOT connect Clinic WS solely due to `/home` mount, and MUST NOT trigger UCG location consent. Switching MUST NOT destroy feeding page State (`AutomaticKeepAliveClientMixin` or equivalent). While the home input mode dock is being dragged for reposition, the PageView MUST temporarily disable horizontal page scrolling; after drag ends, horizontal scrolling MUST be re-enabled. Feeding-page edge pull tabs MUST NOT be required for navigation.

App `/home` SHALL 使用三页 PageView：page 0 智能预测，page 1 喂养（默认着陆），page 2 UCG 壳。预测页与 UCG 均 MUST NOT 在首次进入对应页之前 build/mount；冷启动停留喂养时 MUST NOT 实例化预测页/`UcgShell`，MUST NOT 仅因 `/home` 挂载而连接 Clinic WS。dock 拖动期间 MUST 暂停横滑。进入侧页 **不得** 依赖喂养页贴边拉条。

#### Scenario: 默认进入喂养页

- **WHEN** 用户导航至 `/home`
- **THEN** PageView SHALL 显示 page 1（喂养 HomeScreen），且 SHALL NOT 默认停留在预测页或 UCG 页
- **AND** 预测页与 `UcgShell` MUST NOT 被构建

#### Scenario: 从 UCG 返回喂养

- **WHEN** 用户在 UCG 页触发返回喂养（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 1

#### Scenario: 从预测页返回喂养

- **WHEN** 用户在预测页触发返回喂养（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 1

#### Scenario: dock 拖动期间暂停横滑

- **WHEN** 用户在 page 1 拖动 `HomeInputModeDock` reposition
- **THEN** PageView MUST NOT 响应横滑切页，直至拖动结束

#### Scenario: 首次横滑进入广场才挂载 UCG

- **WHEN** 用户从喂养页横滑首次进入 page 2
- **THEN** App SHALL 挂载 `UcgShell` 并开始广场首屏加载
- **AND** 在此之前 MUST NOT 构建 `UcgShell`

#### Scenario: 首次横滑进入预测页才挂载

- **WHEN** 用户从喂养页横滑首次进入 page 0
- **THEN** App SHALL 挂载智能预测页
- **AND** 在此之前 MUST NOT 构建预测页
- **AND** MUST NOT 挂载陪伴聊天 UI

### Requirement: Feeding page Android back SHALL require double confirmation within 3 seconds to exit

On **Android**, when the user presses the system back button at the feeding module root (PageView feeding index and the root `Navigator` cannot pop), the client MUST NOT exit on the first press within a new confirmation window. The client MUST show a global **AppToast** with message「再试一次退出胖宝」on the first press (or when the previous press was more than 3 seconds ago). The client MUST call `SystemNavigator.pop()` only when a second back press occurs within 3 seconds of the previous back press at the same root context. When the current page is the smart prediction page or UCG, the first back MUST return to the feeding page instead of exiting.

在 **Android** 上，喂养根层双击退出逻辑作用于**喂养页**；在预测页或 UCG 页按返回 **必须** 先回到喂养页，**不得** 直接走退出。

#### Scenario: 喂养页首次按返回提示 Toast

- **WHEN** Android 用户在喂养页根层且 `Navigator.canPop` 为 false 时首次按物理返回键
- **THEN** App SHALL 通过 `apiToastProvider` / AppToast 展示「再试一次退出胖宝」
- **AND** App SHALL NOT 退出应用

#### Scenario: 3 秒内第二次按返回退出

- **WHEN** Android 用户在喂养根层于 3 秒内第二次按物理返回键
- **THEN** App SHALL 调用 `SystemNavigator.pop()` 退出应用

#### Scenario: 超过 3 秒重新计时

- **WHEN** Android 用户首次按返回后超过 3 秒再次按返回
- **THEN** App SHALL 再次展示 AppToast「再试一次退出胖宝」
- **AND** SHALL NOT 退出应用

#### Scenario: 子路由仍优先 pop

- **WHEN** Android 用户在喂养页但从喂养 push 了 GoRouter 子路由（如 `/settings`）且 `Navigator.canPop` 为 true
- **THEN** App SHALL pop 子路由
- **AND** SHALL NOT 触发双击退出或 AppToast

#### Scenario: 预测页返回喂养

- **WHEN** Android 用户在智能预测页且根 Navigator 不可 pop 时按物理返回
- **THEN** PageView SHALL animateTo 喂养页
- **AND** SHALL NOT 退出应用

#### Scenario: UCG 页返回喂养

- **WHEN** Android 用户在 UCG 页且根 Navigator 不可 pop 时按物理返回
- **THEN** PageView SHALL animateTo 喂养页
- **AND** SHALL NOT 退出应用

### Requirement: Feeding page MUST NOT show companion or square edge pull tabs

While PageView is on the feeding page, the client MUST NOT render left-edge「进入陪伴」/「进入预测」or right-edge「进入广场」expandable pull tabs (or equivalent edge strips). Navigation MUST rely on PageView horizontal swipe (and other non-tab entry points such as the prediction tip bar).

喂养页 **不得** 渲染左缘进入预测/陪伴或右缘进入广场的可展开拉条；导航依赖横滑与其它非拉条入口。

#### Scenario: 喂养页无拉条

- **WHEN** PageView 位于喂养页（index 1）
- **THEN** UI MUST NOT 展示进入预测或陪伴的拉条
- **AND** MUST NOT 展示「进入广场」拉条

### Requirement: Feeding page MUST allow horizontal swipe into companion and UCG

While on the feeding page and PageView scrolling is not blocked by an in-progress dock drag (or equivalent existing guard), the user MUST be able to horizontally swipe to the smart prediction page (index 0) and to the UCG page (index 2).

喂养页在未被 dock 拖动等既有禁滑守卫挡住时，用户 **必须** 能横滑进入智能预测页与 UCG 页。

#### Scenario: 横滑进入预测页

- **WHEN** 用户在喂养页且 PageView 可滑
- **AND** 用户向 page 0 方向横滑完成一页
- **THEN** PageView MUST 到达智能预测页（index 0）

#### Scenario: 横滑进入 UCG

- **WHEN** 用户在喂养页且 PageView 可滑
- **AND** 用户向 UCG 方向横滑完成一页
- **THEN** PageView MUST 到达 UCG 页（index 2）
