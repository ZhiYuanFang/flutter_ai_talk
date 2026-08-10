## ADDED Requirements

### Requirement: Smart prediction page SHALL show a next-3-hours timeline under care alerts when both have content

When there exists at least one forecast-enabled predicted event whose `nextAt` is at or before `now + 3 hours` (including overdue `nextAt` values), the client MUST render a timeline block titled「接下来3小时」in the smart prediction page chrome (typically below the care-alert card area). Each segment MUST be formatted like `HH:mm 左右{eventName}` and segments MUST be joined with「 → 」, ordered by ascending `nextAt`. Forecast-disabled events MUST NOT appear. The timeline MUST NOT require a non-empty「值得留意」list. If no segment qualifies, the timeline block MUST NOT be shown.

当存在推演开启、可预测且 `nextAt ≤ now+3h`（含已超时）的事件时，客户端 **必须** 在智能预测页展示「接下来3小时」时间线（通常在留意卡片区下方）；段落为 `HH:mm 左右{事件名}`，以「 → 」连接并按 `nextAt` 升序；推演关闭 **不得** 入列；**不得** 要求「值得留意」非空；无窗内段落时 **不得** 展示该块。

#### Scenario: 有窗内事件

- **WHEN** 事件 A、B 推演开启、`nextAt` 均在 now+3h 内（可含超时）
- **THEN** 页面 MUST 出现「接下来3小时」时间线
- **AND** 文案 MUST 含按时间排序的「左右」段落并以「 → 」连接

#### Scenario: 空留意仍可展示

- **WHEN** 值得留意为空，且存在窗内预测事件
- **THEN** MUST 仍可展示「接下来3小时」时间线块

#### Scenario: 推演关闭排除

- **WHEN** 事件 C 推演关闭且其 `nextAt` 本在窗内
- **THEN** 时间线 MUST NOT 包含事件 C

### Requirement: Next-3-hours timeline SHALL wrap with expand/collapse and navigate to feeding home

The timeline body MUST wrap onto multiple lines when content is long. By default the body MUST be collapsed to a limited number of visible lines; the client MUST provide an expand/collapse control that toggles full vs collapsed text without navigating. Activating the primary timeline tap target (the timeline content or card, excluding the expand/collapse control) MUST navigate to the feeding home page of the main pager and MUST NOT open companion chat.

时间线正文过长时 **必须** 折行；默认收起为有限行数；**必须** 提供仅切换展开/收起、不导航的控件；点击时间线主热区 **必须** 进入喂养主页，**不得** 打开陪伴聊天。

#### Scenario: 展开收起

- **WHEN** 时间线正文超出默认收起行数
- **THEN** 用户 MUST 能通过展开/收起控件在完整与收起间切换
- **AND** 该控件 MUST NOT 单独触发页面导航

#### Scenario: 点击进喂养页

- **WHEN** 用户点击时间线主内容区（非展开控件）
- **THEN** 客户端 MUST 切换至喂养主页（PageView feeding）
- **AND** MUST NOT 打开陪伴聊天
