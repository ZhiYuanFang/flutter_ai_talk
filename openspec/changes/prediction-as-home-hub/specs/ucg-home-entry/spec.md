## MODIFIED Requirements

### Requirement: Home route SHALL use PageView with feeding and UCG pages

App `/home` SHALL render a PageView with exactly three pages: index 0 SHALL be the feeding `HomeScreen`; index 1 SHALL be the smart prediction page (default landing / home hub); index 2 SHALL be the UCG shell widget. On cold start at `/home`, the prediction page MUST be mounted (because it is the default landing). The UCG shell widget MUST NOT be built or mounted until the user first navigates to index 2. Cold start on index 1 MUST NOT instantiate `UcgShell`, MUST NOT run square feed initial load, MUST NOT connect Clinic WS solely due to `/home` mount, and MUST NOT trigger UCG location consent. Switching MUST NOT destroy feeding or prediction page State (`AutomaticKeepAliveClientMixin` or equivalent). Feeding-page edge pull tabs MUST NOT be required for navigation. The home input mode dock MUST NOT be shown on the feeding page in this change; therefore dock-drag scroll blocking is not required for navigation correctness.

App `/home` SHALL 使用三页 PageView：page 0 喂养，page 1 智能预测（默认着陆/主页），page 2 UCG 壳。冷启动进入 `/home` 时预测页 MUST 已挂载；UCG MUST NOT 在首次进入 page 2 之前 build/mount；冷启动 MUST NOT 实例化 `UcgShell`，MUST NOT 仅因 `/home` 挂载而连接 Clinic WS。进入侧页 **不得** 依赖喂养页贴边拉条。本变更喂养页不再展示输入模式 dock。

#### Scenario: 默认进入预测页

- **WHEN** 用户导航至 `/home`
- **THEN** PageView SHALL 显示 page 1（智能预测），且 SHALL NOT 默认停留在喂养页或 UCG 页
- **AND** 智能预测页 MUST 已被构建/挂载
- **AND** `UcgShell` MUST NOT 被构建

#### Scenario: 从 UCG 返回预测主页

- **WHEN** 用户在 UCG 页触发返回主页（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 1（智能预测）

#### Scenario: 从喂养页返回预测主页

- **WHEN** 用户在喂养页触发返回主页（系统返回）
- **THEN** PageView SHALL animateTo page 1（智能预测）

#### Scenario: 首次横滑进入广场才挂载 UCG

- **WHEN** 用户从预测页横滑首次进入 page 2
- **THEN** App SHALL 挂载 `UcgShell` 并开始广场首屏加载
- **AND** 在此之前 MUST NOT 构建 `UcgShell`

#### Scenario: 横滑进入喂养页

- **WHEN** 用户从预测页横滑进入 page 0
- **THEN** App SHALL 展示喂养 `HomeScreen`（KeepAlive 可保留 State）

### Requirement: Feeding page Android back SHALL require double confirmation within 3 seconds to exit

On **Android**, when the user presses the system back button at the **prediction** module root (PageView prediction index and the root `Navigator` cannot pop), the client MUST NOT exit on the first press within a new confirmation window. The client MUST show a global **AppToast** with message「再试一次退出胖宝」on the first press (or when the previous press was more than 3 seconds ago). The client MUST call `SystemNavigator.pop()` only when a second back press occurs within 3 seconds of the previous back press at the same root context. When the current page is the feeding page or UCG, the first back MUST return to the prediction page instead of exiting.

在 **Android** 上，双击退出逻辑作用于**预测主页**；在喂养页或 UCG 页按返回 **必须** 先回到预测页，**不得** 直接走退出。

#### Scenario: 预测页首次按返回提示 Toast

- **WHEN** Android 用户在预测页根层且 `Navigator.canPop` 为 false 时首次按物理返回键
- **THEN** App SHALL 通过 `apiToastProvider` / AppToast 展示「再试一次退出胖宝」
- **AND** App SHALL NOT 退出应用

#### Scenario: 3 秒内第二次按返回退出

- **WHEN** Android 用户在预测根层于 3 秒内第二次按物理返回键
- **THEN** App SHALL 调用 `SystemNavigator.pop()` 退出应用

#### Scenario: 超过 3 秒重新计时

- **WHEN** Android 用户首次按返回后超过 3 秒再次按返回
- **THEN** App SHALL 再次展示 AppToast「再试一次退出胖宝」
- **AND** SHALL NOT 退出应用

#### Scenario: 子路由仍优先 pop

- **WHEN** Android 用户在预测页但从该壳 push 了 GoRouter 子路由（如 `/settings`）且 `Navigator.canPop` 为 true
- **THEN** App SHALL pop 子路由
- **AND** SHALL NOT 触发双击退出或 AppToast

#### Scenario: 喂养页返回预测

- **WHEN** Android 用户在喂养页且根 Navigator 不可 pop 时按物理返回
- **THEN** PageView SHALL animateTo 预测页
- **AND** SHALL NOT 退出应用

#### Scenario: UCG 页返回预测

- **WHEN** Android 用户在 UCG 页且根 Navigator 不可 pop 时按物理返回
- **THEN** PageView SHALL animateTo 预测页
- **AND** SHALL NOT 退出应用

### Requirement: Feeding page MUST NOT show companion or square edge pull tabs

While PageView is on the feeding page, the client MUST NOT render left-edge「进入陪伴」/「进入预测」or right-edge「进入广场」expandable pull tabs (or equivalent edge strips). Navigation MUST rely on PageView horizontal swipe (and other non-tab entry points).

喂养页 **不得** 渲染左缘进入预测/陪伴或右缘进入广场的可展开拉条；导航依赖横滑与其它非拉条入口。

#### Scenario: 喂养页无拉条

- **WHEN** PageView 位于喂养页（index 0）
- **THEN** UI MUST NOT 展示进入预测或陪伴的拉条
- **AND** MUST NOT 展示「进入广场」拉条

### Requirement: Feeding page MUST allow horizontal swipe into companion and UCG

While on the feeding page and PageView scrolling is not blocked by an existing guard, the user MUST be able to horizontally swipe to the smart prediction page (index 1). While on the prediction page, the user MUST be able to swipe to feeding (index 0) and UCG (index 2).

喂养页在未被既有禁滑守卫挡住时，用户 **必须** 能横滑进入智能预测页；预测页 **必须** 能横滑进入喂养与 UCG。

#### Scenario: 从喂养右滑回预测

- **WHEN** PageView 位于喂养页（index 0）且横滑未禁用
- **THEN** 用户 MUST 能横滑进入预测页（index 1）

#### Scenario: 从预测左滑进喂养、右滑进 UCG

- **WHEN** PageView 位于预测页（index 1）且横滑未禁用
- **THEN** 用户 MUST 能横滑进入喂养页（index 0）与 UCG 页（index 2）
