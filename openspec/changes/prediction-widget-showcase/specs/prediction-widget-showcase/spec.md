## ADDED Requirements

### Requirement: Portrait prediction SHALL expose a floating home-widget showcase entry

On the smart prediction page in **portrait** orientation on Android or iOS, the client MUST show a fixed floating affordance that navigates to the home-widget showcase screen. The label MUST be「添加桌面小组件」when no pangbao home widget is pinned, and「查看桌面小组件」when at least one is pinned, as determined by `HomeWidget.getInstalledWidgets()` (or equivalent). The client MUST NOT show this affordance in landscape, on Web, or on platforms without home widgets. When install-state lookup fails, the client MUST treat the user as not pinned (show「添加桌面小组件」).

智能预测**竖屏**（Android/iOS）**必须** 展示固定悬浮入口进入小组件展示页；未钉文案「添加桌面小组件」，已钉「查看桌面小组件」。横屏 / Web / 无小组件平台 **必须 NOT** 展示。查询失败 **必须** 按未钉处理。

#### Scenario: 未钉竖屏文案

- **WHEN** 用户在预测页竖屏且 `getInstalledWidgets` 为空
- **THEN** 悬浮入口 MUST 展示「添加桌面小组件」

#### Scenario: 已钉竖屏文案

- **WHEN** 用户在预测页竖屏且已钉至少一个胖宝小组件
- **THEN** 悬浮入口 MUST 展示「查看桌面小组件」

#### Scenario: 横屏无入口

- **WHEN** 用户在预测页横屏
- **THEN** UI MUST NOT 展示该悬浮入口

#### Scenario: Web 无入口

- **WHEN** 应用在 Web 运行
- **THEN** UI MUST NOT 展示该悬浮入口

### Requirement: Showcase page SHALL branch copy and refresh by pin state

The home-widget showcase screen MUST include a Flutter preview of the **large** widget only (visual affinity to the native large layout; pixel-perfect parity is NOT required). When the user has **not** pinned a widget, the screen MUST show setup / how-to-add instructions and MUST NOT show a「刷新小组件数据」control. When the user **has** pinned at least one widget, the screen MUST show capability-oriented copy instead of setup instructions, and MUST provide「刷新小组件数据」that refreshes widget payload via the existing ensure/sync path (`ensureWidgetReadyFromRef` or equivalent) and confirms success to the user.

展示页 **必须** 仅含 large Flutter 预览。未钉：**必须** 设置说明且 **必须 NOT** 刷新按钮。已钉：**必须** 能力说明（非安装教程）且 **必须** 提供刷新（既有 sync）并成功提示。

#### Scenario: 未钉页无刷新

- **WHEN** 用户进入展示页且未钉小组件
- **THEN** 页内 MUST 展示如何添加的说明
- **AND** MUST NOT 展示「刷新小组件数据」
- **AND** MUST 展示 large 预览

#### Scenario: 已钉页有刷新与能力说明

- **WHEN** 用户进入展示页且已钉小组件
- **THEN** 页内 MUST 展示能力说明且 MUST NOT 以安装步骤作为主文案
- **AND** MUST 展示「刷新小组件数据」
- **AND** MUST 展示 large 预览

#### Scenario: 刷新成功

- **WHEN** 已钉用户点击「刷新小组件数据」且 sync/ensure 成功
- **THEN** 客户端 MUST 更新桌面小组件数据
- **AND** MUST 向用户给出成功反馈（Toast/SnackBar 或等价）

### Requirement: Large in-app preview SHALL reuse widget data semantics

The large Flutter preview MUST derive header/rows/visual styling from the same widget prediction inputs and builders used for home-widget payload sync (e.g. `buildWidgetRows` with large kind and theme visual tokens). The preview MUST handle empty and loading-ready states with user-visible copy consistent with widget empty/loading messaging. The preview MUST NOT call backend APIs solely for preview beyond what sync already uses.

large 预览 **必须** 复用与桌面 sync 同源的行/头/视觉语义；**必须** 覆盖空/准备中态；**不得** 仅为预览另拉专用后端。

#### Scenario: 有预测行时预览

- **WHEN** 本地可构建 large 行数据
- **THEN** 预览 MUST 展示头部（若有宝宝）与 large 桌面同构区块（tip / 预测即将发生 hero / 横向后续留意）
- **AND** MUST 以事件 logo（非仅色条）展示 hero 与 recent 项

#### Scenario: 无内容时预览

- **WHEN** 无可用 active/predict 行
- **THEN** 预览 MUST 展示 empty 或 loading 语义文案（与小组件常量一致或等价）

### Requirement: Large preview SHALL show event logos and match desktop large layout

The in-app large preview MUST render event logos for hero and recent cells (from enriched `logoFile` and/or catalog logo assets with placeholder fallback) and MUST NOT use color-bar-only rows as the primary event affordance. The preview layout MUST follow the desktop large structure: header with brand mark, optional tip section, centered upcoming hero row with logo, and a horizontal recent strip (up to three cells with logos). Pixel-perfect RemoteViews parity is NOT required.

应用内 large 预览 **必须** 展示事件 logo（enrich/`logoFile` 或 catalog 占位），**不得** 仅以色条作为主标识；排版 **必须** 对齐桌面 large（头+品牌标、tip、居中 hero+logo、横向最多三格 recent+logo）。
