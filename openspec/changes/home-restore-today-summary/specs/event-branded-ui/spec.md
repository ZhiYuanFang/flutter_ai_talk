## ADDED Requirements

### Requirement: 今日汇总展示

The home today summary chips MUST show each aggregated event with its logo and brand color. 主页「今日」汇总区每个 chip 必须在文案旁展示对应事件的 **logo** 与品牌色（浅底或边框使用品牌色 alpha）；聚合必须按 **`eventId`** 与事件目录对齐，不得仅按易重名的 `eventName` 字符串合并不同事件。今日区 MUST 挂载在喂养沉浸身份头下方、历史列表上方；当当日无有效总额时 MUST NOT 强制占位。本 Requirement 仅约束展示；chip 打开今昨小时趋势 Sheet 不在本能力范围内。

#### Scenario: 今日有多类事件

- **WHEN** 当日历史含多个不同 `eventId` 的有效记录
- **THEN** 今日区必须分别展示各事件的 chip，且各 chip 视觉可区分

#### Scenario: 无今日总额

- **WHEN** `aggregateTodayTotals`（或等价）结果为空
- **THEN** 今日汇总区 MUST NOT 占用可见高度（shrink 或等价）

#### Scenario: 位于身份头与历史之间

- **WHEN** 用户打开喂养页且今日 totals 非空
- **THEN** 今日汇总区 MUST 出现在沉浸身份头下方、历史列表上方
