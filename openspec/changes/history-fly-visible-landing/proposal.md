## Why

历史落库飞入动画目前仅在喂养页、且仅在「真正新增 / awaiting」时触发；用户在预测主页时看不见动画，且停表、更新、删除等 WS 历史变动无反馈。需要同一套飞入体感覆盖喂养与预测可见页，并在任意历史变动时给出落点反馈。

## What Changes

- **BREAKING（相对 `home-event-record-fly`）**：History WS/SSE 的 create / update / delete 等任意历史变动，在当前可见页为喂养或预测时，均尝试触发落库飞入；不再以 `isNew` / awaiting 作为飞入门槛；接受连播（以最新 session 为准）。
- 飞入动画逻辑保持一套（屏中心 pop → 缩小落锚）；喂养与预测仅提供不同落点（LandingTarget）。
- 喂养落点：该 `recordId` 历史行当前 EventLogo 锚点（沿用现测锚能力）。
- 预测落点：该 record 对应预测卡片上**当前展示**的 logo 槽位（计时叶子图 / 普通根图共用同一锚点位）。
- 仅当前 PageView 可见页播放；UCG 等其它页不飞。
- 测不到可用锚点则**不飞**（删除后无 logo、无对应预测卡等直接跳过）。
- 预测卡不在屏内时，须先自动滚动至该卡、锚点可见后再飞。

## Capabilities

### New Capabilities

- `history-fly-visible-landing`：可见页选落点的共享历史飞入编排与预测侧锚点行为。

### Modified Capabilities

- `home-event-record-fly`：放宽触发条件（全变动可飞）；明确不可见页不飞、无锚点不飞；飞入 UI 与落点解析解耦。

## Impact

- `HomeScreen`：弱化 / 移除仅新增飞入与 `_awaitingWsFlyIds` 门槛；飞入改为共享编排 + FeedingLanding。
- `SmartPredictionScreen`：注册预测卡 logo 锚点、prepare 滚入可视、挂同一套 Overlay。
- `HomeEventRecordFlyOverlay`（或泛化后的共享 overlay）：改为依赖 LandingTarget，而非死绑 `HomeHistoryScroll`。
- `ucg_home_shell` / `homePager`：编排需感知当前页索引。
- History WS 订阅可仍由喂养 KeepAlive 持有，但触发决策必须看可见页。
- OpenSpec 基线收版时同步 `home-event-record-fly` 与新 capability。
