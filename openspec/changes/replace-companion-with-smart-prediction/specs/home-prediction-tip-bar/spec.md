## ADDED Requirements

### Requirement: Feeding home SHALL show a fixed top prediction tip bar

While the feeding `HomeScreen` is shown, the client MUST render a long-lived fixed top prediction tip bar (not the legacy tip edge-dock ball / expandable tip card). The bar MUST display at most one tip: the nearest next prediction among events that are forecast-enabled and not hero-skipped, using local `event_next_predictor` output.

喂养主页 **必须** 长期展示顶部固定预测贴士条（非 tip 球/卡）；最多 1 条「最近下一步」，来自本地预测且已过滤推演关闭与 hero skip。

#### Scenario: 展示最近下一步

- **WHEN** 存在多个可预测且推演开启、未 skip 的事件
- **THEN** 顶栏 MUST 仅展示 `nextAt` 最早的那一条（含倒计时或已超时文案）

### Requirement: History data changes MUST recompute the prediction tip

Whenever local feeding history data used for prediction changes (create/update/delete or equivalent history provider updates, including remote WS-driven changes reflected in local state), the client MUST recompute the tip from local prediction. The client MUST NOT call `/device/tip/generate` for this tip bar.

历史数据变化时 **必须** 本地重算贴士；**不得** 为此调用 tip generate SSE。

#### Scenario: CRUD 后更新贴士

- **WHEN** 用户新增、编辑或删除一条喂养历史且本地 history 状态已更新
- **THEN** 顶栏预测贴士 MUST 基于最新 history 重算

#### Scenario: 不请求 tip SSE

- **WHEN** 本机按钮路径 add 成功
- **THEN** 客户端 MUST NOT 因该成功调用 `/device/tip/generate`（或 `tipProvider.startStreaming`）

### Requirement: Empty prediction tip SHALL show 暂无预测

When no eligible next prediction exists (insufficient samples, all forecast toggles off, or all candidates skipped), the fixed tip bar MUST remain visible and MUST show the copy「暂无预测」.

无合格下一步时顶栏 **必须** 仍占位并展示「暂无预测」。

#### Scenario: 样本不足空态

- **WHEN** 本地无法对任何开启推演的事件计算出预测
- **THEN** 顶栏 MUST 显示「暂无预测」
- **AND** MUST NOT 隐藏整条占位条

### Requirement: Tip skip SHALL reuse widget hero skip store

Activating「跳过」on the tip bar MUST record skip via the same local store and lifetime rules as desktop widget hero skip (`WidgetHeroSkipStore` / `widget-hero-skip`), MUST promote the next eligible prediction on the tip bar, and MUST refresh the home widget payload so hero and tip stay aligned.

顶栏「跳过」**必须** 复用小组件 hero skip 存储与生命周期，提升下一条，并刷新小组件使双边一致。

#### Scenario: 跳过后双边升位

- **WHEN** 预测序列为 A、B（按 nextAt）且顶栏与小组件 hero 均为 A
- **AND** 用户在顶栏点击「跳过」
- **THEN** 顶栏 MUST 展示 B（若 B 合格）
- **AND** 随后小组件 hero MUST 为 B（或等价同步刷新后结果）

### Requirement: Non-skip tip tap SHALL open smart prediction page

A tap on the tip bar outside the skip control MUST navigate the home PageView to the smart prediction page (index 0). The tap MUST NOT open Clinic/companion chat.

点击贴士非跳过区域 **必须** 进入智能预测页，**不得** 打开陪伴聊天。

#### Scenario: 点贴士进预测页

- **WHEN** 顶栏展示某预测贴士（或「暂无预测」）
- **AND** 用户点击非「跳过」热区
- **THEN** PageView MUST 切换到智能预测页（index 0）

### Requirement: Prediction tip bar SHALL show event logo and event-colored countdown

When the tip bar displays an eligible next prediction, the client MUST show that event’s logo via the shared `EventLogo` (or equivalent catalog branding) adjacent to the title, and MUST render the countdown / overdue subtitle using the event’s brand color (`colorHex` from prediction or catalog). When showing「暂无预测」or loading with no tip, the client MUST NOT require an event logo.

有合格预测时顶栏 **必须** 展示事件 logo，且倒计时/已超时文案 **必须** 使用事件品牌色；「暂无预测」等空态 **不得** 强制展示事件图。

#### Scenario: 有预测时 logo 与事件色

- **WHEN** 顶栏展示事件 A 的最近下一步
- **THEN** UI MUST 在标题旁展示 A 的 `EventLogo`（或缺省占位）
- **AND** 倒计时或已超时文案颜色 MUST 为 A 的事件色（解析失败时 MAY 回退主题 primary）

#### Scenario: 空态无强制 logo

- **WHEN** 顶栏展示「暂无预测」
- **THEN** UI MUST NOT 要求展示某一事件的 logo
