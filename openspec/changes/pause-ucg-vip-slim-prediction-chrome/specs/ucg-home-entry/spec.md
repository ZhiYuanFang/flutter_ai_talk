## MODIFIED Requirements

### Requirement: Home route SHALL use PageView with feeding and UCG pages

App `/home` SHALL render a PageView with **exactly two** pages while the temporary UCG home pause gate is active: index 0 SHALL be the feeding `HomeScreen`; index 1 SHALL be the smart prediction page (default landing / home hub). The client MUST NOT expose a UCG page index, MUST NOT allow horizontal navigation into UCG, and MUST NOT mount `UcgShell` due to home pager navigation. On cold start at `/home`, the prediction page MUST be mounted. `requestPage` targeting the former UCG index MUST NOT leave the user on a blank third page (MUST no-op or navigate to prediction). Switching between feeding and prediction MUST NOT destroy page State (`AutomaticKeepAliveClientMixin` or equivalent).

当 UCG 主壳暂停闸门开启时，App `/home` SHALL 使用**两页** PageView：page 0 喂养，page 1 智能预测（默认着陆）；**不得**再提供 UCG 页索引，**不得**横滑进入广场，**不得**因主壳导航挂载 `UcgShell`；指向旧 UCG 索引的 `requestPage` **不得**落到空白第三页。

#### Scenario: 默认进入预测页且无 UCG 页

- **WHEN** 用户导航至 `/home` 且暂停闸门开启
- **THEN** PageView SHALL 显示 page 1（智能预测）
- **AND** PageView itemCount MUST 为 2
- **AND** `UcgShell` MUST NOT 被构建

#### Scenario: 无法横滑进入广场

- **WHEN** 用户在预测页尝试继续向广场方向横滑
- **THEN** App MUST NOT 展示 UCG 壳或广场 Feed

#### Scenario: 从喂养页返回预测主页

- **WHEN** 用户在喂养页触发返回主页（系统返回）
- **THEN** PageView SHALL animateTo page 1（智能预测）

#### Scenario: 横滑进入喂养页

- **WHEN** 用户从预测页横滑进入 page 0
- **THEN** App SHALL 展示喂养 `HomeScreen`（KeepAlive 可保留 State）

### Requirement: Feeding page Android back SHALL require double confirmation within 3 seconds to exit

On **Android**, when the user presses the system back button at the **prediction** module root (PageView prediction index and the root `Navigator` cannot pop), the client MUST NOT exit on the first press within a new confirmation window. The client MUST show a global **AppToast** with message「再试一次退出胖宝」on the first press (or when the previous press was more than 3 seconds ago). The client MUST call `SystemNavigator.pop()` only when a second back press occurs within 3 seconds of the previous back press at the same root context. When the current page is the feeding page, the first back MUST return to the prediction page instead of exiting. While the UCG home pause gate is active, there is no UCG pager page; back handling MUST NOT depend on navigating from UCG.

在 **Android** 上，双击退出逻辑作用于**预测主页**；在喂养页按返回 **必须** 先回到预测页。UCG 暂停期间 **不得** 依赖从 UCG 页返回的分支。

#### Scenario: 预测页首次按返回提示 Toast

- **WHEN** Android 用户在预测页根层且 `Navigator.canPop` 为 false 时首次按物理返回键
- **THEN** App SHALL 通过 `apiToastProvider` / AppToast 展示「再试一次退出胖宝」
- **AND** App SHALL NOT 退出应用

#### Scenario: 喂养页返回预测

- **WHEN** Android 用户在喂养页按返回
- **THEN** PageView MUST 回到预测页
- **AND** MUST NOT 直接退出应用
