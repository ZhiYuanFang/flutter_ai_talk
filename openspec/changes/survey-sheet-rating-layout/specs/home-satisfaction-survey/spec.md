## MODIFIED Requirements

### Requirement: Sheet shows options and free-text feedback

When current returns `show=true`, the client MUST present a sheet with the intro, one row per option, and a trailing free-text field for additional comments, including when the options list is empty. The title 「满意度」 MUST remain outside the scrolling region. The intro and the option rows MUST scroll together. The comment field, the inline error, and the submit button MUST stay below that list and MUST NOT scroll away with the option rows. Each option row MUST offer exactly two mutually exclusive choices labeled 不好用 and 好用, placed on the right of the option text, and MUST NOT wrap onto a separate line under the text. A row that has no choice MUST NOT be treated as 未使用. The two choices MUST use distinct unselected frames and distinct selected fills: 不好用 MUST use the error color, and 好用 MUST use the primary color. The selected fill of a choice MUST stay in the same color family as its unselected frame. The client MUST ignore a non-zero `campaignId` when `show` is false and MUST NOT present the sheet. The text controller MUST be owned by the sheet State and disposed with that State. The comment field MUST stop further input at 1000 characters. Before submit the client MUST trim the comment and MUST NOT call submit when that trimmed text exceeds 1000 Unicode code points; it MUST show that reason above the submit button and leave the sheet open, and MUST NOT toast. The client MUST submit only the rows that have a choice, in `options` order, and MUST omit rows with no choice. Submitting with no rated row and a blank comment MUST NOT call submit and MUST show the reason above the submit button, whether or not the options list is empty. Submitting with no rated row and a non-empty comment within that limit MUST be allowed with `optionResults` empty. Submitting with at least one rated row MUST be allowed even if the comment is blank and some rows have no choice. For each rated row the client MUST append the chosen label directly to that option's `text` from the current response, with no separator, and MUST send those strings as `optionResults` in the same order as `options`. The submit body MUST use `campaignId`, `optionResults`, and `comment`, and MUST NOT include `optionIds`. Colors MUST use `AppColor` (or paired visual tokens), not hard-coded gray or white body text. `show=true` 时 MUST 用 sheet 呈现说明、每项三评与更多意见（选项可为空）。标题「满意度」MUST 不随列表滚动；说明与选项行一起滚；意见、错误和提交按钮 MUST 留在列表下方。两个评价 MUST 贴在选项文案右侧且不换到文案下一行。不好用、好用 MUST 分别使用错误色和主题色，选中实底与未选边框同一色系。没选的行 MUST NOT 当成未使用。没选的行 MUST NOT 进入 `optionResults`。一项都没选且意见为空白时 MUST NOT 提交。至少评了一行，或只写了意见，MUST 允许提交。提交体 MUST 为 `campaignId`、`optionResults`、`comment`，MUST NOT 发送 `optionIds`。每条结果 MUST 是选项原文直接连接所选中文。意见超过 1000 个 Unicode 码位、有行未评或双空时 MUST NOT 提交，并在提交按钮上方展示原因，MUST NOT toast。

#### Scenario: 只填意见可以提交

- **WHEN** current 的选项列表为空，用户在更多意见中输入非空文本并提交
- **THEN** 客户端 MUST 调用 submit，且 `optionResults` 为空数组

#### Scenario: 双空不提交

- **WHEN** 选项列表为空，意见为空白，用户点提交
- **THEN** 客户端 MUST NOT 调用 submit
- **AND** MUST 在提交按钮上方展示原因

#### Scenario: 意见超过 1000 字不提交

- **WHEN** 用户提交时，trim 后的意见超过 1000 个 Unicode 码位
- **THEN** 客户端 MUST NOT 调用 submit
- **AND** MUST 在提交按钮上方说明过长，MUST NOT toast，且 sheet MUST 仍然打开

#### Scenario: 只评部分行可以提交

- **WHEN** 选项列表非空，用户只给其中一行选出评价，意见为空白
- **THEN** 客户端 MUST 调用 submit
- **AND** `optionResults` MUST 只包含已选行，且顺序与 `options` 中这些行的顺序一致

#### Scenario: 每行已评且意见为空可以提交

- **WHEN** 每一行都选择了两个评价之一，意见为空白
- **THEN** 客户端 MUST 调用 submit
- **AND** `optionResults` MUST 与选项顺序一致，每一项为该选项原文直接连接所选的「不好用」或「好用」
- **AND** 请求体 MUST NOT 包含 `optionIds`

#### Scenario: 未选行不会变成未使用

- **WHEN** 用户只给其中一行选了「好用」，其他行未选并点提交
- **THEN** 客户端 MUST 调用 submit
- **AND** `optionResults` MUST 只有这一条，且为该选项原文直接连接「好用」
- **AND** MUST NOT 包含未选行

#### Scenario: 标题不随选项滚动

- **WHEN** 选项行超出 sheet 可视高度，用户滚动选项列表
- **THEN** 标题「满意度」MUST 仍留在可视区域
- **AND** 更多意见与提交按钮 MUST 仍留在列表下方

#### Scenario: 评价贴在行右侧

- **WHEN** sheet 展示一条选项
- **THEN** 两个评价 MUST 位于该选项文案的右侧
- **AND** MUST NOT 排到文案下一行

#### Scenario: 两种评价样式不同

- **WHEN** 用户分别选中不好用和好用
- **THEN** 两种选中实底 MUST 分属错误色和主题色
- **AND** 同一种评价的未选边框与选中实底 MUST 属于同一色系
