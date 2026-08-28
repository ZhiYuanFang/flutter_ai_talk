## Why

智能预测页在「已有部分真实喂养历史、但单事件样本不足以本地推演」时，卡片无倒计时且缺少引导；值得留意日拉取门闸过宽（7 日内任意 1 条即拉），与产品「需有昨日历史才分析」不符；桌面小组件 tip 已改为复用留意数据，但 fail-day 熔断、Repository 内错误读取路径及文案字段选择导致 tip 长期不展示。需在一条变更中统一修复三处体验与数据链路。

## What Changes

- **值得留意拉取门闸**：`care-alert` 日拉取 **BREAKING** 收紧为「已登录 + deviceNo + 7 日 range 就绪 + **存在 Asia/Shanghai 昨日发生的历史记录**」；无昨日历史时 **不得** 发起日拉取 HTTP。
- **预测卡片 per-card 回忆**：当根事件推演开启、已有 `lastAt` 但 `prediction == null` 时，卡片内展示 CTA；点击弹出玻璃 Sheet **仅选择「大概多久一次」**（15 分钟步进滚轮，复用 recall picker 原子）；以 `row.lastAt` 为锚写入回忆种子，**不得**再要求选择上次时间；不写喂养历史、不打副作用 HTTP。
- **小组件 tip 数据源**：桌面小组件 tip 正文 **BREAKING** 改为从客户端已拉取的留意日缓存（过滤后非空列表）派生，**不得**再经 `POST /device/history/api/chat`；文案优先 `summaryLine`，辅以 `detailLines`；留意未 ready 或列表为空时 tip 为空、**不得**展示占位。
- **去掉 tip fail-day 锁死**：移除 `widget_tip_fail_day_v1` 读写；tip 解析为空时 **不得** 写入当日 fail 标记，后续 `scheduleHomeWidgetSync` / 留意 ensure 成功 **必须** 可重复尝试并更新 prefs 快照。
- **tip 刷新时机**：留意 ensure 成功、本地忽略项、或过滤后列表变化后 **必须** 触发 widget sync 并重算 tip cache；读取留意状态 **必须** 使用 `Ref.read`（或 container.read），**不得** 在 Repository 异步路径使用 `watch`。

## Capabilities

### New Capabilities

- `prediction-recall-per-card-interval`：热态（非空库）单事件样本不足时，预测卡片内 CTA + 仅间隔 Sheet + 回忆种子写入与推演生效。
- `widget-tip-from-care-alert`：小组件 tip 从留意日缓存派生、fail-day 移除、与 sync/注入 prefs 快照策略。

### Modified Capabilities

- `llm-care-alert-daily`：日拉取门闸由「7 日真历史非空」改为「7 日 range 就绪且含 Shanghai 昨日发生记录」；与 widget tip 共用同一 gate 判定 helper。
- `smart-prediction-page`：预测事件卡在 `prediction == null && lastAt != null` 时展示 per-card 引导控件；与空库量身定做 Dialog 并存、互不替代。

## Impact

- **代码**：`prediction_care_alert_provider.dart`（gate helper）、`ucg_home_shell.dart`（ensure 触发）、`smart_prediction_screen.dart` / `_PredictionEventCard`（CTA + Sheet）、`prediction_recall_seed.dart` / seed store（热态 upsert）、`widget_tip_cache.dart`（移除 fail-day、改 resolve 入口）、`home_widget_sync.dart`（留意就绪后重算 tip）、`remote_feed_repository.dart`（移除或瘦身 `fetchWidgetFeedingTip` 中留意 watch）、`care_alert` 忽略后 bump sync。
- **规格基线**：`v2.1.0` 中 `Widget tip fetch API SHALL remain history chat sync` **将被本变更 supersede**（经 delta spec）。
- **后端**：无新 API；仍用现有 `GET /device/api/care-alert/daily`。
- **测试**：按仓库约定不新增 `**/test/**`；手工验证预测页卡片 CTA、昨日/非昨日门闸、小组件 tip 展示与 ignore 后刷新。
