## 1. 会话 token 与 JWT 解析

- [x] 1.1 在 `token_expiry.dart`（或同级）新增 `readJwtDeviceNo(accessToken)`，解析 JWT payload 的 `device_no` / `deviceNo`
- [x] 1.2 在 `SessionController` 新增 `refreshSessionForDeviceBind()`（或等价）：无条件调用 `trySilentRefresh()`，供绑定后与 WS 建连前使用
- [x] 1.3 新增 `ensureAccessTokenHasDeviceNo(WidgetRef/Ref)` helper：本地 deviceNo 非空且 JWT 无 device_no 时强制 refresh

## 2. 绑定后 token 同步与 WS 重连

- [x] 2.1 `baby_bind_screen.dart`：`_bind` / `_create` 在 `setLocal` 后调用 refresh helper，再 `reconnectHistoryWebSocket(resetStrike: true)`
- [x] 2.2 `RemoteFeedRepository._prepareAccessTokenForConnect`：建连前调用 ensure helper，确保 JWT 含 device_no
- [x] 2.3 确认 `feedRepositoryProvider` 的 `deviceNo` listener 重连路径同样受益（经 `_prepareAccessTokenForConnect` 或显式 refresh）

## 3. 用户可见错误文案映射

- [x] 3.1 新增 `normalizeUserFacingApiMessage`（如 `app/lib/api/gateway_user_message.dart`）：「设备未注册」「请先注册设备号」→「宝宝ID未绑定」；WS「未绑定设备，无法订阅历史推送」→宝宝语义
- [x] 3.2 在 `ApiClient` 业务失败或 `showApiToastError` / `RemoteFeedRepository._toast` 统一经映射后再展示

## 4. 历史 WS 横幅：自动重连期间隐藏

- [x] 4.1 `home_screen.dart`：调整 `showWsDisconnectBanner`，`historyWsPhase == autoReconnecting` 时不展示横幅
- [x] 4.2 更新 `_historyWsBannerMessage` / `HomeHistoryWsStatusBanner` 调用，移除「正在重连…」作为用户可见主路径（常量可保留）
- [x] 4.3 确认 `gaveUp` 一次性 Snackbar 与 disconnected 横幅在 non-autoReconnecting 时仍正常

## 5. 验证

- [x] 5.1 手测：新账号登录 → 绑定宝宝 ID → WS 就绪、无「未绑定设备」Toast
- [x] 5.2 手测：绑定不存在 ID → Toast「宝宝ID未绑定」
- [x] 5.3 手测：断网恢复过程中不出现「正在重连…」横幅；gaveUp 后仍可见失败横幅
- [x] 5.4 运行 `openspec validate fix-history-ws-after-baby-bind --strict`
