## Why

`prediction-layout-list-grid` 去掉了每事件推演开关后，用户无法按事件关闭推演；且桌面小组件从未消费推演关闭集合，关闭后小组件仍可能展示该事件。需要恢复紧凑开关，并让预测页、值得留意与小组件共用同一关闭集合。

## What Changes

- **恢复**每事件推演开关（默认 ON，本地持久化）；**纵向与网格**卡片均展示；控件形态 **更小**（迷你 Switch / 等价紧凑控件）。
- 推演 OFF：该事件在预测页置灰、无相对时间、无折线；首页 tip 不选用；**值得留意跑马灯不纳入**该事件。
- 推演 OFF **必须**影响桌面小组件：hero / 后续留意等预测行 **不得**再展示该 `eventId`；开关变更后触发既有 widget sync（single-flight）。
- 对冲 `prediction-layout-list-grid` 中「REMOVED 推演开关」：本变更重新引入并扩展小组件与留意过滤。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：恢复紧凑推演开关（list+grid）；OFF 时卡片/tip 行为。
- `prediction-care-alert`：聚合/展示前排除推演关闭事件。
- `home-feed-upcoming-widget`：小组件预测消费尊重推演关闭集合；开关变更后同步。

## Impact

- UI：`smart_prediction_screen.dart` 卡片行尾小开关。
- Provider：`smart_prediction_provider` / tip 重新 `watch forecastDisabledIdsProvider`；`predictionCareAlertProvider` 过滤 disabled。
- 小组件：`home_widget_sync.dart`（及 interactivity 重算路径）读 `ForecastToggleStore`；toggle 后 `scheduleHomeWidgetSync`。
- 复用既有 `ForecastToggleStore`；不改服务端；不自动新建测试。
