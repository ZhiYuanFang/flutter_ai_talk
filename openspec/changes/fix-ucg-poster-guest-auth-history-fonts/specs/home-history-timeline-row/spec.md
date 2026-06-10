## ADDED Requirements

### Requirement: 历史行字号 MUST 随 fromBottom 强化衰减以突出时间层次

Timeline row body text SHALL decrease font size more strongly as `fromBottom` increases, with a lower minimum floor (approximately 9–10 logical pixels) while keeping row height at about 40px and single-line layout. 主页历史时间轴行正文 MUST 随 `fromBottom` 增大而更明显减小字号；最旧行字号下限 MUST 约为 9–10 逻辑像素；行高 MUST 保持约 40px 且主文案 MUST NOT 超过 1 行。

#### Scenario: 最新行与最旧行字号对比

- **WHEN** 历史列表同时展示 `fromBottom == 0` 与较大 `fromBottom` 的行
- **THEN** 最旧行正文 `fontSize` MUST 低于最新行且不低于约 9 逻辑像素
- **AND** 最旧行 MUST visibly 小于当前 11px 下限实现下的字号

#### Scenario: 行高保持约 40px

- **WHEN** 应用加强字号衰减后渲染任意标准历史行
- **THEN** `HomeHistoryTimelineTile.rowHeight` MUST 仍为约 40 逻辑像素
- **AND** 事件名、备注与尾注主文案 MUST NOT 换行溢出

#### Scenario: 尾注数字强调仍基于行内字号

- **WHEN** 较旧行展示计数尾注（如 `120ml`）或计时尾注
- **THEN** 数字 2× 加粗强调 MUST 仍相对于该行 `fontSize` 计算
- **AND** 强调样式 MUST 与 `home-history-timeline-typography` 计数/计时规则一致
