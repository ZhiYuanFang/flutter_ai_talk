## REMOVED Requirements

### Requirement: Imminent compact Dynamic Island SHALL show a three-character event name beside the logo

**Reason**: 产品要求 compact 展示完整事件名，废止最多三字硬截。  
**Migration**: 改用 ADDED「Imminent compact Dynamic Island SHALL show the full event name beside the logo」。

## ADDED Requirements

### Requirement: Imminent compact Dynamic Island SHALL show the full event name beside the logo

When the system presents an Imminent Live Activity in Dynamic Island **compact**, `compactLeading` MUST show the event logo and, when an event name is available, the full trimmed name with no product-side Character-count truncation and no ellipsis inserted by the client. The name MUST be taken from Imminent `title` (ContentState if non-empty, otherwise Attributes). The compact leading copy MUST NOT be derived from lock-screen template fallbacks such as「即将发生」or「事件即将发生」. If `title` is empty after trim, `compactLeading` MUST show only the logo. Compact leading MAY use a single-line layout constraint (`lineLimit(1)` or equivalent) without truncating the string to a fixed Character count. This requirement MUST NOT change Imminent compact trailing’s no-time-slot behavior from `live-activity-imminent-no-time`, and MUST NOT change lock-screen title presentation.

当系统以 Dynamic Island **compact** 展示 Imminent Live Activity 时，`compactLeading` MUST 展示事件 logo；有事件名时 MUST 在 logo 右侧展示 **完整** trim 后名称，客户端 MUST NOT 再按固定 Character 数硬截，MUST NOT 自行加省略号。名字 MUST 来自 Imminent 的 `title`（ContentState 非空优先，否则 Attributes）。MUST NOT 从锁屏模板「即将发生 / 事件即将发生」取 compact 名。trim 后为空时 MUST 仅展示 logo。MAY 使用单行布局（如 `lineLimit(1)`），但 MUST NOT 等价于字数截断。MUST NOT 改变 Imminent compact 无时间右槽行为；MUST NOT 改变锁屏标题。

#### Scenario: Compact leading shows full title

- **WHEN** 系统以 compact Dynamic Island 展示一条 Imminent Live Activity 且 `title` 为「母乳亲喂」
- **THEN** compactLeading MUST 同时展示事件 logo 与完整文案「母乳亲喂」
- **AND** MUST NOT 仅展示前三字「母乳亲」

#### Scenario: Empty title keeps logo only

- **WHEN** compact 展示 Imminent 且 ContentState 与 Attributes 的 `title` 均为空
- **THEN** compactLeading MUST 仅展示事件 logo（或既有兜底图）
- **AND** MUST NOT 展示「即将发生」

### Requirement: Imminent expanded Dynamic Island center title SHALL not use a product line-limit cap

When the system presents an Imminent Live Activity in Dynamic Island **expanded**, the center title MUST use the same `lockTitle` (or equivalent) semantics as today, and MUST NOT apply a product-imposed SwiftUI `lineLimit(1)` or `lineLimit(2)` (or equivalent low fixed line cap) that artificially shortens the title. The system layout MAY still wrap or clip according to ActivityKit chrome. Status empty fallback such as「即将发生」MAY remain.

当系统以 Dynamic Island **expanded** 展示 Imminent Live Activity 时，中心标题 MUST 沿用既有 `lockTitle`（或等价）语义，MUST NOT 再施加产品侧 `lineLimit(1)` / `lineLimit(2)`（或等价低固定行数上限）人为缩短标题。系统布局 MAY 仍按 ActivityKit 区域换行或裁切。空名兜底「即将发生」MAY 保留。

#### Scenario: Expanded center has no low lineLimit

- **WHEN** Imminent expanded 中心渲染非空长标题
- **THEN** UI MUST NOT 因产品代码中的 `lineLimit(1)` 或 `lineLimit(2)` 强制压成最多一两行的人为上限
- **AND** 空回退 MAY 仍为「即将发生」
