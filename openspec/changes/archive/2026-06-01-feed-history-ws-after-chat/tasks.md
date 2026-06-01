## 1. 与后端对齐

- [x] 1.1 与网关确认：`POST /device/history/api/chat` 处理完成后，历史 WebSocket **必定**下发可解析的新增/更新事件（字段与 `RemoteFeedRepository` 中 `create`/`update` 或 `data` 回退分支一致）

## 2. 首页行为

- [x] 2.1 在 `home_screen.dart` 中移除 `_onVoiceEnd`、`_onWebSubmit` 在 `sendCommand` 成功路径上的 `await _reloadHistory()`（保留 `_chatReply` 等与回复文案相关逻辑）
- [x] 2.2 确认 `_init` 中首次 `_reloadHistory()` 仍执行，以满足「首屏种子加载」规格
- [x] 2.3 手测：胖宝号已绑定、WS 已配置 → 发一条聊天 → Network 中**不应**在 send 后立即出现 `history/api/list`；列表仍通过 WS 出现新记录（请在本地 Network 自测）

## 3. WebSocket 未就绪禁发与重连（补充需求）

- [x] 3.1 `RemoteFeedRepository`：`auth_ok` 后置 `isHistoryWebSocketReady`；`sendCommand` 未就绪直接返回；提供 `reconnectHistoryWebSocket` 与 `historyWsReadyStream`
- [x] 3.2 首页：订阅就绪流、AppBar 手动重连按钮；发消息前与按住说话前校验 WS；Toast 提示

## 4. 文档

- [x] 4.1 在 `app/README.md` 简要说明：首页历史以 WS 增量为主，发消息后不再自动 list；WS 未就绪禁发 chat 与重连入口

## 5. 校验

- [x] 5.1 运行 `openspec validate feed-history-ws-after-chat --strict`
