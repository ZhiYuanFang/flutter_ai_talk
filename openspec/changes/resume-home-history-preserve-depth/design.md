## Context

主壳 `UcgHomeShell` 在已登录 `resumed` 时执行 resume HTTP bundle：`homeHistory.bootstrap()`（`loadFromDisk` + `refreshFromRemote`）与 `predictionRangeHistory.ensureLoaded(force: true)` 等并行。

今日 `refreshFromRemote` 无论调用来源，成功后都将 `items` 设为「远端 page1 ∪ 本地 pending」、`highestPageLoaded = 1`，并常把该瘦快照 `saveSnapshot`。`mergeRemoteHistoryAscWithPendingLocal` **只保留 pending:***，不保留已 loadMore 的更旧页。久后台回前台后预测并集变瘦，窗外根丢失窗口 lastAt，表现为「缓存丢了」；杀进程后 tip/其它路径可能又显得「回来了」。

显式喂养下拉/底部上拉仍需要「刷新最新一页」整表替换语义（`home-history-pagination`）。

## Goals / Non-Goals

**Goals:**

- Resume / bootstrap 拉 page1 时 **合并进现有深度**，保留 `highestPageLoaded > 1` 时的更旧条目。
- 该路径落盘保留深度，禁止 page1-only 覆盖更深快照。
- 手势「刷新最新一页」行为不变（整表替换 page1 + pending）。
- 继续 force range；single-flight / 副作用治理不变。

**Non-Goals:**

- 改 tip / `event-last-at-cache` 算法（resume 不再砍窗后症状应消失；tip 加固另案）。
- Resume 改为只刷 range、不动 home（方案 B）。
- 服务端删除的旧页记录在本地更深页的主动对账（手势全量替换或 WS delete 仍可收敛）。
- 新建 `**/test/**`（除非用户另行要求）。

## Decisions

### D1：刷新分模式

- **选择**：`refreshFromRemote({bool preserveLoadedDepth = false})`（或等价双方法）。
  - `preserveLoadedDepth: false`（默认）：现网手势路径——page1 + pending，`highestPageLoaded = 1`，可瘦落盘。
  - `preserveLoadedDepth: true`：resume/bootstrap——page1 upsert 进现有 list，保留不在 page1 中的更旧 id，`highestPageLoaded = max(旧, 1)`，整表落盘。
- **理由**：单一 HTTP（page1）服务两种产品语义；避免手势与 resume 抢同一「砍窗」行为。
- **备选否决**：resume 完全不调 home 刷新（B）——与「回前台要对齐最新喂养」冲突过大。

### D2：保留深度的合并算法

纯函数（示意）：

1. `remoteAsc` = page1 升序；`localAsc` = 当前内存（或 warm 后）升序。
2. 以 `remoteAsc` 中 id 为「最新页集合」：用远端记录覆盖同 id 本地行。
3. 保留 `localAsc` 中 **id 不在最新页集合** 的条目（即更深页 / 窗外相对 page1 的记录）。
4. 再并入既有 `pending:*` 规则（未 flush 且不在 remoteIds）。
5. 结果按发生时刻升序稳定排序（与现网一致）。
6. `highestPageLoaded`：若合并前 `> 1` 则保持；否则为 1。`total` 取远端 `total`。

- **理由**：不猜测「哪些是 page2」，只按 id 集合保留「不在本轮 page1 响应里的本地行」。
- **备选否决**：按时间截断「只留早于 page1 最旧条」——与 id 去重 / 改时间记录更脆。

### D3：谁传 preserve 标志

- `bootstrap()`（含 resume、deviceNo 变更 bootstrap）：`preserveLoadedDepth: true`。
- 喂养 `HomeHistoryScroll` / 底部上拉：`false`（默认）。
- 冷启动 `ColdStartBackgroundSync` 若调 `refreshFromRemote`：若磁盘已有多页，应用 `true`，避免冷启第一次远程就把深度砍掉；若仅有 page1 缓存则结果与今日等价。

### D4：磁盘

- `preserveLoadedDepth: true` 且合并成功：`saveSnapshot` 写入 **完整合并 items** + 保留的 `highestPageLoaded`。
- `false`：可继续今日 page1 快照语义（与「刷新最新一页」一致）。

### D5：与 range / tip

- Resume 仍 `ensureLoaded(force: true)`。
- 不依赖 tip 修复本 bug；砍窗修复后 tip 仍作窗外兜底。

## Risks / Trade-offs

- [更深页含服务端已删记录] → 手势全量刷新或 WS delete 收敛；resume 优先保预测/展示连续性。
- [列表变长、内存] → 深度仍受用户曾 loadMore 上限约束，可接受。
- [bootstrap 与手势并发] → 既有 `_refreshFuture` single-flight；后完成者覆盖时须带同一 mode 或文档约定「进行中以先入模式为准」。
- [旧磁盘已是 page1-only] → 无法凭空恢复曾被覆盖的深度；用户需再 loadMore；本变更防止再次覆盖。

## Migration Plan

- 纯客户端；无服务端迁移。
- 回滚：resume 改回 `preserveLoadedDepth: false` 即可。

## Open Questions

- （无）方案 A 已确认：resume 合并保留深度；手势仍可整表替换。
