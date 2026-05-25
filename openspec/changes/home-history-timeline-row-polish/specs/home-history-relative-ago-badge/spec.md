## ADDED Requirements

### Requirement: 各事件最新记录下方相对时间标签

The client SHALL display a relative-time badge immediately below each history row that is the **newest occurrence of its event** within the **currently loaded home history list**, showing how long ago that row's display instant occurred, in the form **「{h}时{m}分前」**. 对列表中**每一种不同事件**（按事件键区分，见 `home-history-compact-timeline` 与实现中的 `historyRecordEventId` / 事件名回退），**展示时刻最新**且**非进行中计时**的一条记录 MUST 在其行下方显示该标签；同一事件的其他记录 MUST NOT 显示。**进行中计时**记录（`isActiveTimingRecord`：`eventNumber == 0` 且 `endTime` 未设置）MUST NOT 显示该标签，即使其为该事件在列表内的最新一条。同屏 MAY 同时显示**多条**标签（每种至少有一条符合展示条件的记录各一条）。

#### Scenario: 某事件在列表内最新一条展示标签

- **WHEN** 主页历史列表包含某事件键的至少一条记录，且其中记录 A 的 `historyHomeDisplayInstant` 不早于同键任何其他记录，且 A **非**进行中计时（`!isActiveTimingRecord(A)`）
- **THEN** 记录 A 所在行下方 MUST 显示相对时间标签，文案格式为「数字时+数字分+前」（例如 `2时15分前`）

#### Scenario: 同事件较早记录无标签

- **WHEN** 某事件键在列表中存在多条记录，且记录 B 的展示时刻早于该键在列表内的最新记录
- **THEN** 记录 B 所在行下方 MUST NOT 显示相对时间标签

#### Scenario: 多种事件各有一条标签

- **WHEN** 列表同时包含事件键 X 与事件键 Y 的记录，且各自在列表内均有唯一最新展示时刻记录
- **THEN** X 的最新行与 Y 的最新行下方 MUST 各显示一条相对时间标签（共两条），且 MUST NOT 仅因全局 `fromBottom == 0` 而只显示其中一条

#### Scenario: 展示时刻相同时保留列表中更靠底部的一条

- **WHEN** 同一事件键两条记录的 `historyHomeDisplayInstant` 相等
- **THEN** MUST 仅在与列表底部更近（更新）的那条行下方显示标签

#### Scenario: 进行中计时不展示标签

- **WHEN** 某条记录满足 `isActiveTimingRecord`（`eventNumber == 0` 且 `endTime` 未设置），且该条为该事件键在列表内展示时刻最新的一条
- **THEN** 该行下方 MUST NOT 显示相对时间标签

#### Scenario: 进行中计时不回退到较早记录

- **WHEN** 某事件键在列表内最新一条为进行中计时，且存在同键更早的已结束记录
- **THEN** 该事件键 MUST NOT 在任何行下方显示相对时间标签（MUST NOT 将 badge 展示于较早记录）

### Requirement: 相对时间标签主题样式

The client MUST style the relative-time badge using theme-aware foreground and background colors: background opacity **0.2**, font size **slightly smaller** than the event name on the same row. 背景色与文字色 MUST 随应用主题（如 `AppVisualTokens.onShell` 或 `ColorScheme`）变化；背景不透明度 MUST 为 **0.2**；字号 MUST 小于同行事件名字号。

#### Scenario: 浅色与深色主题

- **WHEN** 用户切换 shell 明暗主题
- **THEN** 标签背景与文字 MUST 仍可读，且继续使用主题语义色而非写死 hex

### Requirement: 相对时间定期刷新

The client SHALL refresh every visible relative-time badge at least once per minute while those rows are shown, so the「分前」文案 stays approximately correct. 所有带标签的行 MUST 至少每分钟随当前时间更新文案（可与进行中计时 tick 共用调度）。

#### Scenario: 超过一分钟

- **WHEN** 用户停留在主页且某条带标签记录的展示时刻不变
- **THEN** 至少在一分钟后该标签文案 MUST 更新以反映新的时间差
