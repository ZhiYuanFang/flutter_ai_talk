## Context

历史 WS 建连已由 `UcgHomeShell` 在 gateway bootstrap 后 `watchLatest` + `ensure`（见进行中变更 `history-ws-shell-bootstrap`）。喂养页不再补连。冷启动偶发握手失败会落入 `gaveUp` 或 precondition paused；`ensure` 对 `gaveUp` 空转，login/壳激活未 resetStrike，resume 仅挂在可能未 mount 的 `HomeScreen`，且基线禁止 resume 救 gaveUp。产品要求**静默自愈**。

约束：`ResilientWebSocketClient`；副作用 single-flight + 有限次熔断；provider create 不得建连；Debug 走 `AppDebugLog.wsTransport`。

## Goals / Non-Goals

**Goals:**

- 主壳会话活跃且已订阅时，历史 WS 未 `ready` 可静默恢复（含有限次 gaveUp）。
- 壳激活 / 登录边沿 ensure 前 resetStrike。
- deviceNo 空→非空唤醒 reconnect(resetStrike)。
- resume 编排以主壳为 owner，不依赖喂养页曾 mount。

**Non-Goals:**

- 不改 WS 帧协议、心跳间隔、单次握手 3-strike 计数规则（自愈是「外层再开一轮」）。
- 不强制预测/按钮模式展示 gaveUp 横幅（自愈优先；耗尽后语音横幅仍可用）。
- 不把 UCG/Clinic/Voice 一并纳入本变更的自愈策略。
- 不新建 `**/test/**`。

## Decisions

1. **自愈 owner = 主壳会话**  
   在 `UcgHomeShell`（或抽出的小模块由壳调用）集中：激活时 `resetStrike` + ensure；定时/事件驱动的 silent heal；`WidgetsBindingObserver` resume。  
   **替代**：喂养页再挂 ensure — 与 shell-bootstrap 冲突，拒绝。  
   **替代**：仅改 `ResilientWebSocketClient` 取消 gaveUp — 影响所有通道，拒绝。

2. **外层自愈预算（silent heal budget）**  
   主壳会话内对 history 维持独立计数（建议默认 **2** 次「对 gaveUp/paused 的 resetStrike+reconnect」）。触发源：① 激活后观察未 ready 超过阈值（如 20–30s 或 `waitForReadyOrTerminal` 超时）；② App resume 且 desired∧subscribe∧!ready；③ deviceNo 边沿（另计或共用，实现取单一计数器更简单）。成功 `ready` 后清零预算。登出 / `releasePangbaoHomeTransports` 清零。预算耗尽后遵守「停在 gaveUp，等手动/login/deviceNo」。  
   **替代**：无限重试 — 违反副作用熔断，拒绝。  
   **替代**：预算 0（仅非 gaveUp）— 不满足产品「静默自愈」含 gaveUp，拒绝。

3. **BREAKING：放宽 resume×gaveUp**  
   基线「resume 不得在 gave-up 自动重试」改为：主壳会话内且预算未耗尽时，resume MUST 允许 `reconnect(resetStrike: true)`。预算耗尽则仍不得自动重试。  
   **替代**：仅非 gaveUp resume — 无法覆盖「冷启动三振后从未 ready」。

4. **激活路径 resetStrike**  
   `_activateHistoryWsSessionIfNeeded`（及游客→登录边沿）在 `ensureHistoryWebSocketConnected` 前 MUST `resetHistoryWebSocketStrike()`（或 `reconnect(resetStrike: true)` 若需强制撕旧连接）。补齐基线「login MUST reset strike」的实现缺口。

5. **deviceNo 监听**  
   `feedRepositoryProvider` 对 `bindAuthenticatedWsSession` 启用 `watchDeviceNo: true`，`shouldReconnect` 仍要求主壳 mounted + 非空 URL +（建议）bootstrap complete；空→非空与切换均 `resetStrike` reconnect。与绑定页显式 reconnect 幂等（single-flight）。

6. **喂养页 resume**  
   `HomeScreen.didChangeAppLifecycleState` 中 history 的 `onAppLifecycleResumed` 改为 no-op 或委托壳层统一入口，避免双触发；HTTP 历史/range 刷新可仍留喂养或一并上移（本变更优先 WS；HTTP resume 若仅喂养挂载则预测-only 用户本就靠其它路径，不在本变更扩大 scope，除非实现时顺手接到壳层且遵守副作用治理）。

7. **观测**  
   自愈触发打 `AppDebugLog.wsTransport`：`silentHeal reason=… budget=… phase=…`（无新 tag 除非现有不够；优先复用 wsTransport）。

## Risks / Trade-offs

- [Risk] 冷启动网络持续差 → 自愈 2 次仍 gaveUp → Mitigation：预算熔断 + 语音横幅仍可手动；日志可证伪。  
- [Risk] resume 与 watchdog 并发双 reconnect → Mitigation：单飞 `reconnectInFlight` / 壳层 `_healInFlight`。  
- [Risk] 与 `history-ws-shell-bootstrap` 未归档并存 → Mitigation：本变更假设壳层已是 activate owner；实现时对齐现网 `ucg_home_shell.dart`。  
- [Trade-off] 静默重试略增失败时的连接尝试 — 可接受。

## Migration Plan

纯客户端。回滚：移除壳层 heal/resume gaveUp 分支，恢复基线「resume 不救 gaveUp」与仅 HomeScreen resume。

## Open Questions

（无）产品已选定静默自愈；预算默认 2，实现常量可调，不阻塞提案。
