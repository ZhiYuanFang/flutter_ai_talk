## Context

当前：`upsertRecord` → 立刻 `requestFly` → Overlay `prepare`/测锚；同时 `homeHistory` 变化使预测行重排。喂养页飞入期间冻结历史列表变更，故少见错位；预测页无对等冻结，落点易测在旧槽。

产品拍板方案 A：先重排再测锚（不做飞入期间冻预测顺序）。

## Goals / Non-Goals

**Goals:**

- 预测页飞入落点与用户看到的**重排后**卡片 logo 对齐。
- 改动尽量小，复用现有 Overlay / Landing。

**Non-Goals:**

- 不实现方案 B（飞入完成前冻结 `smartPredictionRows` 顺序）。
- 不改喂养 `setFlyAnimationFrozen` 语义。
- 不改 WS 触发范围（仍仅 feeding/prediction 可见页）。

## Decisions

1. **延迟开播，而非推迟 upsert**  
   历史仍立刻写入；仅推迟预测向飞入的 Overlay 挂载或 `prepare` 完成时机，等重排布局过至少两帧（`addPostFrameCallback` 嵌套或两次 `endOfFrame`）。

2. **落点稳定检测（推荐）**  
   开播前对锚点全局中心连续测两次（跨一帧），位移小于阈值（如 2～4 px）再 `_animationStarted`；超时仍用最后一次测值得开播或 abandon（与无锚点策略一致）。

3. **pop 阶段继续跟锚**  
   保留/加强 `_updateEndFromAnchor` 在 pop 比例内刷新 `_localEnd`，吸收瀑布流晚布局；进入飞入段后冻结终点。

4. **喂养路径**  
   可不延迟（列表冻结已够）；若共享 `requestFly` 延迟，喂养多等 1～2 帧可接受，或仅对 `targetPage == prediction` 延迟。

## Risks / Trade-offs

- [Risk] 延迟过短仍测早 → Mitigation：两帧 + 稳定检测。  
- [Risk] 飞入体感略慢半拍 → 可接受（约 32ms～两帧）。  
- [Risk] 重排后卡离屏 → 既有 `ensureVisible`；仍失败则不飞。

## Migration Plan

纯客户端；回滚去掉延迟/稳定检测即可。

## Open Questions

（无）方案 A 已写死。
