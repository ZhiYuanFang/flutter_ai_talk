## ADDED Requirements

### Requirement: Depth-preserving home refresh MUST persist the full merged snapshot

When home history is refreshed with the preserve-loaded-depth merge (resume / bootstrap path) and the merged in-memory list still contains records beyond page 1, the client MUST persist that full merged snapshot (items + `highestPageLoaded` reflecting retained depth) for the active `deviceNo`. The client MUST NOT overwrite disk cache with a page-1-only snapshot solely because of that depth-preserving refresh. Explicit gesture newest-page refresh MAY continue to persist a page-1-centric snapshot per existing refresh semantics.

保留深度的 home 刷新成功后，客户端 MUST 将完整合并快照（含更深页与对应 `highestPageLoaded`）按 `deviceNo` 落盘；MUST NOT 仅因该路径用 page1-only 覆盖更深磁盘缓存。显式手势刷新最新一页 MAY 仍按既有语义落盘。

#### Scenario: resume 合并后磁盘仍含更深页

- **WHEN** resume/bootstrap 以保留深度模式合并 page 1 成功，且内存仍含 page 1 以外记录
- **THEN** 客户端 MUST 将含这些更旧记录的快照写入该 `deviceNo` 磁盘缓存
- **AND** 下次冷启动 hydrate MUST 能恢复这些更深记录（在未被显式 page1 替换刷新覆盖之前）

#### Scenario: 手势整表刷新仍可瘦快照

- **WHEN** 用户显式下拉/底部上拉以整表替换为最新一页并成功
- **THEN** 客户端 MAY 将磁盘快照更新为该最新一页（加 pending 规则）语义
