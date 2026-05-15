## Context

- `HomeScreen` 在 `sendCommand`（`POST /device/history/api/chat`）成功后调用 `_reloadHistory()` → `GET /device/history/api/list`，整页替换展示数据。
- `RemoteFeedRepository` 已实现历史 WebSocket：订阅 `watchLatest()` 时 `_ensureWs()`，解析 `action` 为 `create`/`update`/`delete` 等并 `_mergeInbound` 更新 `_cache` 与广播流。
- 用户期望：**写路径**以 WS 推送为准，避免每次聊天后立即 HTTP list。

## Goals / Non-Goals

**Goals:**

- `sendCommand` 成功返回后，首页列表**不得**再因该次发送而立即调用 `loadHistory()` / 历史 list HTTP。
- 新记录展示依赖 WS 推送与现有 `historyRecordFromServerMap` 解析链路；首屏进入首页时的**初始**列表仍可通过一次 `loadHistory()` 填充（与现 `_init` 行为一致，除非后续单独变更）。

**Non-Goals:**

- 不修改 `chat` 接口契约与请求体。
- 不在本变更中重写 WebSocket 协议或替换 `web_socket_channel`。
- 不强制删除详情页返回、切换账号等其它路径上的 `loadHistory()`（若存在），除非与「发消息后」路径冲突。

## Decisions

1. **移除发消息后的 `_reloadHistory()`**  
   - **决策**：在 `_onVoiceEnd`、`_onWebSubmit` 中删除 `sendCommand` 成功路径末尾的 `await _reloadHistory()`。  
   - **理由**：与目标一致；WS 已负责增量。  
   - **备选**：改为「仅当 `watchLatest` 未订阅或 WS 未连接时再 list」——实现复杂，留作后续。

2. **保留进入首页时的首次 `loadHistory()`**  
   - **决策**：维持 `_init` 中首次 `_reloadHistory()`，用于冷启动与 `_cache` 种子数据。  
   - **理由**：避免无 WS 快照时白屏；与「发消息后不刷」正交。

3. **兜底（首版可不做代码，规格预留）**  
   - **决策**：若联调发现 WS 延迟或丢事件，再在 `RemoteFeedRepository` 或 UI 层增加「可选延迟 list」或 Toast；本设计默认依赖网关 **chat 完成后必推 create**。  
   - **理由**：先满足主路径，避免过度工程。

## Risks / Trade-offs

- **[Risk] WS 未连接或推送晚于 UI 期望** → 列表短暂不刷新；联调确认 `auth` 后服务端推送顺序；可选在 `sendCommand` 后仅 `invalidate` 本地状态而不 HTTP。  
- **[Risk] 服务端未推 create** → 列表永久缺条；**必须与后端对齐**契约。  
- **[Risk] 用户从详情页返回仍 `_reloadHistory()`** → 与目标不冲突，仍可保留以修复编辑后的列表一致性。

## Migration Plan

1. 合并后发布；无需服务端迁移。  
2. 若线上列表不更新，回滚为恢复 `sendCommand` 后 `_reloadHistory()` 一行即可。

## Open Questions

- `chat` 完成后 WS 帧的 **action/type 与 payload** 是否与 `_mergeInbound` 当前分支完全一致（含无 `action` 时走 `decoded['data']` 分支）？需与网关文档核对。  
- Web 与移动端在 `WS_HISTORY_URL` 为空时是否不建连——此时去掉 list 刷新会导致无法展示新消息，是否要在无 WS 时保留 HTTP 兜底（产品决策）。
