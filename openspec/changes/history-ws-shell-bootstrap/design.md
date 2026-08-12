## Context

预测页成为默认主页后，`HomeScreen`（喂养）仍是历史 WS 的唯一 owner：`PangbaoHomeTransportGate.onHomeMounted`、`watchLatest`、`ensureHistoryWebSocketConnected`、以及 `_onHistoryWebSocketPayload`（upsert + 飞入）全在喂养页。`PageView.builder` 懒构建 → 未滑入喂养则整条链路未启动。

约束：`ResilientWebSocketClient`；`feedRepositoryProvider` create **不得**自动建连；登出仍 `releasePangbaoHomeTransports`；绑定/切号 reconnect 语义保留；iOS 冷却延迟保留。

## Goals / Non-Goals

**Goals:**

- 进入主壳 `/home` 且登录 gateway bootstrap 完成后，历史 WS 订阅+建连，**无需**访问喂养页。
- WS 推送始终写入 `homeHistory` 并按既有规则请求飞入（预测/喂养可见页门闸不变）。
- 登出 disconnect、切号 wipe、绑定/token reconnect 行为与现网一致。

**Non-Goals:**

- 不改 WS 帧协议、心跳、3-strike、横幅文案。
- 不把 UCG / Voice ASR / Clinic 一并改为「壳层激活」（仅历史）。
- 不预挂载整个 `HomeScreen` 作为捷径。
- 不改飞入测锚/重排（`prediction-fly-measure-after-reorder`）逻辑。

## Decisions

1. **Owner = `UcgHomeShell`（主壳会话）**  
   在 shell `initState` / 登录边沿：await `GatewayBootstrapGate.ensureLoggedInComplete`（已登录时）→（iOS delay）→ `watchLatest` 单例订阅 → `ensureHistoryWebSocketConnected`。  
   **替代**：预构建喂养页 — 过重，拒绝。  
   **替代**：provider create 建连 — 违反 project.md，拒绝。

2. **单一 payload 管道**  
   抽出与 UI 无关的 handler（如 `HistoryWsHomeBridge` / shell 内方法）：`upsert`/`removeRecord` + `requestHistoryEventFlyAfterMutation`。`HomeScreen` **取消**自己的 `_sseSub` 建连路径，避免双订阅双飞；喂养仍可 listen phase 做横幅。  
   **替代**：HomeScreen 与 Shell 都 listen — 双飞风险，拒绝。

3. **Gate 语义**  
   `PangbaoHomeTransportGate` 改为在 **主壳 mount/unmount**（或显式 `activateHistoryWsSession`）计数；`repositories.tryReconnectHistoryWs` 的 `isHomeMounted` 与之对齐。命名可保留以免大范围 rename，文档注明「主壳」非「喂养页」。  
   **替代**：去掉 gate 仅看 session — 会在非 home 路由误重连，谨慎保留壳层 gate。

4. **游客**  
   未登录：不建连（与现一致）。游客→登录：shell 监听 `isLoggedIn` 边沿，走与现 `_onLoggedInWhileHomeMounted` 等价的 bootstrap+ensure（门闸后）。

5. **绑定页显式 reconnect**  
   仍允许绕过「等壳 bootstrap」立即 reconnect（规格已有），不变。

## Risks / Trade-offs

- [Risk] Shell 与旧 HomeScreen 路径短暂并存 → 双订阅 → Mitigation：实现时先迁再删 Home 建连；任务勾选防回归。  
- [Risk] Shell dispose 与 KeepAlive 喂养交错 → Mitigation：gate 以 shell 为准；`release` 仍跟登出。  
- [Risk] 喂养横幅在 Home 未 mount 时看不到 → 可接受（用户在预测页）；进喂养后 phase 流仍可用。  
- [Trade-off] 历史 WS 在主壳常驻，比「仅喂养」略增后台连接 — 产品需要。

## Migration Plan

纯客户端。回滚：恢复 HomeScreen 订阅/建连与 gate 挂回 HomeScreen。

## Open Questions

（无）建连时机与登出/切号语义已由产品拍板。
