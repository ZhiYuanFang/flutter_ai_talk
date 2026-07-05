## Why

当前喂养按钮路径在**历史 WebSocket 未就绪**时被 `_ensureHistoryWsForSend` 与 `addHistoryEvent` 双重拦截，用户无法记录事件；而乐观 UI（`pending:<uuid>`）与磁盘持久化能力已存在，只是无法完成「先本地、后上传」。母婴场景下 WS 建连可能滞后（登录 bootstrap、iOS 冷却、gaveUp 需手动重连），用户仍应能立即记喂养/停止计时，并在 WS 连上后**静默**同步。

## What Changes

- **移除按钮 add 的 WS 门闩**：`_onEventButtonTap` 不再调用 `_ensureHistoryWsForSend`；`addHistoryEvent` 在 WS 未就绪时不 Toast、不 rollback，改为入队。
- **历史 Outbox**：`pending:*` 行即 ADD 队列投影；已落库记录的 time 型 **stop/update** 写入独立 UPDATE outbox（按 `deviceNo` 落盘）。
- **WS ready 触发 flush**：`isHistoryWebSocketReady` 上升沿（含冷启动恢复 pending 后首次 ready）single-flight FIFO flush；**不得**在 provider 构造时自动 flush。
- **失败语义**：传输/网络失败 → 保留 outbox，**静默**，等**下一次 WS 连上就绪**再试；`ApiBusinessException`（含额度/登录等业务码）→ Toast，ADD 失败移除 pending，UPDATE 失败回滚本地 optimistic 并保持进行中。
- **pending 可 stop**：WS 未就绪时对 `pending:*` 进行中计时允许停止；本地改 `endTime`，flush 时合并为一条 ADD（不单独 UPDATE pending id）。
- **gaveUp 可本地写、不可 flush**：直到用户点横幅重连且 WS ready（产品已接受）。
- **AI 语音/文字不变**：`_ensureHistoryWsForSend` 仍用于 `sendCommand` 路径。
- **edit sheet 全量保存**：首版不在 scope（仅列表 stop + time 型 update outbox 路径）。

## Capabilities

### New Capabilities

- `history-outbox-flush`：Outbox 存储、WS ready 调度、ADD/UPDATE flush 顺序、失败分类、登出/换宝宝清理、与 `HomeHistoryNotifier` 的 id 替换协作。

### Modified Capabilities

- `home-event-optimistic-add`：由「乐观后立即并行 add HTTP」改为「WS 未就绪延迟 flush」；修订 pending 期间禁止 stop 的 Requirement；add 网络失败改为保留 pending 直至下次 WS ready。
- `side-effect-http-governance`：outbox flush 须 single-flight、不得 provider 构造触发、网络失败不 Toast 重试环。

## Impact

- **Dart**：
  - `app/lib/data/remote_feed_repository.dart` — 移除 add 的 WS 硬门闩；暴露/委托 outbox flush
  - 新增 `app/lib/data/history_outbox_store.dart`（或等价）— UPDATE 队列落盘
  - 新增 `app/lib/data/history_outbox_flusher.dart` — 监听 `historyWsReadyStream` rising edge
  - `app/lib/ui/home_screen.dart` — 按钮路径去 WS gate；`_stopActiveTimer` 支持 pending + 离线 update
  - `app/lib/ui/home_history_scroll.dart` — pending 行启用 stop 按钮（WS 未就绪时）
  - `app/lib/providers/home_history_notifier.dart` — flush 成功后 replace；登出清理 hook
- **基线对照**：v2.0.3 `home-event-optimistic-add`、`ResilientWebSocketClient` / `isHistoryWebSocketReady`、副作用 HTTP 治理；**不**改 UCG WS、诊疗 WS、语音 ASR WS。
- **Debug**：新增 outbox tag 时须 `AppDebugLog` 三联改（若实现阶段加日志）。
- **Release**：无 Android 原生改动预期；若有 store 路径变更仍须 release 构建通过。
