## ADDED Requirements

### Requirement: Cold start SHALL navigate unauthenticated users to home

The client MUST navigate to `/home` after local-only cold start bootstrap completes, regardless of `session.isLoggedIn`. 冷启动在本地 session restore 与主题缓存完成后，无论是否已登录，目标路由 MUST 为 `/home`；不得将未登录用户默认导向 `/login`。

#### Scenario: 未登录冷启动进主页

- **WHEN** 用户未登录且冷启动 bootstrap 完成
- **THEN** App SHALL `go('/home')`，且 SHALL NOT 默认 `go('/login')`

#### Scenario: 已登录冷启动进主页

- **WHEN** 用户已登录且冷启动 bootstrap 完成
- **THEN** App SHALL `go('/home')`（行为与变更前一致）

### Requirement: Router SHALL allow guest access to home trends and settings shell

The `go_router` redirect MUST allow unauthenticated access to `/home`, `/trends`, and `/settings` without redirecting to `/login`. 未登录用户 MUST 可访问 `/home`、`/trends`、`/settings` 壳路由；敏感账号子路由仍须登录门禁。

#### Scenario: 游客访问主页

- **WHEN** 未登录用户位于 `/home` 或冷启动后进入 `/home`
- **THEN** redirect MUST return `null`（不重定向至 `/login`）

#### Scenario: 游客访问趋势与设置

- **WHEN** 未登录用户导航至 `/trends` 或 `/settings`
- **THEN** redirect MUST 允许进入对应页面

#### Scenario: 游客访问敏感设置子路由

- **WHEN** 未登录用户直达 `/settings/bind-baby`、`/settings/change-password` 或 `/settings/feedback`
- **THEN** redirect MUST 重定向至 `/login`

#### Scenario: 已登录用户离开登录页

- **WHEN** 已登录用户位于 `/login` 或 `/register`
- **THEN** redirect MUST 重定向至 `/home`（保持既有行为）
