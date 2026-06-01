# trends-selected-event-memory 规格增量

## ADDED Requirements

### Requirement: 趋势中心必须记忆并恢复上次事件选择
The system MUST persist the last selected valid trend leaf event and restore it on next visit.

趋势中心在用户切换事件并确认后，必须持久化该事件 ID。用户下次进入趋势中心时，系统必须优先恢复该记忆事件（前提是该事件在当前目录中仍为合法叶子事件）。

#### Scenario: 切换事件后写入记忆

- **WHEN** 用户在趋势中心选择器中将事件从 A 切换为 B 且 B 为合法叶子
- **THEN** 系统必须将 B 的事件 ID 写入本地持久化存储

#### Scenario: 再次进入优先恢复

- **WHEN** 用户此前已记忆事件 B，且再次进入趋势中心时 B 仍在当前合法叶子集合中
- **THEN** 系统必须默认选中 B，并基于 B 加载趋势序列

#### Scenario: 记忆失效自动回退

- **WHEN** 本地记忆事件缺失、不可解析，或对应事件已不在当前合法叶子集合中
- **THEN** 系统必须回退到目录顺序中的第一个合法叶子事件，并正常加载趋势序列
