## ADDED Requirements

### Requirement: UCG entry gate SHALL lock square until eligibility is qualified

When the user navigates to the UCG home pager page and `GET /cash/app/api/ucg/eligibility` reports `qualified=false` (or the gate cannot confirm qualification), the client MUST allow the PageView swipe to mount `UcgShell` and MUST present a full-screen lock overlay that blocks interaction with the square feed. The overlay MUST show feeding-day progress from the eligibility response (`requiredDays`, `effectiveDays`, `remainingDays`, and `message` when present). The overlay MUST provide「返回预测页」navigating the home pager to prediction. When `qualified=true`, the client MUST NOT show the full-screen lock. The client MUST NOT clear the UCG lock solely because `isVip` is true or because a catalog feature is unlocked.

当用户进入 UCG 且 eligibility 未合格（或无法确认合格）时，客户端 **必须** 允许横滑挂载 `UcgShell` 并展示全屏锁与天数进度，并 **必须** 提供「返回预测页」。`qualified=true` 时 **必须 NOT** 展示全屏锁。**不得** 仅因 `isVip` 或 catalog 已开通而解除 UCG 锁。

#### Scenario: 未合格时滑入广场见全屏锁

- **WHEN** 用户从预测页横滑进入 UCG 且 `qualified=false`
- **THEN** 客户端 MUST 挂载 UCG 壳并展示全屏锁定浮层
- **AND** MUST 展示 API 返回的天数信息（或等价 N/X/Y 拼装）
- **AND** MUST 阻断广场 Feed 操作

#### Scenario: 返回预测页

- **WHEN** 用户在 UCG 全屏锁上点击「返回预测页」
- **THEN** 主壳 PageView MUST 回到预测页

#### Scenario: 合格后无全屏锁

- **WHEN** eligibility 返回 `qualified=true`
- **THEN** 进入 UCG 时 MUST NOT 展示全屏锁定浮层

#### Scenario: VIP 不能绕过 UCG 门槛

- **WHEN** `isVip=true` 且 `qualified=false`
- **THEN** 进入 UCG 时 MUST 仍展示全屏锁定浮层

### Requirement: UCG lock gate SHALL NOT request location or load square feed until qualified

While the UCG entry gate is locked (`qualified` is not true, including loading and fail-closed states), the client MUST NOT request device location permission for the square, MUST NOT call `ensureUcgLocationForDistance` (or equivalent) from the locked square surface, and MUST NOT refresh the square recommended/following feed. The underlay `UcgShell` MAY remain mounted for blur sampling, but MUST gate those side effects until `qualified=true`. When eligibility becomes qualified, the client MAY then request location and load the feed as on a normal square entry. Compose / history-sync location paths outside the locked gate MUST NOT be blocked by this rule.

UCG 入场锁未解除（含校验中与 fail-closed）时，客户端 **必须 NOT** 为广场请求定位权限、**必须 NOT** 从锁定广场面触发定位 ensure、**必须 NOT** 刷新广场 Feed；锁下挂载的壳 **必须** 闸住上述副作用，直至 `qualified=true`。发帖/历史同步等闸门外路径不受本条阻断。

#### Scenario: 未合格滑入不弹定位

- **WHEN** 用户滑入 UCG 且 `qualified=false`（或尚未确认为合格）
- **THEN** 客户端 MUST NOT 弹出定位权限/rationale
- **AND** MUST NOT 发起依赖定位的广场 Feed 刷新

#### Scenario: 合格后才允许广场定位与拉 Feed

- **WHEN** eligibility 变为 `qualified=true` 且用户在 UCG 广场面
- **THEN** 客户端 MAY 按既有广场逻辑请求定位并加载 Feed

### Requirement: UCG gate progress SHALL be cache-first then async refresh keyed by deviceNo

The client MUST key eligibility cache by the current `deviceNo`. On entering the gated UCG surface, the client MUST render from cache first when available, then MUST refresh asynchronously from `GET /cash/app/api/ucg/eligibility`. Concurrent automatic refreshes MUST be single-flight; repeated failures MUST circuit-break. Provider create MUST NOT auto-fire eligibility HTTP without session activation or navigation into UCG. On eligibility HTTP failure, the client MUST NOT treat the user as qualified (fail-closed UX).

客户端 **必须** 以 `deviceNo` 键控 eligibility 缓存；进入 UCG 时 **必须** 缓存优先再异步刷新；**必须** single-flight/熔断；接口失败时 **不得** 当作已合格放行。

#### Scenario: 有缓存先展示再刷新

- **WHEN** 本地存在该 `deviceNo` 的 eligibility 缓存且用户进入 UCG 闸门态
- **THEN** 全屏锁 MUST 先用缓存天数渲染
- **AND** MUST 异步请求最新 eligibility 并更新展示

#### Scenario: 切换宝宝换键

- **WHEN** 当前 `deviceNo` 从 A 变为 B
- **THEN** 闸门展示 MUST 使用 B 的缓存/接口数据

#### Scenario: 接口失败不放行

- **WHEN** eligibility 请求失败且无可用的合格缓存
- **THEN** 客户端 MUST NOT 解除全屏锁放行广场
