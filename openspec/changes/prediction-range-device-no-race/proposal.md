## Why

智能预测页偶发「暂无可用预测数据」：启动时 `deviceNo` 尚未灌入内存，`/filter` 被当成「成功 0 条」并 `ready=true` 锁死；之后进预测页的 ensure 因已 ready 跳过重拉，而喂养 `/list` 已有数据也无法填入 range store。

## What Changes

- `deviceNo` 缺失时，历史 filter/v2 拉取 **必须** 视为失败（`null`），**不得** 当作成功空列表并标记 range ready。
- range `ensureLoaded` **必须** 在已登录场景下先确保本地 `deviceNo` 可读（如 `refresh`），仍无则不得 ready 成功。
- 若已 `ready` 且 `items` 为空、但此刻 `deviceNo` 已可用，进预测页 / ensure **必须** 强制再拉（自愈假成功空缓存）。
- 智能预测页空态：**加载中 / 未 ready** 不得展示「暂无可用预测数据」；仅 ready 且窗内确无事件时才展示真空文案。
- 启动路径：避免在 ColdStart 灌入 `deviceNo` 之前把假空 range 锁死（调整 splash `ensureWidgetReadyFromRef` 时序或依赖上述自愈）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-range-history`：deviceNo 门控、失败语义、空 ready 自愈重拉。
- `smart-prediction-page`：区分加载与真空空态。

## Impact

- `remote_feed_repository.dart`（空 dn 返回值）、`prediction_range_history_provider.dart`、`smart_prediction_screen.dart`；可能微调 `app.dart` / `ensureWidgetReadyFromRef` 时序。
- 不改服务端 API、预测算法；不自动新建测试文件。
- 对照未归档 `prediction-widget-seven-day-range-history` 的 range 约定；基线 `v2.1.0` 尚无已合并同名 capability。
