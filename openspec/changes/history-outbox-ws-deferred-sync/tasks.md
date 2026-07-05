## 1. Outbox 存储与映射

- [x] 1.1 新增 `history_outbox_store.dart`：按 `deviceNo` 读写 UPDATE FIFO JSON；`enqueueUpdate` / `load` / `removeHead` / `clearForDevice`
- [x] 1.2 新增 helper：`buildEventAddBodyFromPendingRecord(HistoryRecord)`（从 `rawPayload` 构造 add body，禁止 `eventUnit`）
- [x] 1.3 新增 helper：`listPendingAddsInOrder(List<HistoryRecord>)`（过滤 `pending:*` 并保持列表序）

## 2. Flusher 与 Repository

- [x] 2.1 新增 `history_outbox_flusher.dart`：`flushOutbox(Ref/FeedRepository)` single-flight；ADD 序 → UPDATE 序；失败分类（网络静默 / 业务 Toast+回滚）
- [x] 2.2 `RemoteFeedRepository`：移除 `addHistoryEvent` 的 `!isHistoryWebSocketReady` 硬返回；区分网络失败（返回 null 且不 Toast）与业务失败
- [x] 2.3 `RemoteFeedRepository`：订阅 `historyWsReadyStream` 上升沿调用 flusher（与 `watchLatest`/desired 守卫一致）
- [x] 2.4 `FeedRepository` 接口：暴露 `flushPendingHistoryOutbox()` 或等价，供 flusher 与测试路径调用
- [x] 2.5 flush ADD 成功：`homeHistoryProvider.notifier.replaceRecordId`；失败 ADD 业务：`removeById` + toast；UPDATE 业务失败：回滚 `endTime`

## 3. HomeScreen 按钮与 stop 路径

- [x] 3.1 `_onEventButtonTap`：移除 `_ensureHistoryWsForSend`；保留 `_ensureRemoteGate`
- [x] 3.2 `_submitEventAdd`：WS 未就绪时不 `_cancelFlyAndRemovePending`；WS 就绪时保持即时 add + replace
- [x] 3.3 `_stopActiveTimer`：允许 `pending:*`；pending 仅本地 `_recordWithEndTime`；server id + WS 未就绪 → enqueue UPDATE + optimistic
- [x] 3.4 `home_history_scroll.dart`：active timing 的 stop 按钮不再排除 `pending:*`
- [x] 3.5 确认 AI 路径（`_sendVoiceCommand`、文字 send、按住说话）仍调用 `_ensureHistoryWsForSend`

## 4. 生命周期与副作用治理

- [x] 4.1 登出：`home_history_notifier` / session listen 清除 UPDATE outbox 与 pending 行（对齐 spec）
- [x] 4.2 `deviceNo` 变更：flusher 仅 flush 当前 device；不 cross-upload
- [x] 4.3 冷启动：磁盘恢复 pending 后，若 WS 已 ready 触发一次 flush（bootstrap 或 ready 上升沿）
- [x] 4.4 可选 Debug：`AppDebugLog.historyOutbox` + logcat + README 三联改（若实现阶段加日志）

## 6. refresh 与 pending 共存（回归修复）

- [x] 6.1 `mergeRemoteHistoryAscWithPendingLocal`：远端第一页 + 本地 `pending:*` 合并
- [x] 6.2 `_refreshFromRemoteImpl` 全量/空态 replace 使用 merged items 落盘，不得静默删 pending
- [x] 6.3 refresh 完成后若仍有 pending 且 WS ready → `flushPendingHistoryOutbox`

## 5. 手工验收

- [ ] 5.1 WS 未就绪：按钮 add → pending 行 + 动画保留；无错误 Toast
- [ ] 5.2 WS ready：pending 静默 flush → id 替换；无成功 Toast
- [ ] 5.3 pending time 停止 → flush 单条 ADD 含 endTime
- [ ] 5.4 server id time 停止（WS 未就绪）→ 本地结束 + UPDATE flush
- [ ] 5.5 flush 网络失败 → 保留队列；断 WS 再连上后重试成功
- [ ] 5.6 flush/add 业务失败（mock 非 0 code）→ Toast + pending 移除或 stop 回滚
- [ ] 5.7 gaveUp：可 add；点横幅重连后 flush 积压
- [ ] 5.8 语音/文字：WS 未就绪仍 Toast 拦截；WS 就绪可 sendCommand
- [ ] 5.9 小组件：pending/本地 stop 后 `scheduleHomeWidgetSync` 仍反映本地态
