## MODIFIED Requirements

### Requirement: Care-alert strip SHALL always show with state-specific body copy

The smart prediction page MUST always show the care-alert card area while the page is visible. The body MUST be「加载中…」while the daily fetch is in progress or not ready,「接口异常」with a refresh control on failure, and when the successful client-filtered list is empty the card MUST omit the「值得留意」title, show「宝宝成长得真棒！」, and open companion on tap. When the filtered list is non-empty, the card MUST show the「值得留意」title and item marquee. The next-3-hours timeline MUST NOT require a non-empty care-alert list; it MUST appear when forecast-enabled window segments exist, including under the empty care-alert state.

智能预测页可见时 **必须** 始终显示该卡片区；加载中正文 **必须** 为「加载中…」；失败 **必须** 为「接口异常」并带刷新；成功空列表 **必须不** 显示「值得留意」标题、正文为「宝宝成长得真棒！」且点击进陪伴；非空 **必须** 显示标题与跑马灯；「接下来3小时」**不得** 要求留意列表非空，有窗内段落时（含空留意态）**必须** 可展示。

#### Scenario: 加载中显示卡片

- **WHEN** 日拉取仍在进行
- **THEN** 页面 MUST 显示值得留意卡片且正文为「加载中…」

#### Scenario: 成功非空跑马灯

- **WHEN** 日拉取成功且过滤后至少一项
- **THEN** 页面 MUST 显示值得留意跑马灯区块

#### Scenario: 空留意仍可显示三小时时间线

- **WHEN** 留意过滤后为空，且存在推演开启且 nextAt 在 now+3h 内的预测
- **THEN** 页面 MUST 仍可显示「接下来3小时」时间线
