## MODIFIED Requirements

### Requirement: Client SHALL NOT expose feature unlock hub as a product surface

The client MUST NOT present a user-reachable「功能开通」hub screen (`FeatureUnlockHubScreen` or equivalent). Settings MUST NOT navigate to that hub. The client MUST NOT register GoRouter paths `/features/unlock` or `/features/invite-howto` (including redirect-only stubs that only send users to `/home`). Predict Pro payment and trial MUST NOT depend on opening a hub. Attempts to open those locations MUST NOT render a hub list; the router `errorBuilder` (or equivalent) MUST offer a control to return to a safe logged-in home (e.g. `/home`).

客户端 **不得** 再提供可达的功能开通中心页；设置 **不得** 跳转该页；**不得** 再注册 `/features/unlock` 与 `/features/invite-howto`（含仅 redirect 的壳）；Pro 支付/试用 **不得** 依赖 Hub；打开旧路径 MUST NOT 渲染 Hub，且错误页 MUST 可回安全主页。

#### Scenario: 无 Hub 路由注册

- **WHEN** 客户端路由表构建完成
- **THEN** MUST NOT 存在 `/features/unlock` 或 `/features/invite-howto` 的 GoRoute 注册（含 redirect-only）

#### Scenario: 打开旧 Hub 路径

- **WHEN** 用户或深链尝试打开 `/features/unlock`
- **THEN** 客户端 MUST NOT 渲染功能开通中心列表页
- **AND** MUST 能回到安全主页（错误页回主页出口或等价）

#### Scenario: 设置无跳转 Hub

- **WHEN** 已登录用户浏览设置中心
- **THEN** UI MUST NOT 提供进入功能开通中心的入口

## ADDED Requirements

### Requirement: Client SHALL NOT register redirect-only stubs for retired commercial routes

The client MUST NOT register GoRouter routes whose sole purpose is redirecting `/companion`, `/prediction/alert`, `/prediction/ai-analysis` (including `feeding` / `growth` children), or `/vip/purchase` to `/home`. The live `/pangbao` deep link (navigate home and request prediction pager) MUST remain. Unmatched retired paths MUST NOT render the retired product screens.

客户端 **不得** 再为上述退休商业路径注册仅 redirect 的 GoRoute；**必须** 保留仍有业务副作用的 `/pangbao`；未匹配路径 **不得** 渲染已退休产品页。

#### Scenario: 路由表无退休 stub

- **WHEN** 客户端路由表构建完成
- **THEN** MUST NOT 注册 `/companion`、`/prediction/alert`、`/prediction/ai-analysis`（含子路径）、`/vip/purchase` 的 redirect-only GoRoute
- **AND** MUST 仍注册带切预测页副作用的 `/pangbao`（或等价）

#### Scenario: 旧 VIP 购页路径

- **WHEN** 深链打开 `/vip/purchase`
- **THEN** 客户端 MUST NOT 渲染 VIP 购买产品页
