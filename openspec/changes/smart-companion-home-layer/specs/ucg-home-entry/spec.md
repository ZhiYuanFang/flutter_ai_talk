## MODIFIED Requirements

### Requirement: Home route SHALL use PageView with feeding and UCG pages

App `/home` SHALL render a PageView with exactly three pages: index 0 SHALL be the smart companion page; index 1 SHALL be the existing feeding `HomeScreen` (default landing); index 2 SHALL be the UCG shell widget. The companion page MUST NOT be built or mounted until the user first navigates to index 0. The UCG shell widget MUST NOT be built or mounted until the user first navigates to index 2. Cold start on index 1 MUST NOT instantiate companion UI or `UcgShell`, MUST NOT run square feed initial load, MUST NOT connect Clinic WS solely due to `/home` mount, and MUST NOT trigger UCG location consent. Switching MUST NOT destroy feeding page State (`AutomaticKeepAliveClientMixin` or equivalent). While the home input mode dock is being dragged for reposition, the PageView MUST temporarily disable horizontal page scrolling; after drag ends, horizontal scrolling MUST be re-enabled.

App `/home` SHALL 使用三页 PageView：page 0 智能陪伴，page 1 喂养（默认着陆），page 2 UCG 壳。陪伴与 UCG 均 MUST NOT 在首次进入对应页之前 build/mount；冷启动停留喂养时 MUST NOT 实例化陪伴/`UcgShell`、不得拉广场 Feed、不得仅因进 `/home` 连接 Clinic WS、不得触发 UCG 定位。喂养页 State MUST 保持。dock reposition 期间 MUST 暂停横滑。

#### Scenario: 默认进入喂养页

- **WHEN** 用户导航至 `/home`
- **THEN** PageView SHALL 显示 page 1（喂养 HomeScreen），且 SHALL NOT 默认停留在陪伴页或 UCG 页
- **AND** 陪伴页与 `UcgShell` MUST NOT 被构建

#### Scenario: 从 UCG 返回喂养

- **WHEN** 用户在 UCG 页触发返回喂养（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 1

#### Scenario: 从陪伴返回喂养

- **WHEN** 用户在陪伴页触发返回喂养（系统返回或壳内返回控件）
- **THEN** PageView SHALL animateTo page 1

#### Scenario: dock 拖动期间暂停横滑

- **WHEN** 用户在 page 1 拖动 `HomeInputModeDock` reposition
- **THEN** PageView MUST NOT 响应横滑切页，直至拖动结束

#### Scenario: 首次进入广场才挂载 UCG

- **WHEN** 用户从喂养页横滑或点击「进入广场」首次进入 page 2
- **THEN** App SHALL 挂载 `UcgShell` 并开始广场首屏加载
- **AND** 在此之前 MUST NOT 构建 `UcgShell`

#### Scenario: 首次进入陪伴才挂载陪伴页

- **WHEN** 用户从喂养页横滑或点击「进入陪伴」首次进入 page 0
- **THEN** App SHALL 挂载智能陪伴页
- **AND** 在此之前 MUST NOT 构建陪伴页

### Requirement: 右侧拉条 SHALL 仅在喂养页展示

The app SHALL show a right-edge expandable pull tab on the feeding page (index 1) only, displaying text「进入广场」. The tab SHALL behave like an expandable floating strip (narrow peek + expand on drag/tap). On companion (index 0) and UCG (index 2) pages the tab MUST NOT be visible.

喂养页（index 1）右侧 **必须** 展示「进入广场」拉条；陪伴页与 UCG 页 **不得** 展示该拉条。

#### Scenario: 拉条点击进入广场

- **WHEN** 用户在喂养页点击「进入广场」拉条
- **THEN** PageView SHALL animateTo page 2

#### Scenario: UCG 页隐藏拉条

- **WHEN** PageView 当前页为 page 2
- **THEN** 「进入广场」拉条 SHALL NOT 渲染在界面上

#### Scenario: 陪伴页隐藏广场拉条

- **WHEN** PageView 当前页为 page 0
- **THEN** 「进入广场」拉条 SHALL NOT 渲染在界面上

### Requirement: Enter-square pull tab SHALL show UCG unread indicator on feeding page

While `UcgHomeShell` PageView is on the feeding page (index 1), the right-edge「进入广场」expandable pull tab MUST display an unread highlight (dot or badge) at the top-left of its icon when `ucgUnreadCountProvider` (or equivalent) is greater than zero. Unread count MUST follow the same OR logic as UCG shell message tab: sum of conversation unread plus comment notification unread. When UCG WebSocket delivers an inbound chat message for the recipient (`!isMine`) or `comment_notification` while the user stays on feeding page, the client MUST increment local unread count immediately without requiring a synchronous HTTP fetch before showing the pull-tab indicator. Cold-start historical unread MUST be established via the one-time HTTP baseline after UCG WebSocket first becomes ready in the session.

喂养页「进入广场」拉条须在 `ucgUnreadCountProvider > 0` 时显示未读点。WS 他人私信/互动通知须立即乐观 +1；**历史未读**须在本会话 UCG WS **首次 ready 后** HTTP baseline 一次写入 provider。

#### Scenario: WS 他人私信即时亮红点

- **WHEN** 已登录 wx 已绑定用户停留喂养页且 WS 收到他人 `message_delivered`（`senderWxId` 非当前用户）
- **THEN** 客户端 SHALL 立即将 `ucgUnreadCountProvider` 加 1（或等价递增）
- **AND** 「进入广场」拉条 SHALL 在不发起同步 HTTP 的情况下显示红点

#### Scenario: WS 互动通知即时亮红点

- **WHEN** 用户停留喂养页且 WS 收到 `comment_notification`
- **THEN** 客户端 SHALL 立即递增本地未读计数
- **AND** 拉条 SHALL 显示红点

#### Scenario: 本人消息不亮红点

- **WHEN** WS 收到当前用户自己发送消息的 `message_delivered`（`isMine`）
- **THEN** 客户端 SHALL NOT 递增 `ucgUnreadCountProvider`
- **AND** 拉条 SHALL NOT 因此亮起

#### Scenario: 冷启动历史未读在 WS ready baseline 后亮红点

- **WHEN** 冷启动进入喂养页且服务端存在历史未读（非本次 WS 新消息）
- **AND** UCG WebSocket 本会话首次变为 ready
- **THEN** 客户端 SHALL HTTP baseline 校准并写入 `ucgUnreadCountProvider`
- **AND** 校准完成后拉条 SHALL 显示红点（MAY 相对进 App 延迟数秒）

#### Scenario: 无未读时隐藏红点

- **WHEN** `ucgUnreadCountProvider` 为 0
- **THEN** 拉条 SHALL NOT 显示未读指示点

### Requirement: Feeding page Android back SHALL require double confirmation within 3 seconds to exit

On **Android**, when the user presses the system back button at the feeding module root (PageView feeding index and the root `Navigator` cannot pop), the client MUST NOT exit on the first press within a new confirmation window. The client MUST show a global **AppToast** with message「再试一次退出胖宝」on the first press (or when the previous press was more than 3 seconds ago). The client MUST call `SystemNavigator.pop()` only when a second back press occurs within 3 seconds of the previous back press at the same root context. When the current page is companion or UCG, the first back MUST return to the feeding page instead of exiting.

在 **Android** 上，喂养根层双击退出逻辑作用于**喂养页**；在陪伴页或 UCG 页按返回 **必须** 先回到喂养页，**不得** 直接走退出。

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

#### Scenario: 陪伴页返回喂养

- **WHEN** Android 用户在陪伴页且根 Navigator 不可 pop 时按物理返回
- **THEN** PageView SHALL animateTo 喂养页
- **AND** SHALL NOT 退出应用

#### Scenario: UCG 页返回喂养

- **WHEN** Android 用户在 UCG 页且根 Navigator 不可 pop 时按物理返回
- **THEN** PageView SHALL animateTo 喂养页
- **AND** SHALL NOT 退出应用

### Requirement: UCG square tab re-tap SHALL return to feeding page

When the UCG bottom dock「广场」tab is already selected, a subsequent tap on the same「广场」tab MUST invoke the same navigation as「返回喂养」: PageView SHALL animate to the feeding page (index 1). When another UCG tab is selected, tapping「广场」SHALL only switch to the square tab as today.

当 UCG 底部 Dock「广场」Tab 已选中时，用户再次点击「广场」**必须** 切回喂养页（index 1）。

#### Scenario: 广场 Tab 再点回喂养

- **WHEN** 用户在 PageView UCG 页且 UCG Dock 当前 Tab 为「广场」（index 0）时再次点击「广场」
- **THEN** PageView SHALL animateTo 喂养页（index 1）

#### Scenario: 从其他 Tab 点广场仅切换

- **WHEN** 用户在 UCG 页且 UCG Dock 当前 Tab 为「消息」或「我的」时点击「广场」
- **THEN** UCG Shell SHALL 切换到广场 Tab
- **AND** PageView SHALL 保持在 UCG 页

## ADDED Requirements

### Requirement: Left-edge companion pull tab SHALL show on feeding page

While PageView is on the feeding page (index 1), the app SHALL show a left-edge expandable pull tab displaying text「进入陪伴」(or equivalent). The tab MUST mirror the interaction model of「进入广场」(narrow peek + expand). The tab MUST NOT be visible on companion or UCG pages.

喂养页左侧 **必须** 展示「进入陪伴」拉条，交互对齐右侧广场拉条；非喂养页 **不得** 展示。

#### Scenario: 拉条点击进入陪伴

- **WHEN** 用户在喂养页点击「进入陪伴」拉条
- **THEN** PageView SHALL animateTo page 0

#### Scenario: 非喂养页隐藏陪伴拉条

- **WHEN** PageView 当前页为 page 0 或 page 2
- **THEN** 「进入陪伴」拉条 SHALL NOT 渲染
