## REMOVED Requirements

### Requirement: Timing compact Dynamic Island SHALL show a three-character event name from eventName

**Reason**: 产品要求 compact 展示完整事件名，废止最多三字硬截。  
**Migration**: 改用 ADDED「Timing compact Dynamic Island SHALL show the full event name from eventName」。

## ADDED Requirements

### Requirement: Timing compact Dynamic Island SHALL show the full event name from eventName

When the system presents a Timing Live Activity in Dynamic Island **compact**, `compactLeading` MUST show the event logo and, when an event name is available, the full trimmed `eventName` with no product-side Character-count truncation and no ellipsis inserted by the client. The name MUST be taken from `eventName` (ContentState if non-empty, otherwise Attributes). The compact leading copy MUST NOT be derived from lock-screen template fallbacks such as「事件计时中」or the suffix「计时中」. If `eventName` is empty after trim, `compactLeading` MUST show only the logo. Compact leading MAY use a single-line layout constraint (`lineLimit(1)` or equivalent) without truncating the string to a fixed Character count. This requirement MUST NOT remove or replace Timing `compactTrailing`’s existing short timer placeholder (`CompactIslandTimeSlot` / `"00:00:00"` behavior), and MUST NOT change lock-screen title presentation.

当系统以 Dynamic Island **compact** 展示 Timing Live Activity 时，`compactLeading` MUST 展示事件 logo；有事件名时 MUST 在 logo 右侧展示 **完整** trim 后的 `eventName`，客户端 MUST NOT 再按固定 Character 数硬截，MUST NOT 自行加省略号。名字 MUST 来自 `eventName`（ContentState 非空优先，否则 Attributes）。MUST NOT 从锁屏模板「事件计时中」或后缀「计时中」取 compact 名。trim 后为空时 MUST 仅展示 logo。MAY 使用单行布局（如 `lineLimit(1)`），但 MUST NOT 等价于字数截断。MUST NOT 取消 Timing `compactTrailing` 既有短 timer 占位；MUST NOT 改变锁屏标题。

#### Scenario: Compact leading shows full eventName

- **WHEN** 系统以 compact Dynamic Island 展示一条 Timing Live Activity 且 `eventName` 为「母乳亲喂」
- **THEN** compactLeading MUST 同时展示事件 logo 与完整文案「母乳亲喂」
- **AND** MUST NOT 仅展示前三字「母乳亲」

#### Scenario: Empty eventName keeps logo only

- **WHEN** compact 展示 Timing 且 ContentState 与 Attributes 的 `eventName` 均为空
- **THEN** compactLeading MUST 仅展示事件 logo（或既有兜底图）
- **AND** MUST NOT 展示「事件」或「计时中」

#### Scenario: Timing trailing timer slot unchanged

- **WHEN** Timing compact 展示已计时
- **THEN** compactTrailing MUST 仍使用既有短占位槽行为（如隐藏 `"00:00:00"`）
- **AND** MUST NOT 因全名 leading 而取消该占位策略

### Requirement: Timing expanded Dynamic Island center title SHALL not use a product line-limit cap

When the system presents a Timing Live Activity in Dynamic Island **expanded**, the center title MUST use existing `timingIslandTitle` (or equivalent) semantics, and MUST NOT apply a product-imposed SwiftUI `lineLimit(1)` (or equivalent low fixed line cap) that artificially shortens the title. The system layout MAY still wrap or clip according to ActivityKit chrome.

当系统以 Dynamic Island **expanded** 展示 Timing Live Activity 时，中心标题 MUST 沿用既有 `timingIslandTitle`（或等价）语义，MUST NOT 再施加产品侧 `lineLimit(1)`（或等价低固定行数上限）人为缩短标题。系统布局 MAY 仍按 ActivityKit 区域换行或裁切。

#### Scenario: Expanded center has no low lineLimit

- **WHEN** Timing expanded 中心渲染非空长事件名
- **THEN** UI MUST NOT 因产品代码中的 `lineLimit(1)`（或等价低上限）强制压行
