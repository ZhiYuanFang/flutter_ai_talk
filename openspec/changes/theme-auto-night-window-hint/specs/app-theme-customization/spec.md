## ADDED Requirements

### Requirement: Auto night sky toggle MUST show schedule window caption

In the shared theme palette sheet, directly beneath the「自动夜空」label and adjacent to its Switch, the UI MUST always show a secondary caption whose text is exactly `19:00–05:00`. The caption MUST remain visible whether `theme_schedule_enabled` is `true` or `false`. The caption MUST NOT imply that the window is user-editable. 公用主题调色 Sheet 中，「自动夜空」标签正下方、与 Switch 同一控件组内，MUST 始终展示次级文案，文本精确为 `19:00–05:00`；无论自动夜空开或关均可见；不得暗示时段可编辑。

#### Scenario: 打开 Sheet 可见时段

- **WHEN** 用户打开公用主题调色 Sheet
- **THEN** 「自动夜空」标签下方 SHALL 显示文案 `19:00–05:00`

#### Scenario: 关闭自动夜空仍显示时段

- **WHEN** `theme_schedule_enabled=false` 且用户打开公用主题调色 Sheet
- **THEN** 时段文案 `19:00–05:00` SHALL 仍可见

#### Scenario: 开启自动夜空仍显示时段

- **WHEN** `theme_schedule_enabled=true` 且用户打开公用主题调色 Sheet
- **THEN** 时段文案 `19:00–05:00` SHALL 仍可见
