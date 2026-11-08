## ADDED Requirements

### Requirement: iOS client SHALL use a single BabyLiveActivityAttributes for Live Activity

On iOS, the client MUST provide exactly one ActivityKit Live Activity configuration whose attributes type name is `BabyLiveActivityAttributes` (overridable only to match twin env `PUSH_LA_ATTR_TYPE`). The client MUST NOT register separate ActivityConfigurations for `PredictImminentAttributes` and `PredictTimingAttributes` on the product Live Activity path. Decoding of Attributes and ContentState MUST tolerate missing keys with empty/zero defaults. Attributes MUST NOT require logo/color fields from the push. 客户端 MUST 仅注册统一 `BabyLiveActivityAttributes`；MUST NOT 再注册双轨 Imminent/Timing ActivityConfiguration；解码 MUST 容忍缺键；推送 MUST NOT 被要求带 logo/color。

#### Scenario: Unified attributes type

- **WHEN** 系统以 Push-to-Start / liveactivity start 拉起产品 Live Activity
- **THEN** APNs `attributes-type` 与客户端 Codable 类型 MUST 为 `BabyLiveActivityAttributes`（或与 `PUSH_LA_ATTR_TYPE` 一致的单一名称）

#### Scenario: Dual types removed

- **WHEN** 本变更合入后的 Widget Extension 启动
- **THEN** MUST NOT 再向 WidgetKit 注册 `PredictImminentAttributes` / `PredictTimingAttributes` 的产品 ActivityConfiguration

### Requirement: Live Activity ContentState SHALL decode an ordered items list

ContentState MUST decode an `items` array and a `phase` string. Each item MUST include a `kind` discriminant of `imminent` or `timing` and the display fields supplied by the twin (at least `eventId` plus `nextAt`/`title`/`expect*` for imminent, or `historyId`/`eventName`/`startTime`/`expectEndAt` for timing). The client MUST render list rows in the array order provided by the push (twin sorts predict `nextAt` ascending then timing `startTime` descending). The client MUST NOT require logo/color in ContentState. ContentState MUST 解码 `items` 与 `phase`；按推送顺序渲染；禁止要求视觉 URL 字段。

#### Scenario: Mixed list

- **WHEN** ContentState `items` 含一条 `kind=imminent` 与一条 `kind=timing`
- **THEN** 锁屏 MUST 按数组顺序各渲染一行对应样式

#### Scenario: Missing optional fields

- **WHEN** 某 imminent 项缺 `expectKind` 或某 timing 项缺 `expectEndAt`
- **THEN** 客户端 MUST 仍能解码该行并按既有空态省略 expect 右槽或副行

### Requirement: Lock screen SHALL show a centered theme-colored brand row and dynamic item rows

The lock-screen Live Activity MUST show a single top brand row with the text「胖宝」horizontally centered. The brand text color MUST use the product theme/primary color constant in the Widget Extension (lifted for LA dark background readability if needed) and MUST NOT use a per-item event accent for that brand row. Below the brand row, the client MUST vertically stack one row per ContentState item, using the existing Imminent row chrome for `kind=imminent` and the existing Timing row chrome for `kind=timing` (logo from local `eventId` visuals, titles, expect trailing / expectEndAt subtitle / elapsed timer semantics unchanged). The client MUST NOT invent a fixed three-row template independent of `items`. The client MUST NOT restore nextAt-based countdown copy on Imminent rows. 锁屏 MUST 顶栏居中主题色「胖宝」，其下按 `items` 动态堆叠既有 Imminent/Timing 行样式；MUST NOT 固定三行模板；Imminent 行 MUST NOT 恢复 nextAt 倒计时文案。

#### Scenario: Brand centered theme color

- **WHEN** 锁屏展示统一 Live Activity
- **THEN** 「胖宝」MUST 横向居中且颜色为产品主题主色（非事件 accent）

#### Scenario: Dynamic rows preserve kind styles

- **WHEN** `items` 含 imminent（有 duration expect）与 timing（有 expectEndAt）
- **THEN** imminent 行 MUST 仍为 logo+title+短版预计右槽；timing 行 MUST 仍为 logo+事件名+「预计 HH:mm 结束」副行+右侧已计时

#### Scenario: Empty expect on imminent row

- **WHEN** imminent 项无可用 expect 字段
- **THEN** 该行右槽 MUST 为空，MUST NOT 用 nextAt 填充倒计时

### Requirement: Dynamic Island SHALL present only the first list item

When presenting Dynamic Island compact/expanded/minimal for the unified Live Activity, the client MUST use only `items.first`. If the first item is `imminent`, Island chrome MUST follow the existing Imminent Island rules (no time trailing slot). If the first item is `timing`, Island chrome MUST follow the existing Timing Island rules (elapsed timer in trailing slots). Remaining items MUST remain lock-screen-only. Empty `items` MUST NOT be relied on for a lasting Island (server end clears). 灵动岛 MUST 仅用 `items.first` 并按该 kind 沿用既有 Island 样式；其余条目 MUST 仅锁屏可见。

#### Scenario: First imminent

- **WHEN** `items[0].kind=imminent` 且 Island 为 compact
- **THEN** MUST 展示该条 logo+名称，MUST NOT 预留 timer 右槽，MUST NOT 用后续 timing 项驱动 Island

#### Scenario: First timing

- **WHEN** `items[0].kind=timing` 且 Island 为 compact
- **THEN** MUST 展示该条 logo+名称与既有短占位已计时右槽

### Requirement: Client SHALL register Live Activity tokens without attributesKind or activityId slots

The iOS client MUST register Push-to-Start and activity update tokens via `POST /app/api/push/live-activity/register` with body fields `wxId` (non-zero), `deviceKey`, `tokenKind` (`push_to_start` or `activity`), and `token`. The client MUST NOT require or send `attributesKind` or `activityId` for slotting. Successful registration MUST NOT require Bearer/JWT. The client MUST observe Push-to-Start / activity tokens for the single `BabyLiveActivityAttributes` type only. Failure MUST NOT crash the app. 客户端 MUST 按统一单轨 register；MUST NOT 再传 attributesKind/activityId 分槽；MUST 仅观察统一 Attributes 类型。

#### Scenario: Register push_to_start

- **WHEN** 已登录用户收到统一 Attributes 的 Push-to-Start token 且本地有非零 wxId
- **THEN** 客户端 MUST `POST .../live-activity/register` 且 body 含该 wxId、`tokenKind=push_to_start`、`token`，且 MUST NOT 依赖 `attributesKind`

#### Scenario: Register activity token

- **WHEN** 系统已拉起统一 Live Activity 且拿到 activity update token
- **THEN** 客户端 MUST 以 `tokenKind=activity` 上报且 MUST NOT 要求非空 `activityId` 分槽字段

### Requirement: Live Activity deep link SHALL open the prediction surface without client-side dismiss

Tapping the unified Live Activity MUST open the app to the prediction surface family. The client MUST NOT end the Live Activity solely because of the tap; dismissal MUST rely on server-driven end. 点击 MUST 进预测页族；MUST NOT 仅因点击 end。

#### Scenario: Tap opens app

- **WHEN** 用户点击统一 Live Activity
- **THEN** App MUST 打开并进入预测相关表面，且 MUST NOT 仅因该点击结束活动
