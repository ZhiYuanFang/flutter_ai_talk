## Why

预测主页在未登录或未绑定宝宝时虽有骨架预览，但缺少与量身定做同款的粘性引导，用户容易只看演示而不完成登录/绑定。需要叠加「去登录」「去绑定」Dialog，软关后点击再弹，且不得提供永久不再弹。

## What Changes

- **未登录**：预测页展示「去登录」引导 Dialog；底层仍为冷态骨架 + 假留意。
- **已登录未绑定**（无可用 deviceNo）：展示「前往绑定宝宝」Dialog；CTA 对齐喂养页走 `/settings/bind-baby`。
- **交互对齐量身定做软强制**：点遮罩软关；软关后点击**除顶栏头像外**区域再弹；头像仍进 `/settings`（未登录先登录门），**不得**以再弹 Dialog 为该次点击主行为。
- **无永久不再弹**：不得提供 finale/dismissed 永久抑制；仅当条件解除（已登录 / 已绑定）后自动停止展示与再弹。
- **互斥**：同一时刻最多一个引导 Dialog；优先级未登录 > 未绑定 > 量身定做（已绑定无历史）；未登录/未绑定不得启动量身定做。

## Capabilities

### New Capabilities

- `prediction-gate-dialog`：预测页登录/绑定引导 Dialog 的触发、软关再弹、条件解除停用。

### Modified Capabilities

- `smart-prediction-page`：冷态除骨架外叠加登录/绑定 Dialog；与量身定做 Dialog 互斥。

## Impact

- **UI/逻辑**：`smart_prediction_screen.dart`（复用现有 Listener/Visibility 模式）、可选抽取共用 soft-gate Dialog 壳；路由 `/login`、`/settings/bind-baby`。
- **依赖**：建立在 `prediction-demo-skeleton-and-recall-dialog` 的骨架与量身定做 Dialog 行为之上。
- **测试**：不新建 `**/test/**`；手工验收未登录/未绑定软关再弹、头像不抢弹、条件解除后不再出现。
