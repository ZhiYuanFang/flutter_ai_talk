## ADDED Requirements

### Requirement: Care-alert daily fetch MUST NOT run until Shanghai yesterday history exists

The client MUST NOT call the care-alert daily GET API unless the user is logged in, `deviceNo` is present, the prediction 7-day range is ready and not loading, and at least one real history record in that range has an occurrence instant whose calendar day in `Asia/Shanghai` equals yesterday (relative to the current Shanghai calendar day). When the gate is false, `ensureLoaded` MUST skip HTTP and reset or leave care-alert state empty without marking a failed fetch. The same yesterday gate MUST be used for widget tip derivation eligibility.

客户端 **不得** 调用留意日 GET，除非已登录、有 `deviceNo`、7 日 range 已就绪且非 loading，且 range 内至少一条真历史的 `occurrenceInstant` 在 `Asia/Shanghai` 日历日等于当前上海日的昨日。门闸为 false 时 `ensureLoaded` **必须** 跳过 HTTP 且 **不得** 标记失败拉取。小组件 tip 派生 **必须** 共用同一昨日门闸。

#### Scenario: 仅今日有记录不拉取

- **WHEN** 7 日 range 仅含今日（上海日）发生记录且无昨日记录
- **THEN** 客户端 MUST NOT 发起 care-alert daily GET
- **AND** 小组件 tip 派生 MUST NOT 假装有留意数据

#### Scenario: 有昨日记录可拉取

- **WHEN** range 就绪且至少一条记录落在上海昨日
- **AND** 用户进入智能预测页且其他条件满足
- **THEN** 客户端 MUST 允许 ensureLoaded 发起 daily GET（受 single-flight 与同日幂等约束）

#### Scenario: 昨日记录出现后补拉

- **WHEN** 用户本已在预测页且 gate 从 false 变为 true（例如跨日后或历史同步补全昨日）
- **THEN** 客户端 MUST 触发 `_ensureCareAlertOnPredictionVisible` 等价补拉
- **AND** MUST NOT 要求用户离开再进入预测页
