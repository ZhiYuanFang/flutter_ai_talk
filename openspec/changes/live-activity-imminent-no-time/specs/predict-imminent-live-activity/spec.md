## MODIFIED Requirements

### Requirement: iOS client SHALL present Imminent as a dedicated Live Activity type

On iOS, the client MUST provide an ActivityKit Live Activity configuration dedicated to predict-imminent (separate ActivityAttributes from Timing). When the system delivers a Push-to-Start / liveactivity start for Imminent, the lock-screen UI MUST use a two-tier layout: a narrow top row with the App name「胖宝」in the event accent color and MUST NOT show a circular App brand logo in that top row; a wider bottom row with the leading event logo resolved locally from `eventId` (fallback brand/orb if missing) and the primary title copy (existing `lockTitle` semantics unchanged, including empty fallback such as「事件即将发生」). The lock-screen trailing/time slot MUST NOT show any time-dimension copy at any phase—including before and after `nextAt`—such as「预计m分钟后」, digital countdowns, or「已过时」. Bottom-row event logo size MUST be approximately two-thirds of the prior two-tier lock-screen size (about 37pt when the prior size was 56pt). The UI MUST NOT show a trailing chevron/arrow. Event text color MUST follow the catalog color for that `eventId`, brightened when too dark against the Live Activity background tint. The push payload MUST NOT be required to carry logo URL or color hex; the client MUST resolve visuals from App Group / local catalog cache keyed by `eventId`. The client MUST NOT locally `Activity.request` (or equivalent) an Imminent Live Activity for this product path; presentation MUST wait for server push as specified by twin change `predict-live-activity-push`. Android MUST NOT be required to implement a lock-screen Live Activity in this change.

iOS 客户端 MUST 提供专用于预测临近的 Live Activity 配置（与 Timing 不同 Attributes）。系统送达 Imminent 的 Push to Start / liveactivity start 时，锁屏 MUST 为双层：上层窄行仅 App 名「胖宝」（事件提亮色），MUST NOT 在上层展示圆形 App 品牌 logo；下层宽行按 `eventId` 本地解析的事件 logo（缺失则品牌/色球兜底）与主标题（既有 `lockTitle` 语义不变，空名兜底如「事件即将发生」可保留）。锁屏右侧／时间位在任意阶段（含 `nextAt` 前后）MUST NOT 展示任何时间维文案，包括「预计m分钟后」、数字倒计时或「已过时」。下层事件 logo 尺寸 MUST 约为上一版双层锁屏的 2/3（上一版 56pt 时约 37pt）。MUST NOT 展示右箭头。文案色 MUST 跟随该事件 catalog 色，并在相对 LA 深色底过深时提亮。推送 MUST NOT 被要求携带 logo URL 或颜色 hex；客户端 MUST 经 App Group / 本地缓存按 `eventId` 解析。本产品路径 MUST NOT 本地 `Activity.request` 拉起 Imminent，MUST 等待对端 `predict-live-activity-push` 推送。本变更 MUST NOT 要求 Android 实现锁屏 Live Activity。

#### Scenario: Dedicated Imminent UI two-tier lock screen without time

- **WHEN** 系统展示一条 Imminent Live Activity 的锁屏 content
- **THEN** UI MUST 含上层「胖宝」（无圆形 App logo）、下层事件图（或兜底）、标题
- **AND** 下层右侧 MUST NOT 展示「预计m分钟后」或其它时间维文案
- **AND** MUST NOT 展示右箭头
- **AND** MUST 使用与 Timing 不同的 Activity 配置

#### Scenario: Title may keep upcoming wording

- **WHEN** Imminent 锁屏标题 ContentState/Attributes 为空
- **THEN** 主标题 MUST 可回退为「事件即将发生」（或既有 `lockTitle` empty）
- **AND** 该状态语气 MUST NOT 被视为违规的时间维读数

#### Scenario: No time-dimension copy before nextAt

- **WHEN** Imminent 的 `nextAt` 仍晚于当前时间且该 Live Activity 在展示
- **THEN** 锁屏下层右侧 MUST NOT 显示「预计m分钟后」
- **AND** MUST NOT 展示数字倒计时

#### Scenario: No time-dimension copy after nextAt

- **WHEN** Imminent 的 `nextAt` 不晚于当前时间且该 Live Activity 仍在展示
- **THEN** 锁屏下层右侧 MUST NOT 显示「已过时」
- **AND** MUST NOT 展示其它时间维文案（含数字倒计时）

#### Scenario: Top row has no app brand mark

- **WHEN** 系统展示 Imminent 锁屏双层 content
- **THEN** 上层 MUST 含「胖宝」
- **AND** MUST NOT 展示圆形 App brand logo

#### Scenario: Event logo about two-thirds prior size

- **WHEN** Imminent 锁屏下层渲染事件 logo
- **THEN** logo 逻辑尺寸 MUST 约为先前双层锁屏 56pt 的 2/3（约 37pt）

#### Scenario: Local visual by eventId

- **WHEN** 推送 Attributes 含有效 `eventId` 且客户端已将对应 logo/色写入 App Group 索引
- **THEN** 锁屏下层 MUST 使用该事件 logo 与（经提亮处理后的）事件色文案
- **AND** 上层 App 名 MUST 使用同一提亮事件色
- **AND** MUST NOT 要求推送 ContentState 含 logo 或 color 字段

#### Scenario: No local request for Imminent

- **WHEN** 用户本机发生喂养/预测相关变更或 App 在前台
- **THEN** 客户端 MUST NOT 仅凭本机逻辑 `Activity.request` 拉起 Imminent Live Activity

#### Scenario: Android out of scope

- **WHEN** 在 Android 上交付本变更
- **THEN** MUST NOT 要求实现锁屏 Live Activity

## ADDED Requirements

### Requirement: Imminent Dynamic Island SHALL NOT show time-dimension copy

When the system presents an Imminent Live Activity on Dynamic Island, compact trailing and expanded trailing MUST NOT show countdown digits,「预计m分钟后」,「已过时」, or any other time-dimension copy, whether or not `now` is before `nextAt`. Compact presentation MUST NOT reserve intrinsic width via a hidden `"00:00:00"` (or equivalent) time placeholder slot for Imminent; island width MUST be driven by leading content (event logo and optional short name) and minimal presentation, not by an empty trailing timer slot. Status titles such as「即将发生」in expanded center MAY remain. Timing Live Activity island behavior is out of scope for this requirement.

当系统以 Dynamic Island 展示 Imminent Live Activity 时，compact trailing 与 expanded trailing MUST NOT 展示倒计时数字、「预计m分钟后」、「已过时」或其它时间维文案，无论当前是否早于 `nextAt`。Imminent compact MUST NOT 再以隐藏 `"00:00:00"`（或等价）时间占位槽预留固有宽；岛宽 MUST 由 leading（事件 logo 与可选短名）与 minimal 决定，MUST NOT 由空的右侧 timer 槽撑开。expanded 中心「即将发生」等状态标题 MAY 保留。本需求不约束 Timing 的 Island 行为。

#### Scenario: Expanded trailing has no countdown

- **WHEN** Imminent 以 Dynamic Island expanded 展示且距 `nextAt` 仍有剩余
- **THEN** trailing MUST NOT 显示 `hh:mm:ss` 或其它时间维文案

#### Scenario: Compact has no trailing time slot

- **WHEN** Imminent 以 Dynamic Island compact 展示
- **THEN** compactTrailing MUST NOT 展示倒计时
- **AND** MUST NOT 使用隐藏 `"00:00:00"` 占位为 Imminent 预留右侧 timer 宽

#### Scenario: Expanded center may keep upcoming title

- **WHEN** Imminent expanded 中心标题为空回退
- **THEN** UI MAY 显示「即将发生」
- **AND** MUST NOT 因此被要求恢复 trailing 倒计时

## REMOVED Requirements

### Requirement: Imminent Dynamic Island time SHALL always use hh:mm:ss

**Reason**: 预计事件全表面不再展示时间维；Island 倒计时与固定 `hh:mm:ss` 规则废止。  
**Migration**: 按 ADDED「Imminent Dynamic Island SHALL NOT show time-dimension copy」验收；勿再要求 Imminent compact/expanded 显示 `hh:mm:ss`。
