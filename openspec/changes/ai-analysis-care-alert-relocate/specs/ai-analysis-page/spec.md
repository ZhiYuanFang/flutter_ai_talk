## ADDED Requirements

### Requirement: AI analysis page SHALL host feeding analysis and growth trajectory modules

The client SHALL provide a dedicated AI analysis route that contains exactly two primary modules stacked vertically: (1) feeding-record analysis (care-alert eligibility / unlock / list / manual refresh) and (2) a shallow growth-trajectory placeholder. The page MUST be reachable from the next-3-hours 「AI分析」 control. 客户端 **必须** 提供独立 AI 分析路由，纵向两模块：喂养记录分析与成长轨迹浅占位；**必须** 可由「接下来3小时」上的「AI分析」进入。

#### Scenario: 从预测页进入

- **WHEN** 用户在智能预测页点击「接下来3小时」卡片上的「AI分析」
- **THEN** 客户端 MUST 打开 AI 分析页
- **AND** 页面 MUST 同时展示喂养记录分析模块与成长轨迹占位模块

#### Scenario: 成长轨迹浅占位

- **WHEN** 用户打开 AI 分析页
- **THEN** 成长轨迹模块 MUST 展示标题与即将上线类说明
- **AND** MUST NOT 发起成长轨迹相关 HTTP
- **AND** MUST NOT 提供可用的是/否对话流

### Requirement: Feeding analysis module SHALL show explanatory blurb

The feeding-record analysis module SHALL always display a compact explanatory blurb (smaller type on a rounded background) stating that analysis uses roughly the last two days of feeding records together with the baby’s age in months and sex to surface items worth noting today. The blurb MUST remain visible across eligibility, unlock, loading, and result states. 喂养记录分析模块 **必须** 始终展示小字圆角底说明条，说明依据近两日喂养并结合月龄与性别智能分析今日值得留意之处；资格/开通/加载/结果态 **均须** 可见。

#### Scenario: 标题下展示折中说明

- **WHEN** 用户打开 AI 分析页并看到喂养记录分析模块
- **THEN** 标题行下方 MUST 展示解释性文案（含近两日喂养、月龄、性别、值得留意之意）
- **AND** 文案 MUST 为较小字号并带圆角背景

### Requirement: Feeding analysis module SHALL show eligibility and unlock gates

When the user is logged in and bound, the feeding analysis module SHALL render the same care-alert feeding-day eligibility progress and feature-unlock CTAs that previously appeared on the smart prediction care-alert card. The module MUST NOT call `care-alert/daily` solely because eligibility or catalog was ensured. 已登录绑定用户在喂养分析模块中 **必须** 展示原值得留意的喂养日资格进度与开通引导；仅 ensure 资格/目录时 **不得** 调用 daily。

#### Scenario: 未合格展示进度

- **WHEN** cash care-alert eligibility 未合格且已返回数据
- **THEN** 喂养分析模块 MUST 展示有效喂养日进度文案或等价进度控件
- **AND** MUST NOT 展示「AI智能分析」按钮

#### Scenario: 合格未开通

- **WHEN** eligibility 已合格且功能未开通且非 VIP 覆盖
- **THEN** 模块 MUST 展示开通引导
- **AND** 点击 MUST 可进入开通中心（或等价路径）
- **AND** MUST NOT 展示「AI智能分析」按钮
- **AND** 开通引导文案 MUST 以持续心跳缩放动画吸引注意

### Requirement: Manual care-alert refresh SHALL use AI智能分析 and 正在思考中

When care-alert is effectively unlocked (or VIP-covered) and the user has not yet succeeded a manual daily refresh for the current Shanghai calendar day, the feeding module SHALL show a control labeled 「AI智能分析」. While the daily request is in flight, the module MUST show transitional copy 「正在思考中」 and MUST NOT allow a concurrent second daily request from that control. On business success (non-null daily payload, including empty list), the client MUST toast 「今日值得留意刷新成功，请明日再来」, persist that the day succeeded, and hide the control for the rest of that Shanghai day. On network or business failure, the client MUST keep the 「AI智能分析」 control available for retry and MUST NOT show the success toast. 已开通且当日尚未手动成功刷新时 **必须** 显示「AI智能分析」；请求中 **必须** 显示「正在思考中」；业务成功 **必须** Toast 指定文案并隐藏 CTA 至上海日结束；失败 **必须** 保留可重试且不得成功 Toast。

#### Scenario: 未刷过点击分析

- **WHEN** 用户已开通值得留意且今日尚未手动成功刷新
- **AND** 用户点击「AI智能分析」
- **THEN** UI MUST 展示「正在思考中」
- **AND** 客户端 MUST 请求 `care-alert/daily`（或既有 repository 等价）

#### Scenario: 业务成功日限

- **WHEN** daily 请求业务成功（含空列表）
- **THEN** 客户端 MUST Toast「今日值得留意刷新成功，请明日再来」
- **AND** 「AI智能分析」MUST 不再展示直至下一上海日历日
- **AND** 列表 MUST 反映本次结果

#### Scenario: 失败可重试

- **WHEN** daily 请求网络失败或业务失败
- **THEN** 「AI智能分析」MUST 仍可点击
- **AND** 客户端 MUST NOT 弹出成功日限 Toast

### Requirement: Feeding analysis list SHALL open existing care-alert detail

When daily items are available, the feeding module SHALL list each care-alert event item vertically. Tapping an item MUST navigate to the existing care-alert detail route with that item. 有日列表时模块 **必须** 纵向展示各项；点击 **必须** 进入既有值得留意详情路由。

#### Scenario: 点击列表项

- **WHEN** 列表展示至少一条值得留意聚合项
- **AND** 用户点击该行
- **THEN** 客户端 MUST 打开既有详情页并传入该 `CareAlertEventItem`（或等价）
