## REMOVED Requirements

### Requirement: 今日汇总展示

**Reason**: 产品移除喂养主页「今日总结」模块，历史列表之上不再展示按事件聚合的今日 chip。  
**Migration**: 从 `HomeScreen` 卸下 `HomeTodaySummaryPanel`；趋势查看改走趋势中心等其它入口。

#### Scenario: （归档占位）主页不再强制今日汇总

- **WHEN** 用户打开喂养主页且当日有多类事件记录
- **THEN** 主页 MUST NOT 再因本已移除需求而要求展示今日汇总 chip 区
