## MODIFIED Requirements

### Requirement: 刷新最新一页

The client SHALL refresh page 1 on explicit pull-to-refresh when not loading more, **or** when the user completes a bottom upward-pull refresh per the bottom-pull requirement, replacing the in-memory snapshot with the newest page while preserving WebSocket merge rules for subsequent updates and preserving unflushed `pending:*` rows per existing merge rules. This **replace-with-page-1** behavior applies to those **explicit user gestures** (and any documented equivalent user-initiated newest-page refresh). It MUST NOT be the sole behavior used when App resume / `bootstrap` refreshes feeding history after older pages were already loaded; that path MUST follow the preserve-depth merge requirement below.

非「加载更多」的**顶部下拉**刷新，或符合「底部上拉刷新」条件的交互，MUST 重新拉取 **第 1 页**（20 条）并更新「最新一页」快照（保留 pending 合并与 WS 后续规则）。该**整表替换为最新一页**语义适用于上述**显式用户手势**；App resume / bootstrap 在已加载更深页后的刷新 MUST NOT 仅用本条整表替换，而 MUST 走下方「保留深度合并」要求。

#### Scenario: 下拉刷新非触顶加载更多

- **WHEN** 用户在列表**顶部**下拉刷新且不满足「触顶加载更多」条件，或已无更多页
- **THEN** 客户端 MUST 请求 `page=1&pageSize=20` 并刷新最新数据
- **AND** MAY 将内存快照替换为该最新一页（加 pending 合并规则）

#### Scenario: 底部上拉刷新最新

- **WHEN** 用户按「底部上拉 SHALL 刷新最新一页」完成有效上拉刷新
- **THEN** 客户端 MUST 请求 `page=1&pageSize=20` 并刷新最新数据
- **AND** 行为 MUST 与顶部非 loadMore 的 refresh 使用同一显式刷新实现（可整表替换最新一页）

## ADDED Requirements

### Requirement: Resume or bootstrap home refresh SHALL merge page 1 without dropping loaded older pages

When home history remote refresh is triggered by App resume bundle or by `bootstrap` (including deviceNo-change bootstrap) and the in-memory (or just-hydrated) list already contains records beyond the newest page, the client MUST fetch page 1 and merge remote records by `id` into the existing ascending list, MUST retain local records whose ids are absent from that page-1 response (already-loaded older pages), MUST keep `highestPageLoaded` at least as large as before the merge when it was greater than 1, and MUST NOT set the in-memory list to page-1-only solely due to that refresh. Unflushed `pending:*` rows MUST remain subject to existing pending-merge rules. Explicit gesture newest-page refresh remains governed by「刷新最新一页」and MAY replace with page 1.

由 resume / bootstrap 触发的 home 远端刷新，在已有更深页时 MUST 合并 page 1 并保留不在 page 1 中的本地更旧记录，MUST NOT 仅因此收成 page1-only；`highestPageLoaded>1` 时 MUST 保持深度。显式手势刷新仍可整表替换。

#### Scenario: bootstrap 保留 loadMore 深度

- **WHEN** 内存已 `highestPageLoaded >= 2` 且含第 1 页以外记录
- **AND** `bootstrap`（或 resume 调用的等价刷新）成功拉取 page 1
- **THEN** 合并后列表 MUST 仍包含那些不在 page 1 响应中的更旧 id
- **AND** `highestPageLoaded` MUST NOT 被降为 1

#### Scenario: 仅有第 1 页时与今日等价

- **WHEN** 刷新前 `highestPageLoaded <= 1` 且无更深页记录
- **AND** resume/bootstrap 成功拉取 page 1
- **THEN** 结果 MUST 等价于以 page 1（加 pending 规则）更新最新快照
