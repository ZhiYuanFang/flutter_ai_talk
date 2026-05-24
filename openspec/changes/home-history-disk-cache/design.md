## Context

- **现状**：`HomeScreen._items` 初始为空；`_reloadHistoryIfLoggedIn` → `FeedRepository.loadHistory()` 直连 `GET /device/history/api/list`（`page=1`, `pageSize=50`）。`RemoteFeedRepository` 仅在内存 `_cache` 保留最近一次拉取结果，无磁盘层。
- **参照**：`EventCatalogNotifier.loadFromDisk` + `EventCatalogSync.refreshAndPersist` + `catalogSnapshotsEqual` 已是成熟的 cache-first 模式。
- **衍生 UI**：`aggregateTodayTotals(_items)`、历史时间线、绑定 banner 与列表空态均依赖 `_items`；缓存命中可立即稳定首屏。

## Goals / Non-Goals

**Goals:**

- 冷启动/回主页：有缓存则 **立即** 展示历史列表与今日 chips，避免空白闪烁。
- 后台异步刷新；远端与本地不一致时更新 UI 与磁盘。
- 按 **`deviceNo`** 隔离缓存；登出不清磁盘（下次同宝宝登录可复用）。
- WS/SSE 推送、本地 stop/update 成功后回写磁盘，减少下次冷启动漂移。

**Non-Goals:**

- 离线无限滚动或分页合并（仍只缓存第一页 50 条）。
- 替换 WS 实时更新机制。
- Web 端特殊策略变更（Web 可沿用同一 Store；若 `path_provider` 不可用则仅内存，与 event catalog 一致）。

## Decisions

1. **存储位置与键**  
   - 文件：`{appDocuments}/home_history/history_{deviceNo}_v1.json`  
   - `deviceNo` 经 `safeFileStem` 消毒；无 `deviceNo` 跳过读写。

2. **序列化格式**  
   - JSON 数组；每项存 `HistoryRecord` 的 `id`、`createdAt`（ISO8601）、`eventName`、`action`、`rawPayload`（Map）。  
   - 读盘时用与 `historyRecordFromServerMap` 等价的字段还原，避免丢失 `eventId`/`eventNumber` 等 update 所需字段。

3. **快照对比 `historySnapshotsEqual`**  
   - 长度 + 按 `id` 对齐比较：`eventName`、`action`、`rawPayload` 中 `startTime`/`endTime`/`eventNumber`/`remark`/`eventId`（与列表展示及计时判定相关）。  
   - 顺序差异视为不等（列表 API 顺序有语义：首页 reverse 展示）。

4. **加载流程（HomeScreen）**  
   ```text
   _reloadHistoryIfLoggedIn():
     if !loggedIn → _items = []
     if !deviceNo → _items = [] (或保留当前)
     cached = await HomeHistoryStore.load(deviceNo)
     if cached non-empty → setState(_items = cached asc order)
     remote = await feed.loadHistory() // 现有 API
     if remote fetch failed → keep cached UI
     if !historySnapshotsEqual(cached, remote) → save disk + setState
   ```  
   - 列表升序规则不变：`list.reversed.toList()` 与现网一致。

5. **刷新入口**  
   - `_init`、登录态/`deviceNo` 变化监听：均走统一 `_reloadHistoryIfLoggedIn`。  
   - 不在每次 `build` 拉接口。

6. **WS/SSE 后回写**  
   - `watchLatest` 合并 `_items` 后 `unawaited(HomeHistoryStore.save(deviceNo, _items))`。  
   - `_stopActiveTimer` 本地更新成功后同样回写。  
   - 防抖可选（首版每次变更即写，数据量 ≤50 可接受）。

7. **失败与空缓存**  
   - 无缓存 + 接口失败 → 空列表（与现网一致）。  
   - 有缓存 + 接口失败 → 展示缓存，可选 debugPrint，不 Toast（避免进主页即报错）。

8. **与 FeedRepository 边界**  
   - 磁盘层在 UI/Store；`loadHistory()` 保持纯远端语义，HomeScreen 编排 cache-first。  
   - 或抽 `HomeHistorySync` 封装 load+compare+persist，供 HomeScreen 调用。

## Risks / Trade-offs

- **[Risk] 缓存与 WS 竞态** → 远端 refresh 完成前 WS 已更新：refresh 结果覆盖 WS 中间态；refresh 后 WS 继续增量。首版可接受；必要时 refresh 完成后合并而非盲覆盖。  
- **[Risk] 多设备切换** → 必须按 `deviceNo` 分文件；切换时先读新 device 缓存再 refresh。  
- **[Trade-off] 仅 50 条** → 与线上一致；超出部分仍依赖进主页后 WS/手动刷新。

## Migration Plan

- 首版发版无本地文件 → 行为与现网相同（等 API）；第二次进入即有缓存。  
- 回滚：移除 Store 调用，恢复纯 API 加载。

## Open Questions

- （已决）范围：主页历史 list + 今日汇总（由 `_items` 衍生），不含趋势。  
- （待实现验证）refresh 与 WS 并发时是否需版本号/时间戳 — 首版以最后一次 successful save 为准。
