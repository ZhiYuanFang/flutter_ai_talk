## ADDED Requirements

### Requirement: Imminent compact Dynamic Island SHALL show a three-character event name beside the logo

When the system presents an Imminent Live Activity in Dynamic Island **compact**, `compactLeading` MUST show the event logo and, when an event name is available, at most the first **3** Swift `Character`s of that name with no ellipsis. The name MUST be taken from Imminent `title` (ContentState if non-empty, otherwise Attributes)—this is the event-name field for Imminent (there is no `eventName` attribute). The compact leading copy MUST NOT be derived from lock-screen template fallbacks such as「即将发生」or「事件即将发生」. If `title` is empty after trim, `compactLeading` MUST show only the logo. This requirement MUST NOT place the untruncated full title in compact, MUST NOT change `compactTrailing` capsule width behavior, and MUST NOT change lock-screen or expanded full-title presentation.

当系统以 Dynamic Island **compact** 展示 Imminent Live Activity 时，`compactLeading` MUST 展示事件 logo；有事件名时 MUST 在 logo 右侧展示该名的最多前 **3** 个 Character，不得加省略号。名字 MUST 来自 Imminent 的 `title`（ContentState 非空优先，否则 Attributes）；Imminent 无 `eventName` 字段，`title` 即事件名。MUST NOT 从锁屏模板回退「即将发生 / 事件即将发生」再截三字。trim 后 `title` 为空时，`compactLeading` MUST 仅展示 logo。MUST NOT 把未截断全名放入 compact；MUST NOT 改变 `compactTrailing` 胶囊宽度行为；MUST NOT 改变锁屏或 expanded 的全标题展示。

#### Scenario: Compact leading shows up to three characters from title

- **WHEN** 系统以 compact Dynamic Island 展示一条 Imminent Live Activity 且 `title` 为「母乳亲喂」
- **THEN** compactLeading MUST 同时展示事件 logo 与文案「母乳亲」
- **AND** MUST NOT 展示第四字「喂」
- **AND** MUST NOT 加省略号

#### Scenario: Empty title keeps logo only

- **WHEN** compact 展示 Imminent 且 ContentState 与 Attributes 的 `title` 均为空
- **THEN** compactLeading MUST 仅展示事件 logo（或既有兜底图）
- **AND** MUST NOT 展示「即将发生」的前三字
