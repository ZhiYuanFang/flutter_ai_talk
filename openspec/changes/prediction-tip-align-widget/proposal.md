## Why

桌面小组件已展示 tip，但智能预测页底栏横向跑马灯常不出现：预测页 `peek` 强制「当日 dayKey」，与小组件「有 `widget_tip_text` 即展示」不一致；且 tip 写入后 `widgetTipCardTextProvider` 未必刷新。产品要求与小组件对齐——有文案则展示，不判断是否今日；同时底栏跑马灯滚动过快，速度降为约一半。

## What Changes

- 预测页底栏 tip 可见性与小组件对齐：SharedPreferences 中 tip 正文 trim 后非空即展示，**不得**再以「是否当日 dayKey」作为隐藏条件。
- tip 缓存写入或小组件 sync 成功推送 tip 后，**必须**使预测页 tip provider 重新 peek，避免先空后写导致底栏一直不刷。
- 底栏横向跑马灯线速度约降至当前一半（如 `_pxPerSec` 36 → 18）。
- **不**改变 tip 拉取 API、陪伴注入的「当日」语义、登出清缓存策略。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：底栏 tip 展示条件与小组件文案缓存对齐（去当日判定）；横向跑马灯速度减半；tip 写入后 UI 须可刷新。

## Impact

- 代码：`app/lib/home_widget/widget_tip_cache.dart`（`peekWidgetTipDisplayText`）、`app/lib/providers/smart_prediction_provider.dart`、`app/lib/home_widget/home_widget_sync.dart`（及必要时 interactivity 写 tip 后 invalidate）、`app/lib/ui/smart_prediction_screen.dart`（`_BottomTipMarquee` 速度）。
- 对照未归档 `prediction-tip-bottom-marquee` 与基线中小组件 tip 相关 Requirement；本变更仅放宽**预测页展示**的 day 门槛，不改 companion 注入 day 规则。
- 无 Android 原生 / R8 / 新依赖；不新建 `**/test/**`。
