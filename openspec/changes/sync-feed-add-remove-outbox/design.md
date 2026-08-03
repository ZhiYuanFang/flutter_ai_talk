## Context

- 基线 `home-event-optimistic-add`：按钮路径先插 `pending:*` 再 HTTP；飞入与 tip 挂在 WS「新记录且 !flySuppressed」上，本机添加几乎打不到 tip。
- 代码中存在 `HistoryOutboxStore` / `flushHistoryOutbox`；ADD enqueue 调用面已冷，但 flusher 与 pending 内存路径仍增加复杂度。
- History WS 横幅（gaveUp）当前全模式可见；语音 AI 落库仍依赖 WS。

## Goals / Non-Goals

**Goals:**

- 按钮添加：HTTP 成功 → serverId 入列 + 飞入 + tip SSE；in-flight 禁按钮；离线不入列。
- 删除全部历史 outbox 代码与 Debug 三联。
- 按钮操作不依赖 History WS 就绪；WS 尽力连接，用于他端同步。
- 语音球：切换不拦；按住/发送 `_ensureHistoryWsForSend`；gaveUp 横幅仅语音模式。
- tip `done` 渲染 Markdown（含 `##`），复用 `ClinicAnswerBody`。

**Non-Goals:**

- 不改服务端 tip 1h / tip generate 协议。
- 不改语音/文字路径「仅 WS 更新列表」的落库展示模型。
- 不新建 `**/test/**`。
- 不改 Android 原生。

## Decisions

### 1. 同步成功后入列（替代乐观）

- **决策**：`_submitEventAdd` 先 `addHistoryEvent`；成功后用 serverId 插入/合并列表并 `_triggerTipGeneration`；**不**在 HTTP 路径飞入。
- **理由**：列表跟 HTTP 即时性；动画归 WS。
- **备选**：HTTP 成功即飞——已否决。

### 2. In-flight 禁用与离线

- **决策**：`_eventAddInFlight`（或等价）为 true 时禁用事件网格 / 会调用 `_submitEventAdd` 的入口；HTTP 传输失败 Toast，不入列。可不做单独「离线预检」若失败路径已清晰；MAY 在无网时提前 Toast。
- **理由**：防止连点双发；离线不支持添加。

### 3. 彻底删除 outbox

- **决策**：删除 `history_outbox_store.dart`、`history_outbox_flusher.dart`；去掉 `FeedRepository` enqueue/flush API、WS ready / notifier 上的 flush、`AppDebugLog.historyOutbox` 三联、登出 clear outbox。停表等路径一律即时 HTTP，失败 Toast。
- **理由**：产品明确彻底删除；与「不依赖 WS 也能记（靠 outbox）」旧模型决裂。
- **备选**：仅停用 ADD outbox——拒绝。

### 4. History WS 双模式职责（方案 B）

- **决策**：
  - 按钮：添加/停表等**不得**调用 `_ensureHistoryWsForSend`；不因 WS 未就绪拦截。
  - 语音：切换 channel **不**查 History WS；按住开始与聊天发送保留 `_ensureHistoryWsForSend`。
  - `showWsBanner`：`gaveUp && 语音模式 && 已登录绑定 && !refreshInFlight`。
- **理由**：用户冻结「用时再查」+ 横幅仅语音。
- **备选**：切换语音即 Toast——已否决。

### 5. tip 与 Markdown

- **决策**：成功回调触发 `startStreaming`；面板 `done` 继续/确保 `ClinicAnswerBody(streaming: false)`；清理「1 小时去抖」误导注释。WS 路径上的 tip 调用可移除或保留为他端 create 的可选增强——**默认仅本机成功回调触发**，避免双发；他端同步不强制 tip。
- **理由**：产品「添加事件成功后 tip」指本机添加。

### 6. 飞入归 WS；HTTP 预插用 awaiting 集合

- **决策**：HTTP 先入列时把 serverId 放入 `_awaitingWsFlyIds`；WS 到达时若 id 在集合中或 `isNew`，则飞入并 remove；HTTP 路径永不 `_scheduleFlyForRecord`。tip 仍只在 HTTP 成功触发。
- **理由**：产品冻结「HTTP 不要动画，WS 要动画」；避免 HTTP 先入列导致 `isNew==false` 永远不飞。
- **备选**：HTTP 不入列只等 WS——违背「成功瞬间入列」。

## Risks / Trade-offs

- **[Risk] 弱网体感变慢** → 接受；可用按钮 disabled 反馈。
- **[Risk] 删除 outbox 后离线无法记事** → 产品明确接受。
- **[Risk] 残留 pending 行（磁盘旧缓存）** → hydrate 后可过滤或只读编辑；实现期清理 `pending:*` 展示策略。
- **[Risk] tip 双发（若 WS 仍触发）** → 决策 5：默认只本机成功触发。
- **[Risk] 横幅仅语音导致按钮模式 gaveUp 无提示** → 可接受；按钮不依赖 WS；后台仍尽力重连。

## Migration Plan

1. 改 `_submitEventAdd` + tip + 飞入 + in-flight。
2. 删 outbox 与 flush 挂载；修停表仅 HTTP。
3. 横幅条件加语音模式；确认按钮路径无 WS 门闩。
4. tip Markdown 验收；清注释。
5. 回滚：恢复乐观 + outbox 文件（git revert）。

## Open Questions

- 无（方案 B 与 outbox 删除已冻结）。
