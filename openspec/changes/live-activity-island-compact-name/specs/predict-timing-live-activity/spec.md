## ADDED Requirements

### Requirement: Timing compact Dynamic Island SHALL show a three-character event name from eventName

When the system presents a Timing Live Activity in Dynamic Island **compact**, `compactLeading` MUST show the event logo and, when an event name is available, at most the first **3** Swift `Character`s of `eventName` with no ellipsis. The name MUST be taken from `eventName` (ContentState if non-empty, otherwise Attributes). The compact leading copy MUST NOT be derived from lock-screen template fallbacks such as「事件计时中」or the suffix「计时中」. If `eventName` is empty after trim, `compactLeading` MUST show only the logo. This requirement MUST NOT place the untruncated full name in compact, MUST NOT change `compactTrailing` capsule width behavior, and MUST NOT change lock-screen or expanded full-name presentation.

当系统以 Dynamic Island **compact** 展示 Timing Live Activity 时，`compactLeading` MUST 展示事件 logo；有事件名时 MUST 在 logo 右侧展示 `eventName` 的最多前 **3** 个 Character，不得加省略号。名字 MUST 来自 `eventName`（ContentState 非空优先，否则 Attributes）。MUST NOT 从锁屏模板「事件计时中」或后缀「计时中」再截三字。trim 后 `eventName` 为空时，`compactLeading` MUST 仅展示 logo。MUST NOT 把未截断全名放入 compact；MUST NOT 改变 `compactTrailing` 胶囊宽度行为；MUST NOT 改变锁屏或 expanded 的全名展示。

#### Scenario: Compact leading shows up to three characters from eventName

- **WHEN** 系统以 compact Dynamic Island 展示一条 Timing Live Activity 且 `eventName` 为「母乳亲喂」
- **THEN** compactLeading MUST 同时展示事件 logo 与文案「母乳亲」
- **AND** MUST NOT 展示第四字「喂」
- **AND** MUST NOT 加省略号

#### Scenario: Empty eventName keeps logo only

- **WHEN** compact 展示 Timing 且 ContentState 与 Attributes 的 `eventName` 均为空
- **THEN** compactLeading MUST 仅展示事件 logo（或既有兜底图）
- **AND** MUST NOT 展示「事件」或「计时中」的前三字
