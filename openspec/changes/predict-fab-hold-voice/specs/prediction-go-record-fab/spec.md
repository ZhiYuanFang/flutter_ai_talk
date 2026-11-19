## MODIFIED Requirements

### Requirement: Prediction portrait SHALL show a bottom go-record pill FAB

On the smart prediction page in **portrait** orientation, the client MUST show a fixed floating pill affordance centered near the bottom of the page (same placement family as the former `PredictionWidgetShowcaseFab`: horizontally centered, inset from the bottom safe content edge). The pill MUST use `ColorScheme.primaryContainer` fill, `onPrimaryContainer` foreground, elevated material, and a large corner radius consistent with that former FAB (approximately 24). The leading control MUST be an edit-style icon (e.g. `Icons.edit_outlined`). Idle label MUST be the single-line text「去记录 · 长按语音记录」(MUST NOT wrap onto a second line). Pill width MUST size to content (`mainAxisSize.min` / intrinsic), not stretch to the full horizontal inset band. The client MUST NOT use this pill for home-widget showcase navigation. The client MUST NOT show this pill in landscape.

智能预测**竖屏** MUST 在页面底部居中展示悬浮 pill。填充 MUST 为 `primaryContainer`，前景 MUST 为 `onPrimaryContainer`，并带 elevation 与约 24 圆角。左侧 MUST 为编辑类图标；空闲文案 MUST 为单行「去记录 · 长按语音记录」（MUST NOT 换行）；宽度 MUST 随内容自适应。MUST NOT 用该 pill 进小组件展示页。横屏 MUST NOT 展示。

#### Scenario: Portrait shows go-record pill with hold hint

- **WHEN** the user is on the smart prediction page in portrait
- **THEN** a bottom-centered pill MUST be visible with single-line「去记录 · 长按语音记录」and an edit icon
- **AND** the pill MUST size width to its content without wrapping the idle label
- **AND** the pill colors MUST follow `primaryContainer` / `onPrimaryContainer`

#### Scenario: Landscape hides pill

- **WHEN** the smart prediction page is in landscape
- **THEN** the client MUST NOT show the go-record pill

#### Scenario: Pill is not the widget showcase entry

- **WHEN** the user activates the go-record pill with a short tap
- **THEN** the client MUST NOT navigate to the home-widget showcase route as the primary action of that activation

### Requirement: Go-record pill MUST switch the home pager to feeding

A **short tap** (pointer up before the long-press threshold without entering PTT) on the go-record pill MUST request the home PageView feeding page via the shared pager request API (e.g. `homePagerRequestProvider.requestPage(HomePagerPage.feeding)` or equivalent). The client MUST NOT push a duplicate full-screen feeding route solely for this affordance when the feeding page is already a home pager sibling. Long-press PTT MUST NOT perform this feeding navigation as its primary action.

**短按**「去记录」pill MUST 经共享 pager 请求切到喂养页；当喂养已是主壳 PageView 页时 MUST NOT 仅为该入口再 push 一套喂养全屏路由。长按 PTT MUST NOT 以切喂养为主动作。

#### Scenario: Tap switches to feeding

- **WHEN** the user short-taps「去记录」on the prediction portrait pill
- **THEN** the home pager MUST navigate to the feeding page

#### Scenario: Long-press does not switch pager as primary

- **WHEN** the user long-presses into PTT on the go-record pill
- **THEN** the client MUST NOT treat feeding pager navigation as that gesture’s primary success path

## ADDED Requirements

### Requirement: Go-record pill MUST heartbeat three times on basic-tier guidance request

When a guidance request token for the go-record pill is published (after dismissing the predict capability tier wall from the former voice-ball / long-press-record basic feature row, or equivalent), the go-record pill MUST play a heartbeat scale animation exactly three times to attract attention, then stop. The animation MUST NOT automatically start microphone uplink or PTT. 基础版墙引导请求到达后，「去记录」pill MUST 心跳缩放恰 3 次后停止；MUST NOT 自动开麦或进入 PTT。

#### Scenario: Three heartbeats only

- **WHEN** 基础版能力条目触发去记录引导且墙已关闭
- **THEN**「去记录」pill MUST 播放 3 次心跳动画
- **AND** MUST NOT 因此自动 `beginListen`
