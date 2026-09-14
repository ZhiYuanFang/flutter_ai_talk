## MODIFIED Requirements

### Requirement: Feeding once-per-day expectation copy SHALL appear on hub and workspace

The feeding hub card (when unlocked) SHALL display compact helper copy stating that analysis is supported only once per day (文案：每日仅支持分析一次 or equivalent). On the feeding workspace, when the 「AI智能分析」 AppBar control is visible, the same once-per-day helper copy MUST appear as small text directly under that control (same structural slot as growth-trajectory usage copy under its AppBar CTA), and MUST NOT be presented as an in-card subtitle under a glass capability card title. This copy is informational and MUST NOT by itself hide the 「AI智能分析」 control. 喂养 Hub 已开通卡 **必须** 展示「每日仅支持分析一次」（或等价）；喂养工作台在 AppBar「AI智能分析」可见时 **必须** 将该说明挂在该 CTA 正下方小字，**不得** 再作为玻璃卡内标题下副文案；该文案 **不得** 单独作为隐藏「AI智能分析」的条件。

#### Scenario: Hub unlocked shows once-per-day copy

- **WHEN** the feeding hub card is effectively unlocked
- **THEN** 卡上 MUST 可见每日一次说明

#### Scenario: Workspace shows once-per-day under AppBar CTA

- **WHEN** the feeding workspace shows the AppBar 「AI智能分析」 control
- **THEN** 工作台 MUST 在该 CTA 正下方可见每日一次说明
- **AND** MUST NOT rely on a glass in-card title subtitle for that copy

## ADDED Requirements

### Requirement: Feeding workspace chrome SHALL match growth flat shell

The feeding analysis workspace MUST NOT wrap its primary content in a glass capability card (`panelGlassGradient` / equivalent blurred bordered card). The workspace MUST use a page background that gradients from `pageBg` (or equivalent shell page color) toward a tint of the care-alert feature accent, with a transparent AppBar over that gradient (`extendBodyBehindAppBar` or equivalent). Body content MUST be a flat vertical stack: intro blurb then eligibility / unlock / thinking / list body—without a duplicate in-body title row that repeats the AppBar title. Result list rows MAY use dividers but MUST NOT reintroduce a surrounding glass card. 喂养工作台 **必须** 无玻璃能力卡外壳，**必须** 采用页底功能色渐变 + 透明 AppBar，**必须** 平铺 blurb + body；列表 **不得** 再包回玻璃卡。

#### Scenario: No glass card on feeding workspace

- **WHEN** the feeding analysis workspace is shown
- **THEN** primary content MUST NOT be enclosed in a glass capability card shell
- **AND** the page MUST show a feature-accent-tinted vertical gradient background

#### Scenario: Flat blurb then body

- **WHEN** the feeding workspace renders its main scroll content
- **THEN** the intro blurb MUST appear above the body region without an in-body duplicate module title row
