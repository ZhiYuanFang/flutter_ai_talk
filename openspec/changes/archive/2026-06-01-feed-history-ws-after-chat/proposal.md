## Why

当前首页在调用 `POST .../device/history/api/chat` 发送对话后，会立刻再请求 **`GET .../device/history/api/list`** 全量刷新列表，与「登录后已建立历史 WebSocket、由服务端推送 create/update/delete 再合并本地缓存」的能力重复，增加延迟与网关负载。目标是以 **WebSocket 推送为写后读（read-your-writes）的主路径**，发消息后不再依赖立刻拉 list 来展示新记录。

## What Changes

- 在用户成功提交聊天文本（`sendCommand` 成功返回）后，**不再**自动触发 `loadHistory()` / 历史 list HTTP 拉取以刷新首页列表（除非设计文档中明确的兜底场景）。
- 首页历史列表的增量更新继续依赖（并强化契约）**已有**的 `RemoteFeedRepository.watchLatest()` WebSocket 流：`create` / `update` / `delete` 事件合并 `_cache` 并驱动 UI。
- **首屏/冷启动**是否仍保留一次 HTTP `list` 拉取作为初始快照（与当前行为一致）在 design 中约定；本变更聚焦「发消息后」路径。
- 若 WebSocket 未连接或推送缺失，是否在 design 中定义**可选兜底**（如延迟单次 list、仅错误时 Toast）以避免列表长期不更新。

## Capabilities

### New Capabilities

- `feed-history-sync`：定义「聊天写操作成功后的列表更新来源」与 WebSocket 事件处理的规范性要求（含 SHALL/MUST 与场景）。

### Modified Capabilities

- （无）仓库根目录 `openspec/specs/` 下暂无已归档能力；本次仅在变更目录内新增规格。

## Impact

- `app/lib/ui/home_screen.dart`：去掉或条件化 `sendCommand` 之后的 `_reloadHistory()`。
- `app/lib/data/remote_feed_repository.dart`（可选）：确保 `watchLatest()` / `_ensureWs()` 在发消息前已建立订阅的时机、或与首页生命周期的关系说明。
- 网关/产品：需确认 `chat` 处理完成后服务端 **必定** 通过历史 WS 下发可解析的 `create`（或等价）事件，否则去掉 HTTP 刷新会导致 UI 短暂或永久缺条。
