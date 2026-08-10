## REMOVED Requirements

### Requirement: 今日事件 chip 可打开趋势 Sheet

**Reason**: 主页今日总结 chip 已移除，不再提供从 chip 打开今昨小时趋势 Sheet 的入口。  
**Migration**: 删除主页 chip → `showHomeEventHourlyTrendSheet` 接线；Sheet 实现可保留供其它入口复用（若无则随死代码清理）。

#### Scenario: （归档占位）无 chip 入口

- **WHEN** 用户在喂养主页浏览历史列表上方区域
- **THEN** 客户端 MUST NOT 展示可打开今昨小时趋势 Sheet 的今日事件 chip
