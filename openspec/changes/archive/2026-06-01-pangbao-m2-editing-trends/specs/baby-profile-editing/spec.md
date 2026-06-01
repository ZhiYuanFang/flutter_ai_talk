## ADDED Requirements

### Requirement: 设置中可编辑宝宝资料

The system SHALL allow the user to edit linked baby profile fields (nickname, sex, birth date, and other fields returned by the repository) from the settings experience and SHALL persist changes through the settings repository (mock or API).

#### Scenario: 用户修改昵称并保存

- **WHEN** 用户在设置中心修改宝宝昵称并确认保存
- **THEN** 系统必须将新昵称写回仓库并在返回列表或主页时展示更新后的摘要

#### Scenario: 修改性别影响默认主题

- **WHEN** 用户修改宝宝性别并保存且用户未设置自定义背景覆盖逻辑
- **THEN** 系统必须按新性别应用默认主题色规则（与既有性别主题需求一致）

### Requirement: 表单校验与取消

The system SHALL perform basic validation (非空昵称、合法日期等) before save and SHALL allow canceling edits without persisting.

#### Scenario: 非法日期被拒绝

- **WHEN** 用户输入无法解析为日期的生日字段并尝试保存
- **THEN** 系统必须阻止保存并提示错误原因
