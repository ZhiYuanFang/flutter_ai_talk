## Why

本机按钮添加喂养事件采用「乐观 `pending:*` 入列 + 后台同步」时，History WS 回包与飞入抑制共用门闩，导致成功添加后常常**从不触发**小贴士 SSE；同时 outbox / 乐观路径增加了离线与 WS 耦合复杂度。产品改为：**先 HTTP 成功再入列 + tip**（不飞入），**飞入归 History WS**；并**删除 outbox**；按钮操作不依赖 History WS 连接态；语音球仍在按住/发送时校验 History WS，且 gaveUp 横幅仅在语音模式展示。

## What Changes

- **BREAKING（相对基线 `home-event-optimistic-add`）**：按钮路径取消乐观插入；改为 `POST /device/history/api/event/add` **成功后**以服务端 id **瞬间插入**历史列表并 tip；**HTTP 不飞入**；请求进行中禁用会触发添加的按钮入口；离线/传输失败不入列，Toast 提示。
- **BREAKING**：彻底删除历史 **ADD/UPDATE outbox** 相关代码与调度（store / flusher / repository 委托 / flush 调用 / Debug tag 三联清理）。
- 按钮添加成功后立刻 `tipProvider.startStreaming`；HTTP 先入列时登记 awaiting，WS create 再飞一次。服务端 tip 1h 限流**不在本变更范围**。
- 小贴士面板 `done` 态须正确渲染 Markdown（含 `##` 标题），复用陪伴同源 `ClinicAnswerBody`（修布局/状态缺陷若有）。
- History WS：按钮模式操作**不得**以 WS 未就绪拦截；客户端仍尽力建连以同步他端。语音球：**切换不拦**；按住/发送保留 `_ensureHistoryWsForSend`；**gaveUp 横幅仅在语音模式**显示。

## Capabilities

### New Capabilities

- `home-tip-on-feed-add`：本机按钮添加成功后触发 tip SSE；展示态 Markdown（含 `##`）；与服务端限流边界说明。
- `home-history-ws-role-by-input-mode`：按输入模式划分 History WS 门闩与横幅可见性（按钮 vs 语音球）。

### Modified Capabilities

- `home-event-optimistic-add`：由强乐观改为「同步成功后入列」语义（Requirement 级变更 / 实质替换）。
- `home-event-record-fly`：飞入仅由 WS 触发（真正新 id，或本机 HTTP 已入列的 awaiting id）。
- `home-history-ws-status-banner`：gaveUp 横幅增加「当前为语音输入模式」条件。
- `home-button-input-mode`：添加 in-flight 时禁用按钮入口（若基线未覆盖）。

## Impact

- 代码：`home_screen.dart`（`_submitEventAdd`、tip、横幅、`_selectInputChannel` 无关切换门闩）、`home_history_notifier.dart`、`remote_feed_repository.dart` / `feed_repository.dart`、删除 `history_outbox_store.dart` / `history_outbox_flusher.dart`、`app_debug_log` + `logcat_api_http.ps1` + `README`（HistoryOutbox）、`home_tip_panel.dart` / `tip_provider.dart` 注释与触发路径。
- 行为：弱网添加体感变慢（等 RTT）；离线无法添加；他端同步仍靠 History WS。
- 不改：服务端 tip 1h、Android 原生、`**/test/**`（除非用户另要求）。
