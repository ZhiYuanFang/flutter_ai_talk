## Context

现状：主壳登录后并行 `homeHistory.bootstrap` → `GET /device/history/api/list?page=1` 与 `predictionRangeHistory.ensureLoaded` → `GET /device/history/api/filter` 近 7 日（触顶 500 时再 `v2/list` 补页）。预测/widget 经 `predictionRealHistoryProvider`（home∪range）消费；喂养 loadMore 走 `list?page=N`。近窗数据大量重复。

Go 现网（已校对 `go_ai_talk`）：

- `filter`：`startTime`/`endTime` 按 `start_time` GTE/LTE（含边界）+ `limit`≤500，按 `id DESC`；**无** opaque cursor。
- `v2/list`：同上时间窗 + `page`/`pageSize`，或 `limit>0` 时 page 固定 1。
- `list` v1：仅 page/pageSize。

基线：`openspec/specs/v2.2.1.md`。相关完整 change：`align-go-free-predict-retire`（预测单轨；本变更不改算法）。

## Goals / Non-Goals

**Goals:**

- 单一历史内存池，喂养 UI / 预测 / widget 同源。
- 主壳/`deviceNo` 就绪后 **一次** 近 7 日 `filter` 种子；>500 **截断**、启动不连环补页。
- loadMore：**时间游标**（`endTime = 最旧 startTime − 1` + 小 limit）续更旧；不去重拉 7 日窗。
- Splash 仍本地-only 进主页；网络种子不阻塞 Splash。
- 保留 History WS 单消费者写入同一池；切号擦除覆盖池与磁盘。

**Non-Goals:**

- 新增 Go `cursor`/`beforeId`/`nextCursor`。
- 改 `predictAllUpcoming` / 亲和进度算法或 Pro 商业面。
- Splash await 历史 HTTP。
- 自动新建 `**/test/**`。
- 预约「上一次」不限窗 filter（`ignoreTimeRange`）仍可独立调用，不强制改走池。

## Decisions

### D1：单一池门面

- **选择**：以增强后的 `homeHistoryProvider`（或薄封装同 notifier）为唯一内存源；删除/挖空 `predictionRangeHistory` 的远端 ensure；`predictionRealHistoryProvider` 改为直接读池（可本地按 7 日切片给预测，但 **不再** HTTP 第二套）。
- **备选**：新建第三 notifier 再让两边转发——迁移成本高、易残留双写。
- **理由**：WS/飞入/擦除已绑 home；收敛写路径最省。

### D2：种子 = 一次 filter 近 7 日

- **选择**：`predictionSevenDayUnixBounds` 同窗；`tryLoadHistoryFilter(start, end, limit=500)` **仅一次**。返回条数==500 视为可能截断，标记 `seedTruncated`（可选 Debug），**不**启动 v2 补页。
- **备选**：保留触顶 v2——与「开局一次接口」冲突。
- **理由**：产品已接受 >500 截断；与 Go limit 上限一致。

### D3：loadMore = 时间游标 + 条数

- **选择**：池非空时取最旧记录的 `startTime`（unix 秒）；请求 `endTime = that − 1`、`startTime=0`（或不传）、`limit=20`（filter 或 v2 `limit`）。合并按 id 去重；若返回空则 `hasMoreOlder=false`。同秒多条靠 id 去重。
- **备选**：页码推算 `floor(M/20)+1` 的 v1 list——filter 条数非整页、截断时易错位。
- **理由**：现网已支持时间上界+limit；语义即「比池更旧」。

### D4：触发时机

- **选择**：磁盘 hydrate 可先展示；远端种子在主壳挂载且已登录、`deviceNo` 可用后 single-flight（与现 `ucg_home_shell` 预热同位），**不得**放入 Splash await 链。
- **备选**：进预测页才拉——喂养首屏仍空/缺近窗，再双拉风险高。
- **理由**：对齐「启动后预拉 7 日」与 Splash 基线。

### D5：快照与 page 语义

- **选择**：磁盘快照存池 items + `hasMoreOlder`（或等价）；废弃「highestPageLoaded 表示 list 页深」作为 loadMore 主依据。下拉刷新：可再次一次 7 日 filter 替换近窗并保留已 loadMore 的更旧 id（或整表重种子——实现选较简单且正确的一种，design 倾向：**force 种子替换窗内、保留 startTime 严格早于窗起点的更旧行**）。
- **备选**：每次下拉清空更深页——用户已滚出的更旧丢失，差。
- **理由**：时间游标与 page 计数正交。

### D6：副作用 HTTP

- **选择**：种子与 loadMore 均 single-flight、失败熔断、自触发 ignore；provider 创建不得自动狂拉。对齐 `project.md` 副作用 HTTP 治理。

## Risks / Trade-offs

- [7 日 >500 截断致预测样本偏新] → 产品已接受；Debug 可打 truncated；极端宝宝再议升 limit（Go）。
- [LTE 边界重复] → `endTime−1` + id 去重。
- [排序 id DESC vs start_time 游标] → 游标按 start_time；极端时钟回拨靠去重与 hasMore 空页结束。
- [基线仍写 widget 必读 range] → 本变更 delta 改为读统一池；实现时改 sync/注释。
- [首屏列表远多于 20 条] → 预期；UI 虚拟列表已有则无新问题。

## Migration Plan

1. 实现池种子 + loadMore 游标；预测改读池；主壳只触发一种远端种子。
2. 删除 range ensure 调用链与合并 home∪range 的重复 HTTP。
3. 回归：冷启动近窗、下拉更旧、WS 增删、切号擦除、预测/widget 与喂养一致。
4. 回滚：恢复双 provider（客户端版本回退）；无服务端迁移。

## Open Questions

1. ~~loadMore 游标形态~~（已定：时间游标）。
2. ~~>500~~（已定：截断）。
3. 下拉刷新是「整池重种子」还是「只刷新 7 日窗、保留更旧」——默认 D5 后者；实现若过复杂可简化为整表重种子并在 tasks 注明。
