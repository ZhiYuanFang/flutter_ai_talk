## Context

竖屏预测语音挂在 `UcgHomeShell`，由 `LandscapeVoiceLifecycleBinder(landscape: false)` 驱动 `syncLandscapeVoiceLifecycle`。当前竖屏 `surfaceVisible` 额外与 `ModalRoute.of(context)?.isCurrent` 相与：任意压在主壳上的 Modal（含 `showModalBottomSheet` / `showDialog` 的 `PopupRoute`）都会使 `isCurrent == false` → `deactivate` → `_tearDown`（`wake.stop` 释放 KeywordSpotter + `endSession(teardown)`）。弹层关闭后 `activate` → `wake.start()` 在 UI isolate 同步 `KeywordSpotter(config)`（native `InitEncoder`），与关动画抢帧，体感「先卡一下，才关」。

基线 `prediction-portrait-voice-dock` 要求「以主壳为当前路由」并在「推入覆盖路由」时 deactivate——本意是 Page 级离开，实现过宽地包含了 Overlay。

## Goals / Non-Goals

**Goals:**

- 竖屏下打开/关闭喂养事件选择 sheet、记录 sheet、玻璃确认框等 Overlay：**不得** teardown 语音会话，**不得** 全量重载 KWS。
- 真正离开主壳（`PageRoute` 压上，如设置/登录）或离开业务表面（未合格 UCG、横竖屏切换、flag 关）时：**仍须** deactivate。
- 关 Overlay 路径上正常不应再出现 `endSession reason=teardown` 紧接 `InitEncoder` 冷启动卡顿。

**Non-Goals:**

- 不改玻璃 `BackdropFilter` / sheet 视觉。
- 不改主壳 resume HTTP bundle。
- 不改横屏 binder 的 surface 规则（横屏本就不看 `isCurrent`）。
- 不把 `KeywordSpotter` 迁到独立 isolate（可作为后续性能项；本变更以「别无谓重建」为主）。
- 不新建测试文件（遵守仓库测试约定）。

## Decisions

### 1. 竖屏门闩：Page 覆盖 vs Overlay

- **决策**：竖屏生命周期「被盖住」仅当主壳之上存在**覆盖性 `PageRoute`**，**不得**仅因 `ModalRoute.isCurrent == false` 或 Overlay 的 `RouteAware` 回调而 deactivate。
- **实现**：
  1. binder 用 `_coveredByPageRoute`，由 `didPushNext` / `didPopNext` 置位，**不再**读 `isCurrent`。
  2. **`appRouteObserver` MUST 为 `RouteObserver<PageRoute<dynamic>>`**（不得用 `RouteObserver<ModalRoute>`）。后者会把 bottom sheet / dialog 也触发 `didPushNext`，与 `isCurrent` 同病。
  3. `activate` 须 single-flight + lifecycle generation，避免双 `_sync` 重复冷启 KWS。
- **备选（不采纳为唯一手段）**：Overlay 时 `pause` 麦——门闩收窄更对症。

### 2. Overlay 期间保持会话热态

- **决策**：Overlay 打开期间竖屏会话保持 `_active`；KWS 可继续跑或仅按既有对话态 `pause`/`resume`，**不得**因 Overlay 调用 `stop()`+`free` spotter。
- **备选**：Overlay 时 `pause` 麦但保留 spotter——若产品担心 sheet 期间误唤醒可加；默认先「完全不因 Overlay 动生命周期」，实现更简单、卡顿消除最彻底。

### 3. 保留既有业务表面条件

- **决策**：未合格 UCG、非竖屏、`kPredictionPortraitVoiceEnabled == false`、无 deviceNo / 权限失败等既有 `want` 条件不变；本变更只修正「路由货币」判定过宽。

## Risks / Trade-offs

- **[Risk] Overlay 期间仍听唤醒** → 可接受（用户仍在主壳喂养/预测语境）；若误触发可再议 pause；**Mitigation**：规格写明 Overlay 不强制停麦。
- **[Risk] `RouteAware` 与 `isCurrent` 混用导致漏 deactivate** → **Mitigation**：以 PageRoute 进出为权威；手工验：推设置须 teardown，关 sheet 不得 teardown。
- **[Risk] 并发 activate/deactivate 竞态** → 既有 `_active` 门闩；避免 Overlay 抖动触发的成对调用即可。
- **Trade-off**：略增「sheet 开着仍可唤醒」的可能，换取关闭无卡顿与少打模型。

## Migration Plan

- 纯客户端行为修复，无数据迁移。
- 回滚：恢复竖屏 `isCurrent` 相与即可（会带回卡顿）。

## Open Questions

- Overlay 期间是否要 `pause` KWS 麦（防误唤醒）——默认否；若产品要静音，可在不 `free` spotter 的前提下 pause。
