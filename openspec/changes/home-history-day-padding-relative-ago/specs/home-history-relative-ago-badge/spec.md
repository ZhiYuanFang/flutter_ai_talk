## MODIFIED Requirements

### Requirement: 各事件最新记录下方相对时间标签

The client SHALL display a relative-time badge immediately below each history row that is the **newest occurrence of its event** within the **currently loaded home history list**, showing how long ago that row's display instant occurred using **tiered Chinese copy** (刚刚 / 分前 / 时+分前). 对列表中**每一种不同事件**（按事件键区分），**展示时刻最新**且**非进行中计时**的一条记录 MUST 在其行下方显示该标签；同一事件的其他记录 MUST NOT 显示。**进行中计时**记录 MUST NOT 显示该标签。同屏 MAY 同时显示多条标签。

相对时间**文案体**（不含 UI 外层 `[` `]`）MUST 按与当前时刻的差值分档：

- 差值 **不足 1 分钟**：MUST 为 **「刚刚」**
- 差值 **≥1 分钟**且 **不足 1 小时**（0 小时）：MUST 为 **「{m}分前」**，MUST NOT 包含「0时」
- 差值 **≥1 小时**：MUST 为 **「{h}时{m}分前」**

#### Scenario: 某事件在列表内最新一条展示标签

- **WHEN** 主页历史列表包含某事件键的至少一条记录，且记录 A 为该键展示时刻最新且 `!isActiveTimingRecord(A)`
- **THEN** 记录 A 行下方 MUST 显示相对时间标签，文案体符合上述分档规则

#### Scenario: 不足一分钟显示刚刚

- **WHEN** 某带标签记录的展示时刻与当前时刻相差小于 60 秒
- **THEN** 标签文案体 MUST 为「刚刚」（UI 可展示为 `[刚刚]`）

#### Scenario: 不足一小时不显示零小时 re

- **WHEN** 展示时刻与当前相差至少 60 秒且不足 3600 秒
- **THEN** 标签文案体 MUST 为「{m}分前」形式，MUST NOT 为「0时{m}分前」

#### Scenario: 满一小时显示时分

- **WHEN** 展示时刻与当前相差至少 1 小时
- **THEN** 标签文案体 MUST 为「{h}时{m}分前」（例如 `2时15分前`）

#### Scenario: 同事件较早记录无标签

- **WHEN** 某事件键在列表中存在多条记录，且记录 B 的展示时刻早于该键最新记录
- **THEN** 记录 B 行下方 MUST NOT 显示相对时间标签

#### Scenario: 进行中计时不展示标签

- **WHEN** 某条记录满足 `isActiveTimingRecord` 且为该事件键在列表内最新一条
- **THEN** 该行下方 MUST NOT 显示相对时间标签

#### Scenario: 进行中计时不回退到较早记录

- **WHEN** 某事件键最新一条为进行中计时，且存在同键更早已结束记录
- **THEN** 该事件键 MUST NOT 在任何行下方显示相对时间标签

### Requirement: 相对时间标签主题样式

The client MUST style the relative-time badge using theme-aware foreground and background colors: background opacity **0.2**, font size **slightly smaller** than the event name on the same row. 背景色与文字色 MUST 随应用主题变化；背景不透明度 MUST 为 **0.2**；字号 MUST 小于同行事件名字号。

#### Scenario: 浅色与深色主题

- **WHEN** 用户切换 shell 明暗主题
- **THEN** 标签背景与文字 MUST 仍可读，且继续使用主题语义色而非写死 hex

### Requirement: 相对时间定期刷新

The client SHALL refresh every visible relative-time badge at least once per minute while those rows are shown, so tiered copy stays approximately correct. 所有带标签的行 MUST 至少每分钟随当前时间更新文案。

#### Scenario: 超过一分钟

- **WHEN** 用户停留在主页且某条带标签记录的展示时刻不变
- **THEN** 至少在一分钟后该标签文案 MUST 更新以反映新的时间差（例如由「刚刚」变为「1分前」）
