## MODIFIED Requirements

### Requirement: UCG gate progress SHALL be cache-first then async refresh keyed by deviceNo

The client MUST key eligibility cache by the current `deviceNo`. On entering the gated UCG surface **or** when the home shell enters / shows the smart-prediction page (so a qualified square EdgeDock ball can appear without first swiping into UCG), the client MUST render from cache first when available, then MUST refresh asynchronously from `GET /cash/app/api/ucg/eligibility` via `ensureLoaded` (or equivalent). Concurrent automatic refreshes MUST be single-flight; repeated failures MUST circuit-break. Provider create MUST NOT auto-fire eligibility HTTP solely on provider construction without session/home activation or an explicit enter-prediction / enter-UCG path. On eligibility HTTP failure, the client MUST NOT treat the user as qualified (fail-closed UX). Full-screen lock, VIP non-bypass, and location/feed gating while locked remain unchanged.

客户端 **必须** 以 `deviceNo` 键控 eligibility 缓存；进入 UCG **或** 主壳进入/展示预测页时 **必须** 缓存优先再异步 `ensureLoaded`；**必须** single-flight/熔断；**不得** 仅因 provider 构造自动打 HTTP；接口失败时 **不得** 当作已合格放行。全屏锁 / VIP 不绕过 / 锁下定位与 Feed 闸门语义不变。

#### Scenario: 有缓存先展示再刷新

- **WHEN** 本地存在该 `deviceNo` 的 eligibility 缓存且用户进入 UCG 闸门态
- **THEN** 全屏锁 MUST 先用缓存天数渲染
- **AND** MUST 异步请求最新 eligibility 并更新展示

#### Scenario: 进入预测页也刷新 eligibility

- **WHEN** 已登录用户进入或展示主壳预测页
- **THEN** 客户端 MUST 触发 eligibility `ensureLoaded`（single-flight）
- **AND** 当随后 `qualified=true` 时预测竖屏 MAY 展示广场球（见 `ucg-square-edge-dock`）

#### Scenario: 切换宝宝换键

- **WHEN** 当前 `deviceNo` 从 A 变为 B
- **THEN** 闸门展示 MUST 使用 B 的缓存/接口数据

#### Scenario: 接口失败不放行

- **WHEN** eligibility 请求失败且无可用的合格缓存
- **THEN** 客户端 MUST NOT 解除全屏锁放行广场
