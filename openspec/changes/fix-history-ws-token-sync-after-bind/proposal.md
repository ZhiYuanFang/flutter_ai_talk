## Why

用户在新绑定或切换宝宝后，历史 WebSocket 鉴权报错 `device_no 与 token 不一致`，历史推送无法就绪。根因是客户端在 JWT 已含**旧** `device_no` 时跳过 refresh，且 `setLocal` 触发 Provider 监听立即重连，早于 token 对齐。基线规格 `history-ws-token-sync-after-bind` 已要求绑定后 JWT 与本地 `deviceNo` 一致再连 WS，但当前实现仅处理「JWT 缺 claim」情形，需补齐以消除 spec–实现缺口。

## What Changes

- **`ensureAccessTokenHasDeviceNoForSession`**：当本地 `deviceNo` 非空且 JWT `device_no` **缺失或与本地不一致**时，必须调用 `refreshSessionForDeviceBind()`，并在 refresh 后校验二者相等。
- **绑定/创建流程**（`baby_bind_screen`）：先完成 token 对齐，再触发历史 WS 重连；避免 `setLocal` 触发的抢先重连使用陈旧 JWT。
- **`repositories.dart` deviceNo 监听**：在 token 未与本地 `deviceNo` 对齐前不得发起 WS auth；或改为由绑定流程在 token 就绪后显式重连（去竞态）。
- **`_prepareAccessTokenForConnect`**（`remote_feed_repository`）：建连前同样校验 JWT 与本地 `deviceNo` 一致，不一致则 refresh。
- **`bindUsernameDevice`**（`remote_auth_repository`）：绑定胖宝号后同步走 token 对齐路径（与 bindwx/auto_save 一致）。
- 绑定成功但 refresh 失败时继续 Toast 可理解错误，**不得**假装 WS 已就绪（与既有规格一致）。

## Capabilities

### New Capabilities

（无。）

### Modified Capabilities

- `history-ws-token-sync-after-bind`：明确「JWT 已含但与本地不一致」时必须 refresh；补充切换/重绑宝宝场景；约束 deviceNo 变更触发的 WS 重连不得早于 token 对齐。
- `device-identity`：绑定后 access JWT `device_no` 与持久化宝宝 ID 一致的要求，覆盖「JWT 含旧 claim」而不仅是「JWT 缺 claim」。

## Impact

| 区域 | 路径 |
|------|------|
| Token 对齐 | `app/lib/session/session_device_token_sync.dart` |
| 会话刷新 | `app/lib/session/session_controller.dart`（`refreshSessionForDeviceBind`） |
| JWT 解析 | `app/lib/session/token_expiry.dart` |
| 绑定 UI | `app/lib/ui/baby_bind_screen.dart` |
| WS 建连 | `app/lib/data/remote_feed_repository.dart` |
| Provider 监听 | `app/lib/providers/repositories.dart` |
| 胖宝号绑定 | `app/lib/data/remote_auth_repository.dart` |

**不受影响**：`unify-ucg-wxid-api-alignment` 安全区内的 UCG API；网关 WS 协议与服务端校验逻辑（行为符合既有契约）。

**依赖关系**：实现须对齐 `openspec/specs/v1.0.1.md` 中 `history-ws-token-sync-after-bind` 与 `device-identity` 基线，本 change 以 MODIFIED delta 收紧客户端语义。
