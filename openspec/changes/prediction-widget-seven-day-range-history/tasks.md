## 1. API 与 range store

- [x] 1.1 在 `FeedRepository` / remote 封装 `GET /device/history/api/filter` 与 `GET /device/history/api/v2/list`（时间窗 + limit/分页）
- [x] 1.2 实现近 7 日窗计算（本地 today-6d 00:00 → now）与 filter→必要时 v2 补页逻辑（single-flight、连续失败熔断）
- [x] 1.3 新增独立 `predictionRangeHistory` provider/store；登出清空；**不**写入 `homeHistoryProvider` 分页状态
- [x] 1.4 历史 create/update/delete（含 WS 反映后）使 range 失效并 single-flight 重拉（可短防抖）

## 2. 切换消费方

- [x] 2.1 智能预测页行/折线与图区 loading 改为依赖 range store；移除对 `ensurePredictionHistoryDepth` / `loadNextHistoryPage` 的依赖
- [x] 2.2 喂养顶栏预测贴士改为基于 range store 计算
- [x] 2.3 `syncHomeWidgetFromRef` / 小组件预测改为读取 range store；`widgetHistoryDepthReady` 对齐 range 成功

## 3. 拆除旧预拉

- [x] 3.1 废止 `ensureWidgetHistoryDepth` 经 `loadMoreHistory` 拉满 30 日的路径（删除或委托 range ensure）
- [x] 3.2 将 `HomeWidgetConstants.prefetchDaySpan` 等 30 日语义改为 7 日或删除无用常数
- [x] 3.3 确认喂养下拉 refresh / 顶拉 loadMore 不再被小组件或预测预拉打断

## 4. 文档与验收

- [x] 4.1 必要时更新 `app/README.md`：预测/小组件用 7 日 range，与喂养分页隔离
- [x] 4.2 手工验收：进预测页 loading→折线；顶栏有预测；小组件有 hero；喂养分页仍可用；log 见 filter 或 v2/list
- [x] 4.3 未改 `app/android/**`；本 change 不强制 `flutter build apk --release`
