## Context

- 网关历史 WS（`gateway_app_history_ws.go`）auth 首帧校验 JWT 内 `device_no`；为空则返回 `未绑定设备，无法订阅历史推送`，与客户端 auth 帧里的 `deviceNo` 无关。
- 登录响应无 `deviceNo` 时 JWT 不含 `device_no`；`bindwx` / `auto_save` 仅更新 DB 与本地 prefs，不自动换 token。
- `ensureFreshSession()` 仅在 access 将过期（默认 5 分钟内）时才 refresh，绑定后短期内不会 refresh。
- `token/refresh` 会 `FetchDeviceNoByWxID` 并签发含最新 `device_no` 的 access（`gateway_app_ctrl.go` TokenRefresh）。
- 历史 WS 已有 `HistoryWsPhase`（`ready` / `autoReconnecting` / `gaveUp` / `disconnected`）与 3-strike gave-up；`home_screen` 在 `!_wsReady` 时展示横幅，含「正在重连…」。
- 绑定已有宝宝时 `WxBindDevice` → `EnsureRegistered` 失败返回 `设备未注册，请先注册设备号`，经 envelope 原样 Toast。

## Goals / Non-Goals

**Goals:**

- 绑定宝宝后会话 JWT 与 DB 绑定状态一致，历史 WS 可立即订阅。
- 自动/静默重连不打扰用户；仅在真正失败或需点击重连时展示横幅。
- 用户侧错误文案统一为「宝宝ID」语义。

**Non-Goals:**

- 不修改 go_ai_talk 网关 WS 鉴权逻辑或服务端错误字符串（客户端做映射即可）。
- 不改变 heartbeat、3-strike、重连退避算法本身。
- 不在本变更中新增自动化测试文件。

## Decisions

1. **绑定后强制 refresh**
   - `baby_bind_screen` 在 `setLocal` 之后、`reconnectHistoryWebSocket` 之前调用 `SessionController.trySilentRefresh()`（或新增 `refreshSessionAfterDeviceBind()` 封装：强制 refresh + 失败 Toast）。
   - `feedRepositoryProvider` 的 `deviceNo` listener 重连前同样走「必要时 refresh」路径，避免重复实现可提取 `ensureAccessTokenMatchesDeviceNo(ref)`  helper。

2. **建连前 JWT 与本地 deviceNo 对齐**
   - 在 `RemoteFeedRepository._prepareAccessTokenForConnect` 中：若 `_deviceNoGetter()` 非空且 JWT payload 无 `device_no`（或为空），**必须** 调用 `trySilentRefresh()`（不受 5 分钟 buffer 限制），失败则中止建连并提示重新登录或绑定。
   - 解析 JWT 复用/扩展 `token_expiry.dart`（如 `readJwtDeviceNo`），避免散落 decode 逻辑。

3. **横幅可见性**
   - `showWsDisconnectBanner = loggedIn && !needsDeviceBind && !_wsReady && _historyWsPhase != HistoryWsPhase.autoReconnecting`
   - `gaveUp` 与 `disconnected`（且非 autoReconnecting）仍展示对应文案；移除或不再使用「正在重连…」作为用户可见主路径（常量可保留供调试）。
   - 用户手动点击横幅重连时，允许本地 loading 态，但**不必**展开全宽横幅文案切换（可选按钮 loading）。

4. **错误文案映射**
   - 集中函数 `normalizeUserFacingApiMessage(String raw)`：匹配「设备未注册」「请先注册设备号」等 → **「宝宝ID未绑定」**；可扩展 WS error message 映射表。
   - 应用于 `ApiClient` 抛错前或 `showApiToastError` 入口，避免各页面重复。

## Risks / Trade-offs

- **[Risk] 频繁 refresh 增加网关负载** → 仅在「本地有 deviceNo 且 JWT 无 device_no」或「绑定成功回调」时强制 refresh，正常已对齐会话不受影响。
- **[Risk] refresh 失败（网络）导致绑定后仍连不上 WS** → Toast 明确提示，保留横幅手动重连；strike reset 仍在 bind 成功路径执行。
- **[Risk] 隐藏 autoReconnecting 横幅使用户不知后台在重连** → 产品接受；失败态 gaveUp/disconnected 仍会提示。
- **[Trade-off] 服务端原文仍含「设备」** → 仅用户 Toast 映射，日志与联调仍可见原文。

## Migration Plan

1. 实现 token sync + 横幅 + 文案映射。
2. 手测：新注册/Apple/用户名登录 → 绑定已有宝宝 ID → WS 就绪无错误 Toast；切后台回来仍就绪。
3. 手测：输入不存在宝宝 ID → Toast「宝宝ID未绑定」。
4. 手测：断网触发 gaveUp → 横幅可见；恢复网络自动重连过程中横幅不闪现「正在重连…」。

## Open Questions

- 手动点击「重连」进行中是否完全隐藏横幅（当前倾向：保持横幅可见以便可再次点击，仅 suppress autoReconnecting 自动阶段）。
