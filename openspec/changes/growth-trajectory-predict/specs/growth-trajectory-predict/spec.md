## ADDED Requirements

### Requirement: Growth trajectory module SHALL gate by entitlement or VIP without feeding eligibility

The client SHALL treat growth-trajectory as effectively unlocked when the catalog entitlement for `growth_trajectory_predict` is active **or** the user is VIP. The module MUST NOT require a feeding-eligibility scene or progress gate before unlock or prediction. Locked non-VIP users MUST be offered invite-code and/or payment unlock consistent with catalog (`inviteDurationDays` default 7 days; payment SKU ¥19 for 30 days; MUST NOT present a permanent purchase path for this feature). 成长轨迹 **必须** 以功能权益或 VIP 为有效开通；**不得** 要求喂养资格门闸；未开通非 VIP **必须** 提供与 catalog 一致的邀请（默认 7 天）与支付（¥19/30 天）路径，**不得** 提供本功能永久购买。

#### Scenario: VIP 免开通可用

- **WHEN** 用户为 VIP 且成长轨迹权益未单独开通
- **THEN** 客户端 MUST 将成长轨迹视为已开通
- **AND** MUST 允许进入预测流程（仍受服务端日限约束）

#### Scenario: 非 VIP 未开通引导

- **WHEN** 用户非 VIP 且成长轨迹未解锁
- **THEN** 模块 MUST 展示开通引导（邀请码与/或支付，依 catalog）
- **AND** MUST NOT 展示「轨迹预测」主 CTA 直至有效开通

#### Scenario: 支付为 30 天非永久

- **WHEN** 用户通过支付开通成长轨迹
- **THEN** 开通有效期 MUST 为 catalog 产品 `durationDays`（种子 30）
- **AND** 客户端 MUST NOT 将本功能表述为永久开通

### Requirement: Client SHALL load latest trajectory result on entry when unlocked

When growth trajectory is effectively unlocked, entering the AI analysis page SHALL request the Go latest-result API for the current `device_no` and, if a stored Markdown result exists, display it with a「重新预测」control. 已开通时进入 AI 分析页 **必须** 请求 Go 最新结果；有存储结果时 **必须** 展示 Markdown 并提供「重新预测」。

#### Scenario: 有历史结果直出

- **WHEN** 用户已开通且服务端存在该 device 最新轨迹 Markdown
- **THEN** 模块 MUST 展示该结果
- **AND** MUST 显示「重新预测」
- **AND** MUST NOT 默认自动开始新一轮问答

#### Scenario: 无历史结果

- **WHEN** 用户已开通且无最新结果
- **THEN** 模块 MUST 显示「轨迹预测」
- **AND** MUST NOT 伪造结果文案

### Requirement: Trajectory session SHALL use Go SSE with thinking, question, and result phases

The client SHALL call only Go APIs (not Python). Starting or answering a turn MUST consume an SSE (or equivalent streamed) session that can emit thinking deltas, a question payload, a result payload, and errors. While thinking is streaming, the module MUST show an adaptive-height thinking area and MUST apply the shared `\r` stage-clear rules via `applyThinkingStageDelta` (or equivalent). When a question or result event arrives, the client MUST hide the thinking area. 客户端 **必须** 只请求 Go；回合 **必须** 消费含 thinking / question / result / error 的流；思考中 **必须** 自适应高度展示并以 `\r` 规则更新；收到 question 或 result 后 **必须** 隐藏思考区。

#### Scenario: 点击轨迹预测进入流式思考

- **WHEN** 已开通用户点击「轨迹预测」或「重新预测」且日限未拒
- **THEN** 客户端 MUST 隐藏该主按钮并开始 turn 流
- **AND** MUST 实时展示 thinking（支持 `\r` 清阶段）
- **AND** 思考区高度 MUST 随内容自适应（可设上限并内部滚动）

#### Scenario: 收到提问

- **WHEN** 流返回 `question`
- **THEN** 客户端 MUST 隐藏思考区
- **AND** MUST 在当前卡片内展示题干
- **AND** 当 `format` 为 choice 时 MUST 渲染恰好两个选项按钮（文案为服务端 `choices`，不写死「是/否」）
- **AND** 当 `format` 为 free_text 时 MUST 提供输入与提交

#### Scenario: 收到结果

- **WHEN** 流返回 `result` Markdown
- **THEN** 客户端 MUST 隐藏思考区
- **AND** MUST 以富文本/Markdown 展示结果
- **AND** MUST 显示「重新预测」

#### Scenario: 日限错误 Toast

- **WHEN** Go 返回日限或业务错误 message
- **THEN** 客户端 MUST Toast 该 message（或非空服务端文案）
- **AND** MUST NOT 在本地自行累计或拦截「第 N 次」日限
- **AND** 问答中途 submit 失败以外的成功提问 MUST NOT 被客户端计为一次日限消耗

### Requirement: Question submit SHALL resume the same session without client-side daily counting

Submitting an answer SHALL send `sessionId` and the answer to Go and await the next streamed phase. The client MUST NOT increment any local daily-usage counter on question submit. 提交回答 **必须** 携带 session 并等待下一阶段流；客户端 **不得** 因提问提交而本地计日次。

#### Scenario: 双选项提交

- **WHEN** 用户点击两个 choice 之一
- **THEN** 客户端 MUST 提交该选项文案或约定 value
- **AND** MUST 再次进入思考/下一 phase 流

#### Scenario: 自由文本提交

- **WHEN** 用户提交非空 free_text
- **THEN** 客户端 MUST 提交文本并继续会话
- **AND** 空提交 MUST NOT 结束会话为成功结果（须提示或忽略）

### Requirement: Growth trajectory commercial catalog SHALL expose invite and timed payment only

Catalog for `growth_trajectory_predict` SHALL expose invite_code (and optional other non-permanent methods per server) and a payment product whose grant duration is 30 days at seed price 1900 fen. The feature MUST NOT ship a permanent entitlement SKU for growth trajectory. 目录项 **必须** 支持邀请与 30 天付费种子；**不得** 提供成长轨迹永久 SKU。

#### Scenario: 开通中心可见

- **WHEN** 功能 catalog 包含 `growth_trajectory_predict` 且 status 启用
- **THEN** 开通中心 MUST 展示对应卡片与开通 CTA
- **AND** 邀请文案 MUST 可体现 `inviteDurationDays`（缺字段时弱化，不得用付费天数冒充邀请天数）
