## MODIFIED Requirements

### Requirement: Female classic primary color SHALL be rose red

When `BabySex.female` and classic light theme applies, `sexPrimary` MUST resolve to green `#2CB771` (`0xFF2CB771`). 女性宝宝经典浅色主题的主色 MUST 为 `#2CB771`（不再使用玫瑰红 `#E91E63`）。

#### Scenario: 女宝经典主题

- **WHEN** 用户基线为经典且宝宝性别为女且未使用覆盖性别默认的自定义 seed
- **THEN** 主题 primary 与经典 shell tint SHALL 基于 `#2CB771` seed 推导
