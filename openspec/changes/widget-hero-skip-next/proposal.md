## Why

桌面小组件「预测即将发生」只能整卡打开 App，无法在桌面快速略过当前不关心的预测；用户希望点「跳过」后立刻把下一事件提到 hero，且被跳过的事件仍可在「后续留意」看到上次记录，直到该事件有新记录再解除 hero 抑制。

## What Changes

- Android / iOS 在 **small / large** 的 hero 行右侧增加文案为 **「跳过」** 的独立按钮（与整卡打开 App 的点击分离）。
- 点击后将当前 hero 的 `eventId` 记入本机 skip 集合（**S1**：直到该事件出现新历史记录或登出清除），重算并推送小组件 payload。
- 构建 **hero** 时排除仍 skip 的 `eventId`（下一未 skip 预测升为 hero）；**`recentLast`（后续留意）仍可包含** 已 skip 的事件。
- **medium** 无 hero，不展示跳过按钮。
- 仅影响小组件编排；App 内喂养预测列表不跟跳。
- iOS 在系统支持交互小组件的版本上展示按钮；更旧系统不展示跳过、整卡行为不变。
- 不改后端 API；native 仍不自行请求网络。

## Capabilities

### New Capabilities

- `widget-hero-skip`：跳过按钮、交互回调、S1 寿命、hero 过滤与重推（recent 保留 skip）。

### Modified Capabilities

- （无独立基线 capability 目录；行为增量落在本 change 新 capability。与未归档 `home-feed-upcoming-widget` 编排约定对齐但不改其已合并基线条目。）

## Impact

- Dart：`home_widget` interactivity callback、skip prefs、`buildWidgetHero` / `buildWidgetRecentLast`（或 sync 前过滤）、历史变更时解除 skip、登出清理。
- Android：`widget_pangbao_small/large.xml`、`PangbaoWidgetRenderer` 独立 PendingIntent；**须** `flutter build apk --release` 与 proguard 视情况更新。
- iOS：`PangbaoWidget` Button + 共享 `AppIntent` / `HomeWidgetBackgroundWorker`（Runner + Extension）。
- 与 `widget-tip-companion-inject` 正交；可分 PR。
