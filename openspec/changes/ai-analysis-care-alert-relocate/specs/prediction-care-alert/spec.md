## ADDED Requirements

### Requirement: Care-alert daily fetch SHALL be manual-only from AI analysis page

The client MUST NOT invoke the care-alert daily fetch (`ensureLoaded` / repository `fetchDaily` / equivalent) from smart-prediction page entry, `UcgHomeShell` prediction-visible hooks, home-widget sync, or automatic Shanghai day-rollover side effects. The only user-facing path that MAY start a daily fetch is the AI analysis feeding module 「AI智能分析」 control (plus explicit in-module retry after failure). Eligibility and feature-catalog ensure MAY still run without calling daily. 客户端 **不得** 因进入预测页、壳层可见钩子、小组件 sync 或跨日副作用自动拉取 care-alert daily；**仅** AI 分析页「AI智能分析」（及失败重试）可发起日拉取；资格/目录 ensure **可以** 不附带 daily。

#### Scenario: 进入预测页不拉 daily

- **WHEN** 用户进入智能预测页且 session/deviceNo 门闸允许
- **THEN** 客户端 MUST NOT 因此调用 care-alert daily API

#### Scenario: 小组件 sync 不拉 daily

- **WHEN** `syncHomeWidgetFromRef`（或等价）执行
- **THEN** 客户端 MUST NOT 为填充 tip 或其它目的调用 care-alert daily ensure/fetch

#### Scenario: 仅分析页手动拉取

- **WHEN** 用户在 AI 分析页且已开通
- **AND** 点击「AI智能分析」
- **THEN** 客户端 MAY/MUST 发起 daily 拉取（按 ai-analysis-page 规格）

### Requirement: Successful manual daily refresh SHALL be limited once per Shanghai day

After a business-successful manual daily refresh for a given device on the current Shanghai calendar day, the client MUST persist that success and MUST NOT offer another manual daily refresh CTA until the next Shanghai day. Failed attempts MUST NOT set that success mark. 同一设备在上海日历日业务成功手动刷新后，客户端 **必须** 持久化成功标记且 **不得** 再展示手动刷新 CTA，直至下一上海日；失败 **不得** 写入成功标记。

#### Scenario: 跨进程仍日限

- **WHEN** 用户今日已手动成功刷新
- **AND** 进程重启后再次打开 AI 分析页且仍为同一上海日
- **THEN** 「AI智能分析」MUST 不展示

## MODIFIED Requirements

### Requirement: Care-alert presentation on prediction hub SHALL move off the smart prediction card

The smart prediction page MUST NOT render the care-alert marquee panel or the in-page eligibility/unlock progress shell formerly shown as the「值得留意」card. Care-alert list presentation for unlocked users MUST occur on the AI analysis feeding module as a vertical list (not a prediction-page marquee). Detail navigation MUST continue to use the existing care-alert detail route. 智能预测页 **不得** 再渲染值得留意跑马灯或页内资格/开通进度壳；已开通用户的列表 **必须** 在 AI 分析喂养模块纵向展示；详情 **必须** 仍走既有详情路由。

#### Scenario: 预测页无值得留意卡

- **WHEN** 已登录已绑定用户查看智能预测热态页
- **THEN** 页面 MUST NOT 展示标题为「值得留意」的留意卡片/跑马灯区块

#### Scenario: 分析页列表替代跑马灯

- **WHEN** 用户已开通且已有当日成功刷新的留意列表
- **AND** 打开 AI 分析页
- **THEN** 喂养分析模块 MUST 纵向列出各项
- **AND** MUST NOT 依赖预测页跑马灯展示这些项
