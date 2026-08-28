## 1. 壳层激活与预算骨架

- [x] 1.1 在主壳会话侧引入历史 WS 静默自愈预算（默认 2）与 single-flight；登出 / `releasePangbaoHomeTransports` 清零；`ready` 成功清零
- [x] 1.2 `_activateHistoryWsSessionIfNeeded`（及游客→登录边沿）在 ensure 前调用 `resetHistoryWebSocketStrike`（或等价 resetStrike）
- [x] 1.3 激活后若超时未 `ready`（或 `waitForReadyOrTerminal` 超时）且预算未尽：打 `AppDebugLog.wsTransport` 并 `reconnect(resetStrike: true)`，计入预算

## 2. Resume 与 deviceNo

- [x] 2.1 主壳挂载 `WidgetsBindingObserver`（或等价）：`resumed` 时对 history 走统一自愈入口（gaveUp 且预算未尽则 resetStrike+reconnect；非 gaveUp 未 ready 则 `onAppLifecycleResumed` / reconnect）
- [x] 2.2 喂养 `HomeScreen` 去掉或委托 history 的 resume reconnect，避免与壳层双触发（保留其 HTTP 刷新职责除非顺手合并且遵守副作用治理）
- [x] 2.3 `feedRepositoryProvider` 启用 `bindAuthenticatedWsSession(watchDeviceNo: true)`，门闸：主壳 mounted + bootstrap complete + URL 非空；deviceNo 变更 `resetStrike` reconnect

## 3. 校验与手工验收

- [x] 3.1 `openspec validate history-ws-silent-heal --strict`
- [ ] 3.2 手工：冷启动仅预测 → 模拟/偶发三振后无需进喂养即可恢复 ready（或预算耗尽后停）；从未进喂养时后台再回前台可自愈；deviceNo 晚到可唤醒；登出不再连；语音横幅手动重连仍可用
