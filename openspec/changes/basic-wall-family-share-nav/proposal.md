## Why

基础版能力墙中「家庭全员共享」条目目前点按后仅关墙、不进入任何业务页，与其它可落地能力（推送、小组件、趋势、音箱等）不一致；产品期望用户可直接进入「邀请家人」页出示共享码，降低从能力演示到真实家庭共享的路径成本。

## What Changes

- **修改**基础版墙 `familyShare` 行点按行为：先关闭能力墙，再导航至 `/settings/baby-share`（邀请家人页）。
- **BREAKING（相对 v2.2.2 行为）**：撤销「家庭共享不跳转」约束；未绑定宝宝时仍进入该页，由现有页内空态提示「请先绑定宝宝后再出示共享码」。
- 不改其它 kind 的落地规则；不改邀请家人页本身实现。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `predict-capability-tier-wall`：将 `familyShare` 从「仅关墙」改为「关墙后 `push` `/settings/baby-share`」；更新对应 Requirement 与 Scenario。

## Impact

- **代码**：`app/lib/ui/widgets/predict_capability_tier_wall.dart` 中 `_onBasicFeatureTap` 对 `PredictBasicFeatureDemoKind.familyShare` 的分支。
- **路由**：复用既有 `/settings/baby-share`（需登录列表；未登录走现有 redirect）。
- **基线**：对照并 delta `openspec/specs/v2.2.2.md` 中 `predict-capability-tier-wall` 相关 Requirement。
