## 1. Token 对齐逻辑

- [x] 1.1 修改 `session_device_token_sync.dart`：`jwtDn` 为空或与 `localDeviceNo` 不等时调用 `refreshSessionForDeviceBind()`；成功后校验 `readJwtDeviceNo == localDeviceNo`
- [x] 1.2 确认 `_prepareAccessTokenForConnect` 经 `ensureAccessTokenHasDeviceNo` 自动获得一致性强校验，无需重复逻辑；refresh 后仍不等时返回 null 并保留现有 Toast

## 2. 绑定流程顺序

- [x] 2.1 调整 `baby_bind_screen.dart` `_bind`：API 成功后先 `ensureAccessTokenHasDeviceNoFromWidget(localDeviceNo: no)`，成功后再 `setLocal` / `invalidate` / `reconnectHistoryWebSocket`
- [x] 2.2 调整 `_create`：与 `_bind` 相同顺序（先 token 对齐，再 `setLocal`）
- [x] 2.3 token 对齐失败时不得 `setLocal`、不得 `pop(true)`，保留「会话刷新失败」Toast

## 3. 其他绑定入口

- [x] 3.1 `remote_auth_repository.bindUsernameDevice`：API 成功后先 `ensureAccessTokenHasDeviceNo`（传入 normalized deviceNo），成功后再 `setLocal`

## 4. 验证

- [ ] 4.1 手工：登录后 JWT 无 `device_no`，绑定新宝宝 → 历史 WS `auth_ok`，无「device_no 与 token 不一致」Toast
- [ ] 4.2 手工：登录响应带宝宝 A，切换绑定宝宝 B → 绑定后 WS 就绪，JWT `device_no` 为 B
- [ ] 4.3 手工：绑定成功但断网模拟 refresh 失败 → 不写入本地 B，Toast 失败，可重试
- [x] 4.4 确认未修改 `unify-ucg-wxid-api-alignment` 安全区（`RemoteFeedRepository` 仅经共享 helper 增强，无 UCG/网关契约变更）
