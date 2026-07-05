## Context

- **v2.0.3 基线**：`HomeScreen._submitEventAdd` 已做 `pending:<uuid>` 乐观插入 + 飞行动画；`RemoteFeedRepository.addHistoryEvent` 在 `!isHistoryWebSocketReady` 时返回 `null` 导致 rollback；`_ensureHistoryWsForSend` 在按钮 tap 前拦截。`updateHistoryRecord` **无** WS 门闩；`_stopActiveTimer` 对 `pending:*` 直接 `return false`。`HomeHistoryStore` 已持久化含 pending 的 items。
- **约束**：历史 WS 须经 `ResilientWebSocketClient`；flush 为副作用 HTTP，须 single-flight（`openspec/project.md`）；Debug 新 tag 三联改；不新增 `*_test.dart`。
- **产品决策（已确认）**：flush 网络失败静默、下次 WS ready 重试；gaveUp 可本地写；scope 含 time stop/update outbox；AI 语音/文字仍要 WS ready；业务失败 Toast；edit sheet 全量保存不在首版 scope。

## Goals / Non-Goals

**Goals:**

- WS 未就绪时按钮 add / time stop（含 pending）**立即**更新本地 UI 并落盘。
- `isHistoryWebSocketReady` **上升沿**触发 outbox flush（ADD 来自 pending 行，UPDATE 来自独立队列）。
- 网络失败保留队列、不 Toast；`ApiBusinessException` Toast 并按 op 类型回滚/移除。
- 与现有 `historyRecordMatchesPendingAdd`、飞行动画、`scheduleHomeWidgetSync` 兼容。

**Non-Goals:**

- 语音/文字 `sendCommand` 离线队列。
- 历史 edit sheet 内非 stop 的复杂 save（媒体/广场同步）离线化。
- WS 连接期间 HTTP 失败后的即时重试（仅等下一次 WS ready）。
- 后端 API 变更。

## Decisions

### 1. 双轨 Outbox：pending 行 + UPDATE 文件

- **ADD 队列**：不单独存 JSON；凡 `isPendingHistoryId(id)` 的行即待 flush ADD，body 由当前 `rawPayload` 构造（含用户 stop 后写入的 `endTime`）。
- **UPDATE 队列**：`HistoryOutboxStore` 按 `deviceNo` 落盘 FIFO `{ recordId, body, enqueuedAt }`，仅用于**已有服务端 id** 的 stop/update。
- **理由**：pending 已有磁盘投影；UPDATE 无法从 id  alone 还原完整 update body 时序。
- **备选**：统一 JSON outbox —— 重复存储，与 `HomeHistoryStore` 双写风险高。

### 2. Flush 调度：`HistoryOutboxFlusher`

```
historyWsReadyStream
  .distinct() + 仅 false→true 上升沿
  → if isHistoryWebSocketReady
      → flushOutbox() [single-flight Future]
```

- 挂载点：`RemoteFeedRepository` 构造内 subscribe（与现有 `_emitWsReady` 同层），或 `feedRepositoryProvider` 显式 `ensureOutboxFlusherStarted(ref)`——**不得**在 `HomeScreen`  alone 绑定（避免未挂载漏 flush）。
- 冷启动：`HomeHistoryNotifier._warmFromDisk` 恢复 pending 后，若 WS 已 ready，下一次上升沿或 bootstrap 末尾 `tryScheduleFlush()`。
- **gaveUp**：`isHistoryWebSocketReady == false`，flush 不运行；横幅重连 ready 后上升沿触发。

### 3. Flush 顺序（单 deviceNo FIFO）

```
1. 按 items 列表顺序（升序/展示序）逐条 flush pending ADD
2. 再按 HistoryOutboxStore FIFO flush UPDATE
```

- pending stop 已合并进 ADD body，**不**产生 UPDATE op。
- ADD 成功后 `replaceRecordId(pending, serverId)`；若 UPDATE 队列含同 recordId 且 ADD 刚完成，UPDATE 须用新 serverId（enqueue 时用 pending id 的 UPDATE **禁止**——pending 只走 ADD 合并）。

### 4. 按钮路径 vs AI 路径

| 路径 | WS 门闩 |
|------|---------|
| `_onEventButtonTap` / `_submitEventAdd` | **移除** `_ensureHistoryWsForSend` |
| `_stopActiveTimer`（列表/提醒框） | **移除** WS 检查；允许 pending stop |
| `sendCommand` 语音/文字 | **保留** `_ensureHistoryWsForSend` |

### 5. `_submitEventAdd` 行为变更

```
insertOptimistic + fly
if (isHistoryWebSocketReady)
  serverId = await addHistoryEvent(body)  // 立即 POST
else
  return early（保留 pending，不 rollback）
// flush 负责 deferred add
```

- WS ready 时仍**立即** POST（与现网一致），flush 只处理 backlog。
- `addHistoryEvent` 移除 `!isHistoryWebSocketReady return null`；网络异常在 immediate 路径仍按新语义：保留 pending，不 Toast（交给 flush 或下次 ready）。

### 6. Stop / UPDATE 离线

**pending 行 stop：**

```
replaceRecordImmediate(_recordWithEndTime(...))  // 已有
// 不 enqueue UPDATE；flush ADD 时 rawPayload 含 endTime
```

**server id + WS 未就绪：**

```
replaceRecordImmediate（乐观 endTime）
HistoryOutboxStore.enqueueUpdate(recordId, buildEventUpdateBody(...))
// flush 时 POST update
```

- 网络 flush 失败：保留 UPDATE 队列 + 保留本地 optimistic endTime。
- 业务 flush 失败：Toast + `replaceRecordImmediate` 恢复进行中（清 endTime）。

### 7. 失败分类

| 类型 | ADD pending | UPDATE |
|------|-------------|--------|
| 网络/超时/解析 | 保留 pending，静默 | 保留队列，静默 |
| ApiBusinessException | Toast + remove pending + cancel fly | Toast + 回滚 endTime + dequeue |
| 登出 | 清除 pending 行 + 清空 outbox 文件 | 同左 |
| 换 deviceNo | 不清旧 device 文件；flush 仅当前 deviceNo | 同左 |

### 8. 副作用 HTTP 治理

- `_flushInFlight`：并发 ready 事件 await 同一 Future。
- 同一 flush 会话内 UPDATE 连续网络失败 **不** 无限循环；本次 flush 结束，等**下一次 WS ready** 再试（无 timer 重试）。
- 不在 `feedRepositoryProvider` `build` 里 `unawaited(flush)` 除非 flusher 为 lazy singleton 且 idempotent。

### 9. UI：pending stop 入口

- `home_history_scroll.dart`：`onStop` 条件从 `!isPendingHistoryId` 改为始终对 active timing 展示 stop（或仅 WS 未就绪时也展示——实现上等价于移除 pending 排除）。
- `home_history_edit_sheet`：pending 仍只读（scope 不含 sheet save）。

## Risks / Trade-offs

- **[Risk] WS 长期不断开但 HTTP 失败** → 队列挂到下次 WS 重连才 flush（产品已接受）。
- **[Risk] pending 与远端重复** → 依赖 `historyRecordMatchesPendingAdd` + WS create 合并；ADD flush 前 WS 推送同 event+startTime 须 upsert 不重复插行。
- **[Risk] 多条 pending ADD 顺序** → 按列表序 flush；time 型重复校验已含 pending 行。
- **[Risk] Widget 展示未同步 server 的 pending** → 可接受；widget 读本地 history，与乐观策略一致。
- **[Risk] gaveUp 积压** → 用户须点横幅；本地数据仍在，重连后 flush。

## Migration Plan

1. 实现 outbox store + flusher + repository 改动。
2. 调整 HomeScreen / scroll stop 门闩。
3. 手工验收：WS 延迟建连 add、pending stop、gaveUp 重连 flush、业务失败 Toast、AI 路径仍 blocked。
4. 无服务端迁移；旧磁盘 pending 行在升级后首次 WS ready 自动 flush。
5. 回滚：恢复 WS 双门闩（Revert flusher + outbox）。

## Open Questions

- （已关闭）edit sheet save 是否进 outbox → **首版否**。
- （已关闭）WS 连接中 HTTP 失败是否即时重试 → **否，等下次 WS ready**。
