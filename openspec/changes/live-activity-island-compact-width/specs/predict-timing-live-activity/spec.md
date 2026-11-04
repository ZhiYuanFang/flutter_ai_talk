## ADDED Requirements

### Requirement: Timing compact Dynamic Island SHALL stay capsule-width

When the system presents a Timing Live Activity in Dynamic Island **compact**, the compact trailing slot MUST report a short intrinsic width suitable for a capsule (equivalent to a hidden `"00:00:00"` placeholder). The elapsed `timerInterval` MUST render inside that slot and MUST NOT be allowed to set the island's intrinsic width via unbounded measurement. The compact island MUST remain a capsule around the hardware cutout and MUST NOT stretch to approximately full screen width. The compact (and any shared elapsed-text helper used there) MUST NOT use `Date.distantFuture` as the `timerInterval` upper bound; the range MUST be capped (approximately 99 hours from `startTime`). This requirement MUST NOT change the lock-screen full-width banner layout (leading logo, title, trailing large-type elapsed time) or the expanded island chrome.

当系统以 Dynamic Island **compact** 展示 Timing Live Activity 时，compact trailing MUST 以短占位（隐藏 `"00:00:00"`）向岛报告固有宽度。已计时 MUST 画在该槽内，MUST NOT 让无界 `timerInterval` 测量决定岛宽。compact 岛 MUST 保持切口两侧胶囊，MUST NOT 被拉到接近满屏宽。compact（及该处共用的已计时 helper）MUST NOT 将 `timerInterval` 上界设为 `Date.distantFuture`，区间 MUST 有上限（约自 `startTime` 起 99 小时）。本需求 MUST NOT 改变锁屏满宽横条（左图、标题、右侧大字已计时）或 expanded 岛形态。

#### Scenario: Compact island stays capsule while elapsed time ticks

- **WHEN** 系统以 compact Dynamic Island 展示一条 Timing Live Activity 且 `startTime` 为有效 unix 秒
- **THEN** compact 岛 MUST 保持胶囊（切口 + 两侧短内容）
- **AND** MUST NOT 被拉到接近满屏宽
- **AND** compact trailing MUST 仍显示自 `startTime` 起的已计时

#### Scenario: Timing interval is not distantFuture

- **WHEN** compact trailing 使用系统 `timerInterval` 展示 Timing 已计时
- **THEN** 区间上界 MUST NOT 为 `Date.distantFuture`
- **AND** 区间 MUST 为自 `startTime` 起的有限时长（约 99 小时量级）
