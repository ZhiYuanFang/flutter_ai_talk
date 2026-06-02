## MODIFIED Requirements

### Requirement: 相对时间标签主题样式

The client MUST style the relative-time badge with **theme primary** background and **same-row event accent** text. 背景色 MUST 为 `ColorScheme.primary`，不透明度 **0.3**；文字色 MUST 为该行 `resolveEventColor`（无品牌色时回退 primary）向红色方向偏移后的衍生色；字号 MUST 小于同行事件名字号。标签 MUST NOT 再使用 `AppVisualTokens.onShell` 作为背景或文字的主色源。

#### Scenario: 背景随主题 primary

- **WHEN** 某行下方展示相对时间标签
- **THEN** 标签背景 MUST 为 `ColorScheme.primary` alpha **0.3**，且 MUST NOT 使用 event accent 作为背景色

#### Scenario: 文字随事件 accent

- **WHEN** 某行下方展示相对时间标签，且该行关联事件具有有效品牌色
- **THEN** 标签文字 MUST 为该品牌色偏红衍生色，且 MUST NOT 使用 shell 前景中性色作为主色

#### Scenario: 无品牌色时文字回退 primary

- **WHEN** 展示标签的行关联事件无有效 `parsedColor`
- **THEN** 文字衍生 MUST 基于 `ColorScheme.primary` 偏红；背景仍 MUST 为主题 primary alpha 0.3

#### Scenario: 切换主题后背景随主题

- **WHEN** 用户切换 shell 主题
- **THEN** 标签背景 MUST 随新主题的 `ColorScheme.primary` 更新

#### Scenario: 字号与布局不变

- **WHEN** 仅更新标签配色
- **THEN** 标签字号 MUST 仍小于同行事件名，圆角、内边距与行下槽位高度 MUST 与变更前一致
