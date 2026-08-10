## Why

预测页折线与小组件预测此前依赖喂养 `homeHistoryProvider` 分页预拉（30 日 / 7 日拼页），与列表刷新、loadMore 抢同一状态，易半拉子、难复现。兄弟仓已提供按时间范围查历史的接口；产品确认预测与小组件只需近 **7** 日数据，应共用独立数据源，不再加深喂养分页。

## What Changes

- **BREAKING（客户端行为）**：废止小组件经 `ensureWidgetHistoryDepth` + `loadMoreHistory` 预拉至 **30** 自然日的路径；改为拉取本地近 **7** 日时间窗历史。
- **BREAKING（相对未归档的预测页预拉）**：废止预测页对 `homeHistory` 分页直至跨满 7 日的预拉；改为同一 range 接口与独立 provider。
- 对接既有网关：优先 `GET /device/history/api/filter`（`startTime`/`endTime`/`limit`，空 `eventIds`）；若单次触达 `limit` 上限（500）则用 `GET /device/history/api/v2/list` 在同窗内分页补全。
- 新增独立 Riverpod store（勿与 `homeHistoryProvider` 共用）：供智能预测页（列表/折线）、喂养顶栏预测贴士、桌面小组件 `predictAllUpcoming` 消费。
- 喂养主页历史列表继续只用 v1 `/device/history/api/list` 分页；range 拉取 **不得** 写入喂养列表分页状态。
- 历史 WS / 本地增删改后：range store single-flight 失效重拉（或等价合并），遵守副作用 HTTP 治理。
- 预测页图区 loading 绑定 range store in-flight，不再绑定 `homeHistory` 分页深度。

## Capabilities

### New Capabilities

- `prediction-range-history`：近 7 日时间窗历史的拉取契约、独立 store、与喂养分页隔离、预测页/顶栏/小组件共享消费及失效重拉。

### Modified Capabilities

- `home-feed-upcoming-widget`：小组件历史深度由「分页至 30 日」改为「与预测同源的 7 日 range 拉取」；`widgetHistoryDepthReady` 语义对齐 range ready。
- `side-effect-http-governance`：小组件预拉治理从「与 UI loadMore 共享分页」改为「range 拉取 single-flight / 熔断 / 非 provider 构造启动」。
- `smart-prediction-page`：进页 7 日数据改为 range store（相对 change `replace-companion-with-smart-prediction` 中的分页预拉需求）。
- `home-prediction-tip-bar`：顶栏本地预测改为消费 range store（与预测页同源）。

## Impact

- **Flutter**：`feed_repository` / API 封装、`prediction_history_depth` / `widget_history_depth`、`home_widget_sync`、`smart_prediction_provider`、顶栏 tip provider；常数 `prefetchDaySpan`。
- **API**：复用 `go_ai_talk` 已有 `filter` 与 `v2/list`，不新增后端 path。
- **喂养列表**：无功能破坏性要求；对齐隔离后不再被小组件/预测预拉搅动。
- **测试**：不新建 `**/test/**`；手工验收预测页折线、顶栏、小组件与喂养下拉分页互不干扰。
- **Android**：不改 `app/android/**`，本 change 不强制 release APK。
