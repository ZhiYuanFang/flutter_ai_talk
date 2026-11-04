## ADDED Requirements

### Requirement: Imminent lock screen trailing SHALL show short expect duration or amount from structured fields

When the system presents an Imminent Live Activity on the lock screen and ContentState provides a usable structured expect, the trailing slot of the bottom row MUST show short product copy as follows: for `expectKind`=`duration` with `expectDurationSec` ≥ 60,「预计{h}时{m}分钟」when hours ≥ 1 and minutes &gt; 0,「预计{h}时」when hours ≥ 1 and minutes = 0, and「预计{m}分钟」when hours = 0; for `expectKind`=`amount` with positive `expectAmount`,「预计{N}{unit}」where `N` preserves fractional digits when needed and `unit` is `expectUnit` (may be empty). The client MUST prefix amount copy with「预计」. The client MUST NOT append「约」, MUST NOT use「小时」in place of「时」for this lock-screen short form, MUST NOT append `expectLeafTitle`, and MUST NOT derive this trailing copy from `nextAt` countdown math. When `expectKind` is missing/unrecognized, duration &lt; 60 seconds, or amount ≤ 0, the trailing slot MUST be empty (no placeholder width reserved for expect). The point size of that Imminent lock trailing expect text MUST be **5pt smaller** than the lock-screen trailing baseline previously applied to Timing elapsed text (SwiftUI `.title` / equivalent semibold title size used by `LockScreenTwoTier` trailing). This −5pt rule MUST apply only to Imminent expect trailing, MUST NOT shrink Timing elapsed timer type, and MUST NOT change the event-name title size. Dynamic Island compact/expanded trailing MUST NOT show this expect copy. Decoding MUST tolerate older pushes that omit expect fields. This requirement does not restore nextAt-based time-dimension copy such as「预计m分钟后」or「已过时」.

当系统展示 Imminent Live Activity 锁屏且 ContentState 提供可用结构化 expect 时，下层右侧 MUST 按短版展示：`expectKind`=`duration` 且 `expectDurationSec`≥60 时，满小时且有分钟为「预计{h}时{m}分钟」、满小时零分钟为「预计{h}时」、不足 1 小时为「预计{m}分钟」；`expectKind`=`amount` 且 `expectAmount`&gt;0 时为「预计{N}{unit}」（`N` 保留必要小数，`unit` 为 `expectUnit` 可空）。用量文案 MUST 含前缀「预计」。MUST NOT 追加「约」、MUST NOT 在本锁屏短版用「小时」代替「时」、MUST NOT 拼接 `expectLeafTitle`、MUST NOT 用 `nextAt` 倒计时推导该右槽文案。`expectKind` 缺失/未知、duration&lt;60 秒或 amount≤0 时，右槽 MUST 为空（MUST NOT 为 expect 预留占位宽）。该 Imminent 锁屏右槽预计文案字号 MUST 相对 Timing 已计时右槽既有基准（`LockScreenTwoTier` trailing 所用 SwiftUI `.title` / 等价 semibold title）**减小 5pt**；−5pt 仅作用于 Imminent expect 右槽，MUST NOT 缩小 Timing 已计时字号，MUST NOT 改变事件名主标题字号。Dynamic Island compact/expanded trailing MUST NOT 展示该 expect 文案。解码 MUST 容忍旧推送缺省 expect 字段。本需求 MUST NOT 恢复基于 `nextAt` 的「预计m分钟后」「已过时」等时间维文案。

#### Scenario: Duration expect on lock trailing

- **WHEN** Imminent 锁屏 ContentState 为 `expectKind=duration` 且 `expectDurationSec=5400`（1 小时 30 分钟）
- **THEN** 下层右侧 MUST 显示「预计1时30分钟」
- **AND** MUST NOT 显示「预计约…」或「…小时…」

#### Scenario: Amount expect on lock trailing

- **WHEN** Imminent 锁屏 ContentState 为 `expectKind=amount`、`expectAmount=120`、`expectUnit=ml`
- **THEN** 下层右侧 MUST 显示「预计120ml」

#### Scenario: Imminent trailing type is five points smaller than title baseline

- **WHEN** Imminent 锁屏右槽展示短版 expect 文案
- **THEN** 该文案 pointSize MUST 等于既有 trailing `.title`（或等价）基准 pointSize 减 5
- **AND** Timing 锁屏已计时右槽字号 MUST 保持原 `.title` 基准（不因本需求减小）

#### Scenario: No expect keeps empty trailing

- **WHEN** Imminent 锁屏未带可用 expect 字段
- **THEN** 下层右侧 MUST 为空
- **AND** MUST NOT 展示「预计m分钟后」或基于 `nextAt` 的倒计时

#### Scenario: Sub-minute duration omitted

- **WHEN** `expectKind=duration` 且 `expectDurationSec` 小于 60
- **THEN** 下层右侧 MUST 为空

#### Scenario: Island does not show expect

- **WHEN** Imminent 以 Dynamic Island compact 或 expanded 展示且 ContentState 含可用 expect
- **THEN** Island trailing MUST NOT 展示 duration/amount 预计文案

## MODIFIED Requirements

### Requirement: iOS client SHALL present Imminent as a dedicated Live Activity type

On iOS, the client MUST provide an ActivityKit Live Activity configuration dedicated to predict-imminent (separate ActivityAttributes from Timing). When the system delivers a Push-to-Start / liveactivity start for Imminent, the lock-screen UI MUST use a two-tier layout: a narrow top row with the App name「胖宝」in the event accent color and MUST NOT show a circular App brand logo in that top row; a wider bottom row with the leading event logo resolved locally from `eventId` (fallback brand/orb if missing) and the primary title copy (existing `lockTitle` semantics unchanged, including empty fallback such as「事件即将发生」). The lock-screen trailing slot MUST NOT show nextAt-based time-dimension copy—including「预计m分钟后」, digital countdowns to `nextAt`, or「已过时」—but MAY show short structured expect duration/amount copy when ContentState provides usable expect fields as specified by「Imminent lock screen trailing SHALL show short expect duration or amount from structured fields」. Bottom-row event logo size MUST be approximately two-thirds of the prior two-tier lock-screen size (about 37pt when the prior size was 56pt). The UI MUST NOT show a trailing chevron/arrow. Event text color MUST follow the catalog color for that `eventId`, brightened when too dark against the Live Activity background tint. The push payload MUST NOT be required to carry logo URL or color hex; the client MUST resolve visuals from App Group / local catalog cache keyed by `eventId`. The client MUST NOT locally `Activity.request` (or equivalent) an Imminent Live Activity for this product path; presentation MUST wait for server push as specified by twin change `predict-live-activity-push`. Android MUST NOT be required to implement a lock-screen Live Activity in this change.

iOS 客户端 MUST 提供专用于预测临近的 Live Activity 配置（与 Timing 不同 Attributes）。系统送达 Imminent 的 Push to Start / liveactivity start 时，锁屏 MUST 为双层：上层窄行仅 App 名「胖宝」（事件提亮色），MUST NOT 在上层展示圆形 App 品牌 logo；下层宽行按 `eventId` 本地解析的事件 logo（缺失则品牌/色球兜底）与主标题（既有 `lockTitle` 语义不变，空名兜底如「事件即将发生」可保留）。锁屏右槽 MUST NOT 展示基于 `nextAt` 的时间维文案（含「预计m分钟后」、到 `nextAt` 的数字倒计时、「已过时」），但当 ContentState 提供可用结构化 expect 时 MAY 按「Imminent lock screen trailing SHALL show short expect duration or amount from structured fields」展示短版 duration/amount 预计文案。下层事件 logo 尺寸 MUST 约为上一版双层锁屏的 2/3（上一版 56pt 时约 37pt）。MUST NOT 展示右箭头。文案色 MUST 跟随该事件 catalog 色，并在相对 LA 深色底过深时提亮。推送 MUST NOT 被要求携带 logo URL 或颜色 hex；客户端 MUST 经 App Group / 本地缓存按 `eventId` 解析。本产品路径 MUST NOT 本地 `Activity.request` 拉起 Imminent，MUST 等待对端 `predict-live-activity-push` 推送。本变更 MUST NOT 要求 Android 实现锁屏 Live Activity。

#### Scenario: Dedicated Imminent UI two-tier lock screen without nextAt time copy

- **WHEN** 系统展示一条 Imminent Live Activity 的锁屏 content 且无可用 expect 字段
- **THEN** UI MUST 含上层「胖宝」（无圆形 App logo）、下层事件图（或兜底）、标题
- **AND** 下层右侧 MUST NOT 展示「预计m分钟后」或其它基于 `nextAt` 的时间维文案
- **AND** MUST NOT 展示右箭头
- **AND** MUST 使用与 Timing 不同的 Activity 配置

#### Scenario: Trailing may show structured expect without restoring nextAt countdown

- **WHEN** Imminent 锁屏 ContentState 含可用 `expectKind=duration` 或 `amount`
- **THEN** 下层右侧 MAY 显示短版「预计…」duration/amount 文案
- **AND** MUST NOT 因此恢复「预计m分钟后」或「已过时」

#### Scenario: Title may keep upcoming wording

- **WHEN** Imminent 锁屏标题 ContentState/Attributes 为空
- **THEN** 主标题 MUST 可回退为「事件即将发生」（或既有 `lockTitle` empty）
- **AND** 该状态语气 MUST NOT 被视为违规的 nextAt 时间维读数

#### Scenario: No nextAt-based copy before nextAt

- **WHEN** Imminent 的 `nextAt` 仍晚于当前时间且该 Live Activity 在展示
- **THEN** 锁屏下层右侧 MUST NOT 显示「预计m分钟后」
- **AND** MUST NOT 展示到 `nextAt` 的数字倒计时

#### Scenario: No nextAt-based copy after nextAt

- **WHEN** Imminent 的 `nextAt` 不晚于当前时间且该 Live Activity 仍在展示
- **THEN** 锁屏下层右侧 MUST NOT 显示「已过时」
- **AND** MUST NOT 展示到 `nextAt` 的数字倒计时

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
