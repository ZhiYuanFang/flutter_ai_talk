## ADDED Requirements

### Requirement: Live affinity prediction SHALL chase overdue nextAt via predicted tip and re-affinity

For **live** non-appointment affinity prediction（smart prediction cards, next-3-hours, home-widget, feeding next-prompt consumers）, after the client computes a candidate `nextAt` from the normal true-`lastAt` + interval path（including existing TOD density guard / autoSkip）, when `now − nextAt > 2 hours`, the client MUST run a missed-cycle chase of at most **3** steps. Each step MUST: (1) set tip to the current predicted `nextAt`（virtual tip, MUST NOT write into feeding history）; (2) **recollect** affinity-weighted interval samples using that tip as the time-of-day affinity anchor（MUST NOT reuse the interval computed solely against the true last occurrence）; (3) set `nextAt = tip + interval`. Appointment roots MUST NOT use this chase.

live 非预约：候选 nextAt 若过期超过 2 小时，MUST 最多 3 步以预测点为 tip **重算亲和**再推；MUST NOT 复用真 lastAt 间隔硬加；MUST NOT 写入历史；预约 MUST NOT 追赶。

#### Scenario: 过期超过 2h 追赶一步

- **WHEN** live 非预约预测得出 nextAt₀，且 now − nextAt₀ > 2h
- **AND** 以 nextAt₀ 为 tip 重采亲和样本 ≥ 2
- **THEN** 客户端 MUST 得到 nextAt₁ = nextAt₀ + interval'（interval' 相对 nextAt₀ 重算）
- **AND** MUST NOT 使用仅相对真 lastAt 算出的原 interval 作为该步加法

#### Scenario: 满 3 步仍过期则无预测

- **WHEN** 连续追赶 3 步后仍有 now − nextAt > 2h
- **THEN** 该根 live 预测 MUST 视为无 nextAt（不可预测）

#### Scenario: 重采亲和失败则无预测

- **WHEN** 追赶任一步以预测 tip 重采后亲和有效样本不足 2
- **THEN** 该根 live 预测 MUST 视为无 nextAt

#### Scenario: 展示 lastAt 仍为真发生

- **WHEN** 漏记追赶改写或清空了 nextAt
- **THEN** UI 展示的上一次发生时刻 MUST 仍来自真喂养记录 tip（或既有真 last 缓存规则）
- **AND** MUST NOT 把虚拟预测 tip 当作已记录的 lastAt

### Requirement: Missed-cycle chase SHALL retain rolled tips on the live prediction result

When live missed-cycle chase rewrites `nextAt`, the client MUST attach an ordered list of the virtual tips rolled through（each tip that was used as the additive/affinity base for a chase step before the final displayed `nextAt`）on the live prediction result（e.g. `missedTips`). The list MUST contain at most **3** instants, MUST NOT include the final displayed `nextAt`, and MUST NOT be written into feeding history. When chase does not run, or chase fails and yields no `nextAt`, the client MUST treat the tip list as empty / absent for display consumers. Expect-anchor-chain paths with chase disabled MUST NOT invent missed tips.

漏记追赶改写 nextAt 时，MUST 在 live 预测结果上保留有序滚过 tip（最多 3、不含终显 nextAt、不写历史）；未追赶或追赶失败无 nextAt 时 tip 列表对展示视为空；锚点链 MUST NOT 伪造 tip。

#### Scenario: 追赶一步保留原候选 tip

- **WHEN** live 追赶以 nextAt₀ 为 tip 成功得到终显 nextAt₁
- **THEN** 该预测结果的 tip 列表 MUST 含 nextAt₀
- **AND** MUST NOT 把 nextAt₁ 列入 tip 列表

#### Scenario: 多步保留全部滚过 tip

- **WHEN** live 追赶连续两步后得到终显 nextAt₂
- **THEN** tip 列表 MUST 按时间序含 nextAt₀ 与 nextAt₁
- **AND** MUST NOT 含 nextAt₂

#### Scenario: 未追赶无 tip

- **WHEN** 候选 nextAt 未满足 now − nextAt > 2h，未进入追赶
- **THEN** tip 列表 MUST 为空（或不存在）

### Requirement: Missed-cycle chase SHALL apply uniformly to live surfaces and NOT to expect-anchor chain

Smart prediction, next-3-hours timeline, and home-widget prediction MUST use the same live chase result for a given root. The history expect-anchor chain（`buildHistoryExpectAnchorPatches` / post-mutation expect-batch）MUST NOT enable missed-cycle chase when stamping expect* for existing rows（including after mid-list insert recalculation）.

智能预测、3h、Widget MUST 同 live 追赶结果；expect 锚点链（含中间插入重算）MUST NOT 启用漏记追赶。

#### Scenario: Widget 与页内一致

- **WHEN** 同一根在预测页 live 追赶后 nextAt 被改写
- **THEN** 桌面 Widget / 应用内 Widget 预览 MUST 使用同一追赶后的 nextAt（或同为无预测）

#### Scenario: 锚点链不追赶

- **WHEN** 静默管线为历史行计算 expect 补丁
- **THEN** 客户端 MUST NOT 对墙钟 now 做漏记 2h/3 步追赶
- **AND** MUST 仍以 prior 真发生序列为 tip 按既有锚点链打 expect（过期仍可打戳，按既有 fromPrediction 语义）

### Requirement: Absent live nextAt SHALL omit prediction chrome and expect stamps on live record

When live chase yields no `nextAt` for a root, the feeding-page next-prediction glass card MUST NOT be shown for that prompt, and live record/add paths MUST NOT attach `expectStartTime` / related expect* from that missing prediction（so accuracy is not polluted by a chased-or-abandoned forecast）. The 30-minute A/B/C prompt states MUST be evaluated only against a final displayed `nextAt` when one exists.

无 live nextAt 时喂养下一次卡 MUST NOT 展示；活记事 MUST NOT 打 expect*；A/B/C MUST 仅基于终显 nextAt。

#### Scenario: 无 nextAt 无下一次卡

- **WHEN** 某根 live 预测无 nextAt
- **THEN** 喂养页 MUST NOT 展示该根的下一次预测玻璃卡

#### Scenario: 无 nextAt 不打 expect

- **WHEN** 用户在无 live nextAt 上下文记录喂养
- **THEN** 请求 MUST NOT 携带由该缺失预测推导的 expectStartTime（等 expect*）
