## Why

喂养页 `homeHistory`（`/list` 分页）与预测/小组件 `predictionRangeHistory`（近 7 日 `filter`）并行拉取，近窗记录大量重复，浪费流量与主壳启动并发。预测已依赖近 7 日真历史；应改为**单一历史池**：启动后一次灌入 7 日，喂养与预测共用；下拉加载更多用时间游标续更旧记录，不再重拉 7 日窗。

## What Changes

- **BREAKING（客户端数据路径）**：废除「喂养 list 种子 + 预测 range 另拉」双轨；主壳登录后以**一次** `GET /device/history/api/filter`（近 7 日窗、`limit≤500`）作为远端种子；7 日内记录超过 500 时**接受截断**，启动路径**不得**连环 `v2/list` 补页。
- 引入统一历史池（可仍以 `homeHistoryProvider` 为对外门面，或等价单一 notifier）：喂养列表、智能预测、桌面 widget tip/预测、WS upsert/删除均读写该池。
- 喂养下拉 **loadMore** 改为**时间游标**：`endTime = 池内最旧 startTime − 1`（秒）+ 小 `limit`（如 20），经 `filter` 或 `v2/list` 拉取更旧记录并按 id 去重合并；**不得**再以「再 filter 一遍近 7 日」或与种子脱节的 `list?page=2` 作为主路径。
- 删除或降级独立的 `predictionRangeHistory` 远端 ensure；预测输入改为读统一池（近窗视图可本地切片，不必二次 HTTP）。
- Splash **仍不得** await 该网络预拉（对齐本地-only 进 `/home`）；7 日种子在主壳/登录后、`deviceNo` 可用时 single-flight 触发。
- 磁盘快照 / 切号擦除 / History WS 单一消费者语义保持，但快照语义从「page 深度」调整为「池内容 + 是否还能更旧」。

## Capabilities

### New Capabilities

- `unified-history-pool`：统一喂养/预测历史池的种子（一次 7 日 filter）、时间游标 loadMore、与预测/widget 只读该池的行为契约。

### Modified Capabilities

- （无独立旧 capability 目录；基线 `v2.2.1.md` 中 homeHistory 双拉、widget 必读 range、page 深度等 Requirement 由本变更 delta 覆盖/取代，实现时以 `unified-history-pool` 为准。）

## Impact

- **Flutter**：`home_history_notifier`、`prediction_range_history_*`、`predictionRealHistoryProvider` / `mergeRealHistoryById`、`ucg_home_shell` bootstrap、`home_widget_sync`、loadMore UI、磁盘 `HomeHistoryStore` 快照字段。
- **HTTP**：种子用现网 `filter`；loadMore 用现网 `filter` 或 `v2/list` 的 `endTime`+`limit`（**不**新增 Go cursor API）。
- **Go**：无需改契约；>500 截断为产品接受项。
- **非目标**：改亲和算法、Pro 开通、Splash 阻塞网络、引入 opaque `cursor`/`beforeId`。
