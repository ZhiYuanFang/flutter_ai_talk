## ADDED Requirements

### Requirement: Client SHALL NOT expose feature unlock hub as a product surface

The client MUST NOT present a user-reachable「功能开通」hub screen (`FeatureUnlockHubScreen` or equivalent at `/features/unlock`). Settings MUST NOT navigate to that hub. Deep links or stale routes to `/features/unlock` MUST redirect to a safe logged-in home (e.g. `/home`) without rendering the hub. Predict Pro payment and trial MUST NOT depend on opening this hub.

客户端 **不得** 再提供可达的功能开通中心页；设置 **不得** 跳转该页；深链 MUST 安全回退；Pro 支付/试用 **不得** 依赖打开 Hub。

#### Scenario: 无 Hub 路由页

- **WHEN** 用户尝试打开 `/features/unlock`
- **THEN** 客户端 MUST NOT 渲染功能开通中心列表页
- **AND** MUST 回退至安全主页（或等价非 Hub 页）

#### Scenario: 设置无跳转 Hub

- **WHEN** 已登录用户浏览设置中心
- **THEN** UI MUST NOT 提供进入功能开通中心的入口

## REMOVED Requirements

### Requirement: Unlock hub SHALL list predict Pro shell without basic or VIP sticky

**Reason**: 开通中心产品面已退休；Pro 试用与付费改由「接下来3小时」两档墙承载。

**Migration**: 见 `predict-free-pro-chrome` 墙内试用/直付；catalog 仍可加载 Pro 项供墙使用。
