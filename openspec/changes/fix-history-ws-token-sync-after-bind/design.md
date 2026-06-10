## Context

历史 WebSocket 鉴权帧为 `{ type: auth, accessToken, deviceNo }`（camelCase）。服务端校验帧内 `deviceNo` 与 JWT `device_no` claim 一致。当前客户端在 `session_device_token_sync.dart` 中，若 JWT **已有任意非空** `device_no` 即提前返回，不比对是否与本地 `deviceNo` 相等；绑定页在 `setLocal` 之后才对齐 token。`feedRepositoryProvider` 监听 `deviceNoNotifierProvider`，`setLocal` 广播后立即 `reconnectHistoryWebSocket`，形成「新 deviceNo + 旧 JWT」的竞态，触发 `device_no 与 token 不一致`。

基线 `openspec/specs/v1.0.1.md` 已规定绑定后须 refresh 且 JWT 与本地一致；本设计为实现补齐，不修改网关协议。

## Goals / Non-Goals

**Goals:**

- 绑定/创建/胖宝号绑定成功后，历史 WS 鉴权不再因 JWT 与本地 `deviceNo` 不一致而失败
- `ensureAccessTokenHasDeviceNoForSession` 与 `_prepareAccessTokenForConnect` 在 **缺失或不一致** 时均触发 refresh，并在 refresh 后校验相等
- 消除 `setLocal` 与 token 对齐之间的竞态（绑定流程先对齐 token 再更新本地并触发重连）
- 保持 `resetStrike`、refresh 失败 Toast 等既有行为

**Non-Goals:**

- 修改 `gateway_app_history_ws.go` 或服务端校验规则
- 重构 `RemoteFeedRepository` 整体重连/backoff 策略
- 变更 `unify-ucg-wxid-api-alignment` 安全区外的喂养 HTTP 契约
- 登录响应已带正确 `deviceNo` 且无切换时的路径（仅确保不回归）

## Decisions

### 1. Token 对齐条件：相等校验而非「有 claim 即通过」

**选择**：`ensureAccessTokenHasDeviceNoForSession` 在 `localDeviceNo` 非空时，若 `readJwtDeviceNo(token)` 为 null、空或与 `localDeviceNo` **不相等**，则调用 `refreshSessionForDeviceBind()`；成功后 **必须** `readJwtDeviceNo == localDeviceNo` 才返回 true。

**理由**：直接落实基线「JWT 已含与本地一致的 device_no 才跳过 refresh」；修复切换宝宝时 JWT 含旧 ID 的漏洞。

**备选**：仅在绑定页无条件 `refreshSessionForDeviceBind()` — 覆盖不全（`bindUsernameDevice`、被动重连路径仍会漏）。

### 2. 绑定流程顺序：先 token 对齐，再 `setLocal`

**选择**：`baby_bind_screen` 的 `_bind` / `_create` 在 API 成功后：

1. `ensureAccessTokenHasDeviceNoFromWidget(ref, localDeviceNo: newNo)`（此时本地 prefs 可仍为旧值，显式传入目标 ID）
2. 失败则 Toast，**不** `setLocal`，**不** pop
3. 成功则 `setLocal(newNo)` → `invalidate(settingsBabyProvider)` → `reconnectHistoryWebSocket(resetStrike: true)`

**理由**：`deviceNoNotifierProvider` 监听在 `setLocal` 时同步触发重连；先对齐 JWT 可保证监听触发的重连与显式重连均使用一致凭证。

**备选**：移除 `repositories.dart` 的 deviceNo 监听 — 会漏掉其他写入 `deviceNo` 的路径（如登录 `_persistLoginData`）。

### 3. 保留 deviceNo 监听 + 建连前二次校验

**选择**：保留 `ref.listen(deviceNoNotifierProvider, …)`；`_prepareAccessTokenForConnect` 继续调用已增强的 `ensureAccessTokenHasDeviceNo`，作为兜底。

**理由**：监听保证登录/绑定后自动重连；建连前校验防止任何遗漏路径发送不一致 auth。

### 4. `bindUsernameDevice` 纳入同一对齐路径

**选择**：`remote_auth_repository.bindUsernameDevice` 在 API 成功后，**先** `ensureAccessTokenHasDeviceNo`（传入 normalized deviceNo），**再** `setLocal`。

**理由**：与 bindwx/auto_save 行为一致，避免用户名通道重绑遗漏。

### 5. Refresh 后仍不一致的处理

**选择**：若 refresh 成功但 JWT `device_no` 仍与目标 `localDeviceNo` 不等，视为失败（返回 false / 不建连 / Toast「会话刷新失败，请重新登录后再试」）。

**理由**：避免无限重试错误 auth；暴露服务端 refresh 未回写 claim 的配置问题。

## Risks / Trade-offs

- **[Risk] 服务端 refresh 未返回新 `device_no`** → 绑定后仍无法连 WS；通过 Toast 与日志 `ws token refresh for device_no failed` 暴露，需后端排查。
- **[Risk] 额外 refresh 调用** → 切换宝宝时多一次 `POST /token/refresh`；可接受，绑定为低频操作。
- **[Trade-off] 绑定失败时本地 deviceNo 不更新** → 若 token 对齐失败，用户需重试或重登；优于写入本地 ID 却 WS 永久报错。

## Migration Plan

纯客户端热修复，无数据迁移。发布后验证路径：

1. 登录后绑定新宝宝（JWT 无 claim）
2. 登录响应带宝宝 A，切换绑定宝宝 B（JWT 含 A）
3. 胖宝号用户名绑定设备
4. 绑定后首页历史 WS banner 消失、`auth_ok` 就绪

回滚：还原 `session_device_token_sync.dart` 与绑定顺序即可。

## Open Questions

- 登录响应若已带正确 `deviceNo` 且用户仅「确认」同一宝宝（无切换），是否仍需绑定页 refresh？当前设计仅在缺失/不一致时 refresh，无额外开销。
- Web 与移动端 SharedPreferences 行为一致，无需分叉；若仍复现需抓 JWT payload 与 `HomeHistoryLog` 时间线。
