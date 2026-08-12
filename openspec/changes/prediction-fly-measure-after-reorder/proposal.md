## Why

预测页落库飞入时，History upsert 会立刻驱动 `smartPredictionRows` 按 `nextAt` 重排，瀑布流换位；飞入 Overlay 若在重排布局完成前测锚，会把 `_localEnd` 冻在旧坐标，出现「动画落到空位、卡片已在新位置」。产品选择方案 A：先完成顺序变化与布局，再测量落点并开播。

## What Changes

- 预测可见页的飞入：在历史变更写入之后，**延迟到重排后的布局稳定**（至少 1～2 个 post-frame，或锚点连续稳定）再挂载/启动共享 Overlay 测锚。
- Overlay 在 pop 阶段 MAY 继续刷新落点，以吸收晚到的布局；飞入段仍可冻结终点以免中途乱跳。
- **不**采用方案 B（飞入期间冻结预测行序）；喂养页既有 `setFlyAnimationFrozen` 不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `history-fly-visible-landing`：预测页飞入 MUST 在预测行重排布局可用后再测锚开播。

## Impact

- 代码：飞入请求时机（如 `requestHistoryEventFlyAfterMutation` / 壳层 listen）与/或 `HistoryEventFlyOverlay` 测锚窗口；可能小改 `ucg_home_shell` 预测 KeepAlive。
- 无原生 / 无新依赖；不新建测试文件。
