## ADDED Requirements

### Requirement: Bound hot prediction rows SHALL be catalog-root complete

When the user is logged in and bound (usable deviceNo) and the smart prediction page is rendering hot (non-demo-skeleton) rows, the client MUST emit one prediction row for every catalog root event (`parentId == null`), including roots with no merged history and roots whose forecast is disabled. Absence of history MUST NOT omit the row; it MUST only leave `lastAt` / `prediction` / chart points empty as applicable. The client MUST NOT show the「回忆宝宝习惯」`AppEmptyStateGallery` (or equivalent empty-copy CTA that only reopens recall onboarding) solely because merged history is empty when the catalog has at least one root.

已登录已绑定且热态（非 demo 骨架）时，客户端 **必须** 为目录每一个非子根事件（`parentId == null`）产出一行预测卡，**包括**无合并历史与已关推演的根；无历史 **不得** 省略该行，仅可使 `lastAt` / `prediction` / 图表点为空。当目录至少有一个根时，**不得** 仅因合并历史为空展示「回忆宝宝习惯」类缺省 Gallery（或其仅用于重开量身定做的等价空态 CTA）。

#### Scenario: 空库仍全量根卡

- **WHEN** 用户已绑定、预测 range 就绪且真历史为空、目录含多个无父根
- **THEN** 主内容 MUST 展示覆盖这些根的热态预测卡
- **AND** MUST NOT 展示「回忆宝宝习惯」缺省 Gallery

#### Scenario: 半记录仍出未记过的根卡

- **WHEN** 用户仅对部分根有真历史
- **THEN** UI MUST 仍展示尚未出现过历史的其它无父根卡
- **AND** 有历史的根 MUST 按既有规则填 `lastAt` / `prediction`

#### Scenario: 已关推演仍占位

- **WHEN** 某无父根在 `forecastDisabledIds` 中
- **THEN** 该根 MUST 仍出现在行列表中且 `forecastEnabled == false`
- **AND** MUST NOT 因此被从列表中删除

### Requirement: Sparse hot cards SHALL offer heartbeat add-last CTA when forecast enabled and lastAt missing

On a hot (non-demo-skeleton) prediction event card whose forecast is enabled, `prediction` is null, and `lastAt` is null, the card MUST show a full-width event-accent heartbeat control labeled to the effect of「补充上一次」(same heartbeat pattern as「补充大概多久一次」/ in-timer「停止」). Activating it MUST invoke the same add-event path as tapping the card (`handleEventGridTap` with `confirmDirectLeafBeforeAdd: true` for grid). The client MUST NOT show the interval-recall CTA on that card while `lastAt` is null. When forecast is disabled, the client MUST NOT show「补充上一次」, MUST NOT show the interval CTA, and MUST NOT treat a card tap as the add-event fill path.

热态预测卡在推演开启、`prediction == null` 且 `lastAt == null` 时，**必须** 展示与间隔 CTA /「停止」同风格的全宽事件色心跳控件「补充上一次」；点击 **必须** 走与点卡相同的加事件路径（网格含 `confirmDirectLeafBeforeAdd: true`）。`lastAt == null` 时 **不得** 展示间隔回忆 CTA。推演关闭时 **不得** 展示「补充上一次」与间隔 CTA，且 **不得** 将点卡作为补齐加事件路径。

#### Scenario: 无上次仅补上次心跳

- **WHEN** 热态某根卡 `forecastEnabled == true`、`lastAt == null`、`prediction == null`
- **THEN** 卡 MUST 展示心跳「补充上一次」
- **AND** MUST NOT 展示「补充大概多久一次」
- **AND** 点击「补充上一次」MUST 打开与点该卡相同的加喂养流程

#### Scenario: 关推演无补齐

- **WHEN** 热态某根卡 `forecastEnabled == false`
- **THEN** MUST NOT 展示「补充上一次」
- **AND** MUST NOT 展示「补充大概多久一次」
- **AND** 点卡 MUST NOT 触发加喂养补齐路径

### Requirement: Prediction event card chrome SHALL be driven by parameters not per-type widgets

The hot prediction event card MUST render sparse / interval-fill / countdown / active-timing chrome from a single card widget (or equivalent) whose visible actions and body are determined by input parameters or a derived action list, and MUST NOT introduce separate top-level card widget types solely for empty-history vs partial-history vs interval-gap.

热态预测事件卡的稀疏补齐 / 间隔补齐 / 倒计时 / 计时中 chrome **必须** 由单一卡片组件（或等价）依据入参或派生 action 列表展示，**不得** 仅为空历史、半历史、缺间隔等分别引入顶层分型卡片 Widget。

#### Scenario: 同一卡组件切换状态

- **WHEN** 同一根事件从无 `lastAt` 变为有 `lastAt` 仍无 `prediction`，再变为有 `prediction`
- **THEN** UI MUST 仍由同一卡片组件实例族渲染
- **AND** 可见 CTA / body MUST 随入参从「补充上一次」变为「补充大概多久一次」再变为 countdown

### Requirement: Hot prediction cards SHALL open feeding history edit sheet from last-occurrence label

When a hot (non-demo-skeleton) prediction event card shows the「上一次{事件名}：…」label and the client can resolve a **real** feeding `HistoryRecord` (not a recall-seed synthetic record) as the latest occurrence under that catalog root from home and/or prediction-range history, activating the label MUST open the same `showHomeHistoryEditSheet` used on the feeding history list for that record. The tap MUST NOT trigger the card’s add-event path. When the label shows「暂无」or no real record can be resolved, the label MUST NOT be tappable for edit.

热态预测卡展示「上一次{事件名}：…」且客户端能从喂养 home 与/或预测 range **真历史**解析出该目录根下最新一条非回忆种子 `HistoryRecord` 时，点按该文案 **必须** 打开与喂养历史列表相同的 `showHomeHistoryEditSheet`。该点按 **不得** 触发整卡加事件路径。「暂无」或无法解析真记录时，该文案 **不得** 作为编辑入口可点。

#### Scenario: 有真记录点上一次进编辑

- **WHEN** 热态某根卡展示「上一次…」且该 root 在真喂养历史中存在至少一条记录
- **THEN** 点按该文案 MUST 打开 `showHomeHistoryEditSheet`，record 为该 root 最近发生的真记录
- **AND** MUST NOT 因此调用加喂养 `handleEventGridTap`

#### Scenario: 暂无不可点编辑

- **WHEN** 热态某根卡「上一次」文案为「暂无」或仅有回忆种子伪记录、无真历史
- **THEN** 该文案 MUST NOT 打开历史编辑 Sheet

## REMOVED Requirements

### Requirement: While recall onboarding is visible chrome panels MUST be hidden

**Reason**：量身定做 Dialog / 引导层已退役，不再叠在热态预测页上，无需再规定引导期隐藏留意/三小时/底 tip。

**Migration**：热态 chrome 恢复按各能力自身有数据门闸展示；不再依赖 `predictionRecallDialogVisible` / 会话层隐藏。
