## ADDED Requirements

### Requirement: Next-3-hours card content SHALL lay out logo and copy vertically centered

When the「接下来3小时」card is shown, the client MUST place the tier logo on the leading (left) side and the title row plus body copy in a trailing column. The logo and the text column MUST be vertically centered with respect to each other. Existing behaviors（full body text, no AI分析, whole-card opens Free/Pro wall when not syncing, free-tier `Icons.upgrade` beside suffix）MUST remain.

3h 卡 MUST 左 logo、右标题+正文，图文纵向居中；既有开墙/upgrade/无 AI分析 MUST 保持。

#### Scenario: 图文纵向居中

- **WHEN** 已绑定用户看到「接下来3小时」卡（含有正文）
- **THEN** 左侧档位 logo 与右侧文案列 MUST 垂直居中对齐
- **AND** 标题行仍 MUST 含「接下来3小时」与档位后缀（免费时可含 upgrade 图标）
