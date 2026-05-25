## Context

- **现状**：`home_screen._submitEventAdd` 仅 `await addHistoryEvent` → Toast；列表与飞行动画依赖 `watchLatest` WS upsert（`home-event-record-fly-animation` 在「本地尚无该 id」时 scheduleFly）。
- **既有 add 规约**（`home-button-input-mode` / `history-event-add`）：明确要求 **不得** 用 add 响应 `id` 插 UI，仅 WS。
- **用户选择**：强乐观（option 1）—— tap 即插行 + 动画 + Toast，并行 POST，成功替换 id，失败删行。
- **相关变更（只读）**：`home-event-record-fly-animation` 定义飞行动画与 B+ 滚底；本变更调整「何为新增 record」的触发源与 WS 去重。

## Goals / Non-Goals

**Goals:**

- 底部按钮路径（`time` / `one` / `number` + 目录 picker 叶子）实现强乐观 UI。
- `addHistoryEvent` 解析并返回 `data.id`；pending `pending:<uuid>` → 服务端 id 原地替换。
- WS `create`/`update` 同 id 合并，无重复行、无二次飞行动画。
- 与现有 `buildEventAddBody`、eventType 映射、time 重复校验、Toast 文案保持一致。
- `time` 型 pending 期间停止计时边缘行为明确且安全。

**Non-Goals:**

- 语音/文字 `sendCommand` 乐观插入（仍 WS-only）。
- 修改 WS 协议或后端 add 契约（假定成功响应含 `data.id`，用户已确认）。
- 改动 `home-history-visual-scale` 等无关 UI。

## Decisions

### 1. 强乐观时序（按钮路径）

```
tap → 生成 pendingId = "pending:" + uuid
    → buildOptimisticRecord(body, pendingId) 
    → homeHistory.insertOrUpsert(pending)   // 列表立即可见
    → Toast「已记录{eventName}」
    → scheduleFly(pendingId)                // 仅一次，见 §5
    → unawaited: addHistoryEvent(body) → AddHistoryResult
         ├─ success(serverId): replaceId(pendingId, serverId)
         └─ failure: removeById(pendingId) + error Toast（envelope message）
```

**理由**：用户感知与列表/动画同步；网络与 WS 并行不阻塞 UI。

**备选**：弱乐观（仅 Toast 不等列表）—— 已否决（用户选强乐观）。

### 2. Pending id 与展示记录

- **格式**：`pending:<uuid>`（字符串 id，与数字服务端 id 区分）。
- **构造**：`history_mapper` 新增 `historyRecordFromAddBody(Map body, {required String id})`，字段与 add body / catalog 一致（`eventId`、`eventName`、`eventNumber`、`startTime`、`endTime`、`remark`、`deviceNo` 等），保证 `EventLogo`、计时态 `isActiveTimingRecord` 与现网一致。
- **`time` 型**：`endTime == 0` → 进行中计时；乐观行参与 `_hasActiveTimingForEvent` 校验，避免重复点开始。

### 3. 仓储 API：`addHistoryEvent` 返回 id

```dart
// 示意（实现时命名可对齐仓库风格）
sealed class AddHistoryEventResult { ... }
// success: server record id (String)
// failure: null / false + 已 Toast
Future<String?> addHistoryEvent(Map<String, dynamic> body);
```

- `remote_feed_repository`：`postJsonEnvelope` 成功后从 `data['id']` 解析（`int` → `String`），业务 `code != 0` 仍 Toast 并返回 null。
- **不得** 在 repository 内直接改 `homeHistoryProvider`（保持 UI 层编排）。

### 4. Notifier：`replaceId` / `removeById`

- `HomeHistoryNotifier` 新增：
  - `insertOptimistic(HistoryRecord r)` 或复用 `upsertRecord` 且保证 pending 在列表末尾（与「最新在底」一致）。
  - `replaceRecordId(String fromId, String toId)`：同索引替换 id，保留其余字段；若 `toId` 已存在则合并后删 pending（防御双通道）。
  - `removeById(String id)`：失败回滚。
- WS `upsertRecord`：**若 `items.any((e) => e.id == r.id)`** 则更新字段，**不** 视为新增（不触发 fly 的「新 id」分支）。

### 5. 飞行动画触发规则（协同 `home-event-record-fly`）

| 事件 | 是否 scheduleFly |
|------|------------------|
| 按钮乐观插入 pending | **是**（tap 后，与 Toast 同帧/下一帧） |
| add 成功 id 替换 pending→server | **否**（同一条逻辑记录，仅 id 变） |
| WS create/update 同 id 已存在 | **否** |
| WS create 新 id（语音等） | **是**（保持原规约） |
| add 失败移除 pending | **否**（若动画已播完可接受；进行中可 cancelFly） |

实现要点：`home_screen` 在乐观路径显式 `scheduleFly(pendingId)`；`watchLatest` 内「新 record」判定改为：**仅当 upsert 前本地不存在该 id 且非「刚由 replaceId 产生的 server id」**。可用 `_recentlyReplacedIds` 短生命周期 Set（1–2 帧）或 fly 调度 flag 避免 WS 与 replace 竞态二次飞行。

### 6. `time` 型：pending 期间停止计时

- **决策**：对 `id.startsWith('pending:')` 的进行中计时行，**禁用** 停止按钮（或隐藏 stop affordance），直至 add 成功完成 id 替换或失败移除。
- **理由**：`updateHistoryRecord` 需要有效服务端 id；对 pending 调 update 必然失败。
- **备选**：排队 stop 至 id 替换后自动 update—— 复杂度高，MVP 不采用。

### 7. 语音/文字路径

- `sendCommand` / chat 落库：**不** 调用乐观插入；列表仍仅 WS。避免与 NLU 异步、多事件歧义冲突。

### 8. 失败与竞态

- add 失败：同步 `removeById(pendingId)` + 错误 Toast（repository 已 Toast 时 UI 避免重复，以一层为准）。
- add 成功但 WS 先到且带同 event 不同 id：极少见；`replaceId` 后 WS 合并 server id 即可。
- add 慢、用户滚离底部：飞行动画仍按 B+（`home-event-record-fly-animation`），乐观插入时 `followLatest` 逻辑不变。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 响应无 `data.id` | 契约已确认；解析失败视为 add 失败并回滚 pending |
| WS 早于 replace 到达 | upsert 同 pending id 合并；replace 后 WS 更新 server 字段 |
| 二次飞行动画 | replace 不 scheduleFly；WS 路径排除已存在 id |
| pending 行可点停止导致无效 update | 禁用 stop 直至 id 就绪 |
| 乐观行与真实数据字段偏差 | 共用 `buildEventAddBody` + mapper 单一路径 |

## Migration Plan

1. 扩展 `FeedRepository` / `RemoteFeedRepository.addHistoryEvent` 返回 id。
2. mapper + notifier API。
3. `home_screen` 按钮路径改乐观编排；`watchLatest` fly 去重。
4. `home_history_timeline_tile`（或 stop 入口）识别 pending id 禁用 stop。
5. 更新 OpenSpec delta；手工验证 time/one/number、目录叶子、失败回滚、WS 对账、语音不加行。

**回滚**：恢复 await-only add + WS-only 列表（Revert notifier/repository API）。

## Open Questions

- `data.id` JSON 类型为 `int` 还是 `string`？实现统一 `toString()`。
- add 成功但 `replaceId` 前用户删除 pending 行？MVP 不允许删 pending（无删除入口）；若后续支持需取消 in-flight add。
