## Why

主壳默认页为智能预测；`PageView.builder` 懒构建导致喂养页 `HomeScreen` 在用户首次滑入前不 mount。历史 WebSocket 的 `watchLatest` 订阅、`ensureHistoryWebSocketConnected`、以及 upsert → 飞入请求目前都挂在 `HomeScreen` 生命周期上，因此冷启动只待在预测页时：**WS 未连、推送不入库、落库飞入不触发**。用户必须先进入一次喂养页后飞入才「突然正常」。预测已成为主页枢纽后，该耦合已不可接受。

## What Changes

- 将历史 WS **会话激活**（`watchLatest` 订阅 + gateway bootstrap 完成后 ensure 建连）上移到 **主壳 `UcgHomeShell`（或等价 shell session）**，在用户进入 `/home` 且登录门闸通过后即触发，**不依赖**喂养页是否曾 mount。
- 将 History WS 推送的 **upsert / remove → `homeHistory` + `requestHistoryEventFlyAfterMutation`** 从仅 `HomeScreen` 处理，改为壳层/会话级单一订阅（喂养页不再是唯一消费方）。
- `PangbaoHomeTransportGate`（或后继命名）的「允许 history reconnect」语义与 **主壳会话**对齐，而非「喂养 `HomeScreen` widget 已 mount」。
- **保持**：登出 → `releasePangbaoHomeTransports` / disconnect；切账号 wipe；绑定后 `reconnectHistoryWebSocket(resetStrike: true)`；token 轮换 reconnect；iOS 建连冷却；**不得**在 `feedRepositoryProvider` create 时自动建连。
- 喂养页保留 phase 横幅与手动重连 UI；不再作为建连唯一入口。

## Capabilities

### New Capabilities

- `history-ws-shell-session`：主壳会话级历史 WS 订阅与建连门闸（与喂养页 UI 解耦）。

### Modified Capabilities

- `history-ws-reconnect`：将「须 `HomeScreen` watchLatest」改为「须主壳（或等价 home owner）在 bootstrap 后订阅并 ensure」；登出 tearDown 语义不变。
- `home-event-record-fly`：可见页为预测时，落库飞入 MUST 在未访问喂养页的情况下仍可由 History WS 触发（前提：主壳已激活历史会话）。

## Impact

- 代码：`ucg_home_shell.dart`、`home_screen.dart`（拆出订阅/建连）、`pangbao_transport_release.dart`（gate 语义）、`repositories.dart`（`isHomeMounted` 判定）、可能新增小模块承载 payload → history/fly。
- 行为：冷启动进预测 → 登录门闸后历史 WS 就绪；预测页加/改事件可飞入且 `homeHistory` 实时更新。
- 约束：仍走 `ResilientWebSocketClient`；provider 创建不得自动 WS；不新建测试文件。
