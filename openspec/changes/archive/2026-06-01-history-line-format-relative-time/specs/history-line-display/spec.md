## ADDED Requirements

### Requirement: 历史单行文案分支（eventNumber 与 endTime）

The client SHALL 按 `eventNumber` 与「结束时间是否为零」选择展示模板，且所有时间片段 MUST 先经「相对时间展示」规则格式化后再拼入文案。字段缺失、`null`、空字符串或解析为 Unix 秒 `0` 的结束时间 MUST 视为「`endTime` 为 0」。

#### Scenario: eventNumber 为 1 且带备注

- **WHEN** `eventNumber == 1` 且 `remark` 去空白后非空  
- **THEN** 主文案 MUST 为 `{格式化(endTime)}:{eventName}({remark})`（括号与备注字面输出）

#### Scenario: eventNumber 为 1 且无备注

- **WHEN** `eventNumber == 1` 且 `remark` 为空  
- **THEN** 主文案 MUST 为 `{格式化(endTime)}:{eventName}`（不得输出空括号）

#### Scenario: eventNumber 大于 1

- **WHEN** `eventNumber > 1`  
- **THEN** 主文案 MUST 为 `{格式化(endTime)}:{eventName}->{eventNumber}`（`->` 为字面）

#### Scenario: eventNumber 为 0 且未结束（开始计时）

- **WHEN** `eventNumber == 0` 且 `endTime` 按上条视为 0  
- **THEN** 主文案 MUST 为 `{格式化(startTime)}:{eventName} -> 开始计时`（`->` 为字面）

#### Scenario: eventNumber 为 0 且已结束（展示用时）

- **WHEN** `eventNumber == 0` 且 `endTime` 大于 0（已设置结束时间）  
- **THEN** 主文案 MUST 包含 `{格式化(endTime)}`、`{eventName}`、「`-> 用时`」字面及用时文案；用时为 `endTime` 与 `startTime` 的时间差。若用时 **满 1 小时**，MUST 以「小时 + 分钟」形式展示（例如「1小时3分钟」）；若 **不满 1 小时且至少 1 整分钟**，MUST **仅展示分钟**（例如「5分钟」）；若 **不足 1 分钟（含 0 分钟）**，用时文案 MUST 为「不足 1 分钟」。字面顺序 MUST 为「`{格式化(endTime)}:{eventName}-> 用时{用时文案}`」。

### Requirement: 相对时间展示（今日 / 昨天 / 今年 / 其它）

The client SHALL 以设备本地时区与本地自然日为锚，将某一绝对时间格式化为列表用短串：今日仅 **时:分**；昨日为 **昨天时:分**；今年内既非今日也非昨日为 **月日 时:分**；其它年为 **年月日 时:分**（月日年具体分隔符在实现中固定并与设计一致）。

#### Scenario: 今日记录

- **WHEN** 该时间落在与「当前时间」同一本地日历日  
- **THEN** 格式化结果 MUST 仅含当日 **时:分**（前导零策略在实现中固定）

#### Scenario: 昨日记录

- **WHEN** 该时间为本地日历的「昨天」  
- **THEN** 格式化结果 MUST 以 **昨天** 前缀加 **时:分**

#### Scenario: 今年非今昨

- **WHEN** 该时间与当前时间处于同一公历年且非今日、非昨日  
- **THEN** 格式化结果 MUST 含 **月与日** 及 **时:分**

#### Scenario: 其它年份

- **WHEN** 该时间与当前时间不在同一公历年  
- **THEN** 格式化结果 MUST 含 **年、月、日** 及 **时:分**

### Requirement: 事件名与备注的排版层级

The client SHALL 在历史列表（及复用同一组件的同类入口）中，对 `eventName` 使用相对正文 **更大字号且字重加粗**；对 `remark` 使用相对 **更小字号**；同一条内其它字面（时间、箭头、次数、用时等）使用默认正文样式，除非规格另有说明。

#### Scenario: 含备注的单次事件行

- **WHEN** 渲染 `eventNumber == 1` 且 `remark` 非空的行  
- **THEN** `eventName` MUST 比同条内默认文本更粗更大；`remark` MUST 比 `eventName` 更小且不加粗于 `eventName` 之上

#### Scenario: 无备注行

- **WHEN** 任意分支不产生 `remark` 片段  
- **THEN** 不得渲染空白备注占位；`eventName` 仍 MUST 满足加粗加大规则
