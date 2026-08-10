## ADDED Requirements

### Requirement: Unauthenticated prediction page SHALL show a login gate Dialog

When the user is not logged in and opens the smart prediction page, the client SHALL present a login gate Dialog over the demo skeleton. The Dialog MUST expose a primary action that navigates to `/login` (or the same login entry used elsewhere). The client MUST NOT provide a permanent dismiss that suppresses this Dialog while the user remains unauthenticated.

未登录打开智能预测页时，客户端 **必须** 在骨架之上展示登录引导 Dialog；主操作 **必须** 进入 `/login`（或等价登录入口）；在仍未登录期间 **不得** 提供永久不再弹。

#### Scenario: 未登录自动展示登录 Dialog

- **WHEN** 用户未登录并进入智能预测页
- **THEN** UI MUST 展示登录引导 Dialog
- **AND** 底层 MUST 仍为冷态骨架

#### Scenario: CTA 去登录

- **WHEN** 用户点击登录引导 Dialog 的主按钮
- **THEN** 客户端 MUST 导航至 `/login`（或等价）

### Requirement: Bound-missing prediction page SHALL show a bind-baby gate Dialog

When the user is logged in but has no usable deviceNo (unbound baby) and opens the smart prediction page, the client SHALL present a bind-baby gate Dialog over the demo skeleton. The primary action MUST navigate to `/settings/bind-baby` (same destination as the feeding-home bind CTA). The client MUST NOT provide a permanent dismiss that suppresses this Dialog while the user remains unbound. This Dialog MUST NOT be shown when the user is not logged in (login gate takes priority).

已登录但无可用 deviceNo 时，客户端 **必须** 展示绑定宝宝引导 Dialog；主操作 **必须** 进入 `/settings/bind-baby`；未绑定期间 **不得** 永久不再弹；未登录时 **必须** 优先登录引导而非本 Dialog。

#### Scenario: 已登录未绑定展示绑定 Dialog

- **WHEN** 用户已登录、无可用 deviceNo，进入智能预测页
- **THEN** UI MUST 展示绑定宝宝引导 Dialog
- **AND** MUST NOT 同时展示登录引导 Dialog

#### Scenario: CTA 去绑定

- **WHEN** 用户点击绑定引导 Dialog 的主按钮
- **THEN** 客户端 MUST 导航至 `/settings/bind-baby`

### Requirement: Login and bind gate Dialogs SHALL soft-dismiss and reopen like recall

The login and bind gate Dialogs MUST be dismissible by tapping the scrim/barrier (soft dismiss). Soft dismiss MUST NOT permanently suppress the gate. After a soft dismiss, a **tap/click** on any interactive region of the smart prediction page **except** the header baby avatar MUST reopen the currently applicable gate Dialog for as long as the gate condition still holds. Reopen MUST NOT be triggered solely by pointer-down / touch-down without a completed tap (so scrolling or brushing MUST NOT reopen). Tapping the avatar MUST navigate to settings (with the existing unauthenticated login gate) and MUST NOT reopen the gate Dialog as that tap’s primary action.

登录/绑定引导 Dialog **必须** 可点遮罩软关；软关 **不得** 永久抑制；条件仍满足时，软关后除顶栏头像外对预测页的**点击** **必须** 再弹；**不得**仅因按下触点（未完成点击）或滑动浏览再弹；点击头像 **必须** 走设置/登录门且 **不得** 以再弹为该次主行为。

#### Scenario: 点遮罩软关登录 Dialog

- **WHEN** 登录引导 Dialog 打开且用户点击外部遮罩
- **THEN** Dialog MUST 关闭
- **AND** 客户端 MUST NOT 永久禁止再次展示

#### Scenario: 软关后再弹

- **WHEN** 登录或绑定引导已软关且条件仍满足，用户点击预测页非头像区域
- **THEN** 客户端 MUST 再次展示对应引导 Dialog

#### Scenario: 滑动触碰不误弹

- **WHEN** 引导已软关且条件仍满足，用户在预测页主体上按下并滑动浏览（未完成点击）
- **THEN** 客户端 MUST NOT 仅因此重新打开引导 Dialog

#### Scenario: 软关后点头像不抢弹

- **WHEN** 引导已软关且条件仍满足，用户点击预测顶栏头像
- **THEN** 客户端 MUST 按既有规则进入设置或登录
- **AND** MUST NOT 仅因该点击重新打开引导 Dialog

### Requirement: Gate Dialogs SHALL stop only when their condition clears

The login gate MUST stop showing and stop reopening once the user is logged in. The bind gate MUST stop showing and stop reopening once a usable deviceNo exists. After login while still unbound, the client SHALL switch to the bind gate (MUST NOT leave the user with no gate while unbound).

登录引导 **必须** 在已登录后停止；绑定引导 **必须** 在出现可用 deviceNo 后停止；登录后仍未绑定 **必须** 切换为绑定引导。

#### Scenario: 登录成功停登录引导

- **WHEN** 用户完成登录且会话变为已登录
- **THEN** 登录引导 Dialog MUST 不再展示
- **AND** 若仍无 deviceNo，绑定引导 MUST 可展示

#### Scenario: 绑定成功停绑定引导

- **WHEN** 用户完成绑定且出现可用 deviceNo
- **THEN** 绑定引导 Dialog MUST 不再展示与再弹

### Requirement: At most one prediction gate Dialog SHALL be active

The client MUST show at most one of: login gate, bind gate, or recall onboarding Dialog at a time, using priority unauthenticated > unbound > recall(empty history).

同一时刻 **最多** 展示登录、绑定、量身定做 Dialog 之一；优先级未登录 > 未绑定 > 量身定做。

#### Scenario: 未登录不展示绑定与量身定做

- **WHEN** 用户未登录
- **THEN** UI MUST NOT 展示绑定引导 Dialog
- **AND** MUST NOT 展示量身定做 Dialog
