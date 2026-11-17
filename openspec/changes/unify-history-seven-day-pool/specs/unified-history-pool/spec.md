## ADDED Requirements

### Requirement: Client SHALL use one shared history pool for feeding and prediction

The client MUST maintain a single in-memory history pool as the source of truth for the feeding history list, smart-prediction inputs (including affinity / progress), and desktop-widget prediction sync that today consume `homeHistory` and/or `predictionRangeHistory`. After this change, the client MUST NOT run a separate remote ensure that re-fetches the same near window solely for prediction while feeding already holds that window. 客户端 MUST 以单一内存历史池作为喂养列表、智能预测与桌面 widget 预测的同源输入；MUST NOT 在喂养已持有近窗时再为预测单独远端重拉同一近窗。

#### Scenario: Prediction reads the shared pool

- **WHEN** the smart prediction page or widget sync builds `predictAllUpcoming` (or equivalent) inputs
- **THEN** the history records MUST come from the shared pool (or a local slice of it)
- **AND** MUST NOT require a second successful near-window HTTP fetch that duplicates the pool’s seven-day seed

#### Scenario: Feeding list reads the same pool

- **WHEN** the feeding page renders history rows
- **THEN** the rows MUST come from the same shared pool instance updated by seed, loadMore, and History WebSocket upserts/removes

### Requirement: Shell seed SHALL be one seven-day filter call

When the user is logged in and `deviceNo` is available after home-shell mount (not during Splash await), the client MUST seed the shared pool with exactly one `GET /device/history/api/filter` for the local seven-day window (`today-6d 00:00` through now, same bounds as today’s prediction range) with `limit` at most 500. The seed path MUST NOT chain `v2/list` (or additional filter pages) to backfill when the response length equals the limit. If the response length equals 500, the client MAY treat the window as truncated and MUST still mark the seed complete for UI purposes. 登录且 `deviceNo` 可用后（非 Splash await），MUST 以**一次**近 7 日 `filter`（limit≤500）种子；触顶 MUST NOT 连环 `v2/list` 补页；500 条时 MAY 视为截断且 MUST 仍结束种子态。

#### Scenario: Cold seed is a single filter

- **WHEN** the home shell triggers remote history seed for a bound device
- **THEN** the client MUST issue one seven-day `filter` request
- **AND** MUST NOT issue follow-up `v2/list` pages as part of that seed

#### Scenario: Splash does not await seed HTTP

- **WHEN** Splash performs local-only bootstrap into `/home`
- **THEN** the client MUST NOT await the seven-day filter seed as a gate to leave Splash

### Requirement: Feeding loadMore SHALL use a time cursor for older records

When the user pulls to load more older feeding history, the client MUST request records strictly older than the oldest `startTime` already in the shared pool by setting `endTime` to that instant minus one second (Unix seconds) and a small positive `limit` (e.g. 20), using `filter` or `v2/list` time-bound APIs. The client MUST merge results by record id (dedupe) into the shared pool. The client MUST NOT re-run the seven-day window filter as the loadMore primary path, and MUST NOT use v1 `list?page=N` as the primary loadMore path after the seven-day seed is the pool’s near-window source. 下拉加载更多 MUST 以「池内最旧 startTime−1」为 `endTime` + 小 limit 续更旧并 id 去重；MUST NOT 以再拉近 7 日或 v1 页码作为主路径。

#### Scenario: LoadMore fetches older than pool

- **WHEN** the pool has at least one record with a known `startTime`
- **AND** the user triggers loadMore
- **THEN** the request MUST use `endTime` equal to the oldest pool `startTime` minus 1 second
- **AND** returned ids already in the pool MUST NOT create duplicates

#### Scenario: Empty older page ends hasMore

- **WHEN** a time-cursor loadMore returns an empty list
- **THEN** the client MUST treat further older pagination as exhausted (`hasMoreOlder` false or equivalent)

### Requirement: History WebSocket and wipe SHALL target the shared pool

While the home shell session is active, History WebSocket create/update/delete MUST upsert/remove into the shared pool (same single application-level consumer rule as today’s `homeHistory`). Account switch / deregistration wipe MUST clear the shared pool and its disk snapshot so the next session cannot see the previous account’s records. 主壳会话内 History WS MUST 写入统一池；切号/注销擦除 MUST 清空该池与磁盘快照。

#### Scenario: WS upsert lands in one pool

- **WHEN** a History WebSocket create/update arrives during an active home shell session
- **THEN** the shared pool MUST reflect the upsert
- **AND** both feeding UI and prediction readers MUST see the update without a second HTTP seed

#### Scenario: Wipe clears pool

- **WHEN** the user confirms switch-account or successful deregistration wipe
- **THEN** the shared pool in memory and on disk MUST NOT retain the previous account’s history rows
