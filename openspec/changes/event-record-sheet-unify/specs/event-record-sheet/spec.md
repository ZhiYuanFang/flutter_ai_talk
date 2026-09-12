## ADDED Requirements

### Requirement: Unified event record sheet SHALL cover supplement, number-add, and edit

The client MUST present a single primary glass event-record bottom sheet entry (e.g. `showEventRecordSheet`) for intents `supplement`, `add` (number type only), and `edit`. The sheet MUST show the event logo and a title that is the event display name only (MUST NOT prefix with `补充·` / `新增·` / `编辑·`). Non-quantity `add` (`time` / `one`) MUST NOT open this sheet. Date and time-of-day pickers MAY remain separate lightweight sheets invoked from the time line. Primary action labels MAY still distinguish supplement vs add vs save.

客户端 **必须** 以单一主业务玻璃底部 Sheet 入口承载 `supplement`、仅 number 的 `add`、以及 `edit`；标题 **必须** 仅为事件名，**不得** 加「补充·/新增·/编辑·」前缀。普通新增非量 **不得** 打开该 Sheet。日期/时分 **可以** 仍为点击时间行后弹出的轻量子 Sheet。主按钮文案 **可以** 仍区分确认补充 / 确认记录 / 保存。

#### Scenario: 补充配方奶标题

- **WHEN** 用户以 supplement intent 打开某事件记录 Sheet
- **THEN** 标题 MUST 仅为该事件名，MUST NOT 含「补充·」前缀

#### Scenario: 新增 number 标题

- **WHEN** 用户从喂养格打开 number 类型新增
- **THEN** 客户端 MUST 打开统一 Sheet 且标题 MUST 仅为事件名

#### Scenario: 编辑标题

- **WHEN** 用户打开既有历史编辑
- **THEN** 标题 MUST 仅为事件显示名，MUST NOT 含「编辑·」前缀

#### Scenario: 喂养格计时不弹主 Sheet

- **WHEN** 用户在喂养格点击 time 类型叶子且 intent 为 add
- **THEN** 客户端 MUST NOT 打开统一记录 Sheet，MUST 按现网直接提交开始=now、结束=0

### Requirement: Supplement intent MUST require cross-day time selection for all event types

When intent is `supplement`, the client MUST open the unified sheet for `one`, `time`, and `number`, MUST allow selecting a calendar day from baby birth date through today inclusive, and MUST default the initial instant to today at the current local time-of-day. For `time`, start MUST be required and end MUST be optional (unset means in-progress / `endTime` epoch 0). For `one` and `number`, the single occurrence instant MUST be used for both start and end as today. The client MUST NOT show a「清除结束」control in this change; correcting a mistaken end MUST be by deleting the record or editing the end instant.

补充 intent 下，`one`/`time`/`number` **必须** 打开统一 Sheet，日期范围 **必须** 为生日→今日，初值 **必须** 为今日·当下。计时开始必填、结束可选（空=进行中）。本期 **不得** 提供清除结束；记错 **必须** 靠删除或改结束时刻。

#### Scenario: 补充非量选过去日

- **WHEN** 用户补充 one 类型并将发生日改为昨天后确认
- **THEN** 提交的 start/end MUST 落在昨天所选时分

#### Scenario: 补充计时仅开始

- **WHEN** 用户补充 time 类型只设开始、结束仍为「进行中」并确认
- **THEN** 提交 MUST 含开始时刻且 endTime MUST 为未结束语义（epoch 0）

#### Scenario: 点进行中设结束

- **WHEN** 用户点击「进行中」并确认一时分（默认今日·当下可改）
- **THEN** 界面 MUST 将结束侧从「进行中」变为所选「日·时」，且 MUST NOT 提供清除回进行中的专用控件

### Requirement: Centered segmented time line SHALL replace labeled date-time rows on the record sheet

On the unified event record sheet, the client MUST NOT show separate「开始时间」/「结束时间」（or equivalent）field labels for the time block. The client MUST render a horizontally centered time line: for a single instant, `{日文案}·{HH:mm}` with the day segment in a smaller type size than the time segment; for timing with end set, `{日起}·{时起} ~ {日止}·{时止}`; for timing in progress, `{日起}·{时起} ~ 进行中`. Tapping the day segment MUST open the date wheel sheet; tapping the time segment MUST open the hour/minute wheel sheet; tapping「进行中」MUST begin setting the end instant (picker defaults today + now). Day labels MUST follow `formatHistoryDaySectionLabel` (or the same rules as home history day headers).

统一记录 Sheet 时间区 **不得** 再展示「开始/结束」类标签；**必须** 横向居中分段文案（日小字、时大字）；分别点击日/时打开既有滚轮；「进行中」可点以设结束。日文案规则 **必须** 与历史日标题一致。

#### Scenario: 单点时刻展示

- **WHEN** Sheet 展示 one 或 number 的发生时刻为今天 16:24
- **THEN** 居中行 MUST 同时含日文案与 `16:24`，且时刻字号 MUST 大于日文案

#### Scenario: 计时进行中展示

- **WHEN** 计时记录结束未设
- **THEN** 居中行 MUST 匹配「起 ~ 进行中」形态且「进行中」可点

#### Scenario: 分别改日与时

- **WHEN** 用户点击日段并选新自然日，再点击时段并选新时分
- **THEN** 展示与提交 MUST 反映组合后的完整瞬间

### Requirement: Prediction confirm-add dialog SHALL remain for non-quantity add only

When the prediction page invokes add on a direct leaf with `confirmDirectLeafBeforeAdd` and intent is `add` and type is `time` or `one`, the client MUST keep showing the「确认添加」glass confirm dialog before submitting now. When intent is `supplement`, the client MUST NOT show that confirm dialog before the unified sheet.

预测页直点叶子在 **普通新增** 非量时 **必须** 仍先「确认添加」；**补充** 路径 **不得** 在打开统一 Sheet 前再弹该确认框。

#### Scenario: 有 lastAt 点卡非量仍确认

- **WHEN** 预测热态卡有 lastAt、用户点卡触发 add、事件为 time/one 叶子
- **THEN** 客户端 MUST 先展示「确认添加」再提交 now

#### Scenario: 无 lastAt 补充不套确认框

- **WHEN** 用户点击「补充上一次」或无 lastAt 点卡进入 supplement
- **THEN** 客户端 MUST 直接打开统一 Sheet 且 MUST NOT 先弹「确认添加」
