## MODIFIED Requirements

### Requirement: Portrait prediction SHALL expose a floating home-widget showcase entry

On the smart prediction **portrait** surface on Android or iOS, when the user is **logged in and bound** to a baby (`deviceNo` non-empty) and the prediction tab is visible, the client MUST show a **draggable EdgeDock circular affordance** (peek / engaged / floating) mounted on the **home shell** (same overlay layer family as the portrait prediction voice dock), not a full-width bottom pill FAB. Tapping the affordance MUST navigate to the home-widget showcase screen. The visual ball MUST be icon-led (e.g. widgets icon) to minimize chrome. The client MUST expose the pin-state label「添加桌面小组件」or「查看桌面小组件」via accessibility Semantics and/or a short engaged caption, as determined by `HomeWidget.getInstalledWidgets()` (or equivalent). The client MUST register the dock in the shared edge-dock occupancy table so it does not permanently overlap the voice or UCG square docks. The client MUST NOT show this affordance when the user is not logged in, when logged in but unbound, in landscape, when the prediction tab is not visible, on Web, or on platforms without home widgets. The client MUST NOT reserve a large list bottom inset solely for a bottom-center pill FAB. When install-state lookup fails, the client MUST treat the user as not pinned (Semantics/caption「添加桌面小组件」) if the affordance is otherwise shown.

智能预测**竖屏**且预测 Tab 可见（Android/iOS）、**已登录已绑定**时，客户端 MUST 在**主壳**上展示可拖拽的 EdgeDock 圆形入口（peek/engaged/floating），MUST NOT 使用底栏通栏 pill FAB。点按 MUST 进入小组件展示页。球面 MUST 以图标为主以降低占用。钉态文案「添加桌面小组件」/「查看桌面小组件」MUST 经 Semantics 和/或 engaged 短 caption 可达（`getInstalledWidgets` 或等价）。MUST 登记共享贴边占位，避免与语音/广场球长期重叠。未登录、未绑定、横屏、非预测 Tab、Web、无小组件平台 MUST NOT 展示。MUST NOT 仅为底栏 pill 预留大块列表底垫。查询失败且入口可见时 MUST 按未钉文案处理。

#### Scenario: 未钉竖屏可达文案

- **WHEN** 用户已登录已绑定、在预测页竖屏且 `getInstalledWidgets` 为空
- **THEN** 壳上 MUST 展示小组件 EdgeDock 球
- **AND** Semantics 或 engaged 短 caption MUST 表达「添加桌面小组件」

#### Scenario: 已钉竖屏可达文案

- **WHEN** 用户已登录已绑定、在预测页竖屏且已钉至少一个胖宝小组件
- **THEN** 壳上 MUST 展示小组件 EdgeDock 球
- **AND** Semantics 或 engaged 短 caption MUST 表达「查看桌面小组件」

#### Scenario: 点按进入展示页

- **WHEN** 用户点按小组件 EdgeDock 球
- **THEN** 客户端 MUST 导航至小组件展示页（既有 showcase 路由）

#### Scenario: 未登录无入口

- **WHEN** 用户未登录并进入预测页竖屏
- **THEN** UI MUST NOT 展示该小组件贴边球

#### Scenario: 未绑定无入口

- **WHEN** 用户已登录、无可用 deviceNo，进入预测页竖屏
- **THEN** UI MUST NOT 展示该小组件贴边球

#### Scenario: 横屏无入口

- **WHEN** 用户在预测页横屏
- **THEN** UI MUST NOT 展示该小组件贴边球

#### Scenario: Web 无入口

- **WHEN** 应用在 Web 运行
- **THEN** UI MUST NOT 展示该小组件贴边球

#### Scenario: 无底栏 pill 与超额底垫

- **WHEN** 小组件入口以 EdgeDock 球展示
- **THEN** 预测竖屏 MUST NOT 再展示底栏居中「添加/查看桌面小组件」pill FAB
- **AND** MUST NOT 仅为该 pill 保留约一屏底栏量级的列表底垫
