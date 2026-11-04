## ADDED Requirements

### Requirement: Imminent compact Dynamic Island SHALL stay capsule-width

When the system presents an Imminent Live Activity in Dynamic Island **compact** (not expanded, not lock-screen banner), the compact trailing slot MUST report a short intrinsic width suitable for a capsule (equivalent to a hidden `"00:00:00"` placeholder, or the wider of that placeholder and the overdue copy「已过时」). The live countdown MUST render inside that slot and MUST NOT be allowed to set the island's intrinsic width via unbounded `Text(timerInterval:)` measurement. The compact island MUST remain a capsule around the hardware cutout and MUST NOT stretch to approximately full screen width. When current time is at or after `nextAt`, compact trailing MUST show「已过时」as ordinary short text and MUST NOT use `timerInterval` for that copy. This requirement MUST NOT change the lock-screen full-width banner or the expanded island chrome.

当系统以 Dynamic Island **compact**（非 expanded、非锁屏横条）展示 Imminent Live Activity 时，compact trailing MUST 以短占位向岛报告固有宽度（隐藏 `"00:00:00"`，或该占位与「已过时」中较宽者）。倒计时 MUST 画在该槽内，MUST NOT 让无界 `Text(timerInterval:)` 决定岛宽。compact 岛 MUST 保持切口两侧胶囊，MUST NOT 被拉到接近满屏宽。当前时间 ≥ `nextAt` 时，compact trailing MUST 以普通短文案显示「已过时」，MUST NOT 对该文案使用 `timerInterval`。本需求 MUST NOT 改变锁屏满宽横条或 expanded 岛形态。

#### Scenario: Compact island stays capsule while counting down

- **WHEN** 系统以 compact Dynamic Island 展示一条未过期的 Imminent Live Activity
- **THEN** compact 岛 MUST 保持胶囊（切口 + 两侧短内容）
- **AND** MUST NOT 被拉到接近满屏宽
- **AND** compact trailing MUST 仍显示距 `nextAt` 的倒计时

#### Scenario: Overdue copy does not use timerInterval

- **WHEN** Imminent 的 `nextAt` 不晚于当前时间且 compact 岛仍在展示
- **THEN** compact trailing MUST 显示「已过时」
- **AND** MUST NOT 用 `timerInterval` 渲染该文案
- **AND** compact 岛 MUST NOT 因该文案被拉到接近满屏宽
