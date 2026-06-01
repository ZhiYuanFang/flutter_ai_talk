## Why

主页历史列表（含今日汇总、时间线）目前仅在 `_reloadHistoryIfLoggedIn` 时请求 `GET /device/history/api/list`，冷启动或弱网下首屏长时间空白，布局在「暂无历史记录」与有数据之间跳动。事件目录已实现「先读本地、再异步刷新」模式，主页历史需要对齐同一 **stale-while-revalidate** 体验。

## What Changes

- 新增 **`HomeHistoryStore`**：按 **`deviceNo`** 将最近一页历史列表（与现网 `page=1&pageSize=50` 一致）持久化为本地 JSON。
- 主页进入时：**先加载本地缓存** 渲染列表与今日汇总；**并行**请求服务端最新列表。
- 远端返回后与本地快照 **对比**（按记录 `id` 及关键字段）；有差异则 **覆盖磁盘** 并刷新 UI；无差异则不触发多余重绘。
- 远端请求失败时 **保留缓存展示**，不强制清空列表（与事件目录刷新失败策略一致）。
- 历史 **WebSocket** 推送导致的增删改，在更新内存列表后 **同步写回缓存**（保持下次冷启动一致）。
- 未登录或无 `deviceNo` 时不读不写缓存；切换 `deviceNo` 时加载对应宝宝缓存。

## Capabilities

### New Capabilities

- `home-history-disk-cache`：主页历史列表本地持久化、冷启动 stale-while-revalidate、快照对比与 WS 后回写。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线；与 `feed-history-ws-after-chat`、`home-history-compact-timeline` 等归档变更在消费侧扩展，本变更以新增 capability 完整描述。）

## Impact

- `app/lib/data/home_history_store.dart`（新）、`history_record_serialization.dart` 或 `HistoryRecord` JSON 辅助（新）。
- `app/lib/ui/home_screen.dart`：`_init` / `_reloadHistoryIfLoggedIn` 改为 cache-first + async refresh。
- `app/lib/data/remote_feed_repository.dart` 或独立 `HomeHistorySync`：拉取与对比逻辑（可复用 `loadHistory` 解析）。
- **Out of scope**：趋势页序列缓存、事件目录（已有 `EventCatalogStore`）、扩大 `pageSize` 或改 list API 契约。
