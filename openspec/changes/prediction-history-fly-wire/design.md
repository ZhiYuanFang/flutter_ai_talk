## Context

共享编排已向预测发出 `HistoryEventFlyRequest`；`HomeScreen` 只处理 feeding。预测承接本应在 `ucg_home_shell._KeepAlivePredictionPage`；误在 `SmartPredictionScreen` 再挂一层会导致双飞。

## Goals / Non-Goals

**Goals:**

- 预测可见时仅**一层**共享 Overlay 飞入。
- 落点 = 对应 `rootEventId` 预测卡当前 logo；离屏先 ensureVisible。

**Non-Goals:**

- 不改触发门槛、不改喂养路径、不新建测试。

## Decisions

1. **唯一宿主**：`_KeepAlivePredictionPage`（壳层 KeepAlive）；`SmartPredictionScreen` **不得**再挂飞入 Overlay。
2. **复用** `HistoryEventFlyOverlay` + `PredictionCardFlyLanding(logoAnchorKey: registry.keyFor(rootEventId))`。
3. `disableAnimations` 时 clear session，避免请求悬挂。

## Risks / Trade-offs

- [Risk] rootEventId 空或卡未 build → Overlay abandon 不飞（已接受）。
- [Risk] 与门闸 Overlay 叠层 → 壳层 Overlay 在预测页之上；连播以最新 session 为准。
