## 1. 会话门闸与管道

- [x] 1.1 将 `PangbaoHomeTransportGate` 挂载计数改到主壳 `UcgHomeShell`（或显式 activate/deactivate），并更新 `repositories.dart` reconnect 门闸注释/行为与壳对齐
- [x] 1.2 抽出单一 History WS payload 处理器：upsert/remove → `homeHistory` + `requestHistoryEventFlyAfterMutation`（可放 bootstrap 模块或 shell 私有类）
- [x] 1.3 在 `UcgHomeShell`：已登录时 await gateway bootstrap →（iOS delay）→ `watchLatest` 订阅 + `ensureHistoryWebSocketConnected`；监听游客→登录边沿复用同一路径；保证 single-flight / 不重复订阅

## 2. 拆除喂养页独占建连

- [x] 2.1 从 `HomeScreen` 移除 `_subscribeHistoryWebSocketIfNeeded` / `_sseSub` payload 建连与 upsert 飞入路径；保留 phase 横幅与手动 `reconnectHistoryWebSocket`
- [x] 2.2 确认登出仍 `releasePangbaoHomeTransports`、绑定页 `resetStrike` reconnect、token 轮换仍受壳 gate 约束

## 3. 校验

- [x] 3.1 `openspec validate history-ws-shell-bootstrap --strict`
- [ ] 3.2 手工：冷启动仅预测页 → 加/改事件有飞入且历史列表（进喂养后）已更新；未先进喂养也能飞；登出断开；切号/绑定后重连正常；喂养页无双飞
