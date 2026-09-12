## ADDED Requirements

### Requirement: Client SHALL expose a shared VIP status settlement API

The client MUST provide a single shared API (e.g. `ensureVipSettled`) that resolves the current account VIP status from `GET /cash/app/api/vip/status` (or an equivalent already-loaded settled cache). Concurrent callers MUST share one in-flight load (single-flight). When a settled successful or fail-closed result already exists and `force` is false, the API MUST return promptly without starting a duplicate request. When the user is logged out, the API MUST treat VIP as not applicable (non-VIP / null) without requiring a network call. Future features that branch side-effect HTTP or skip logic on `isVip` MUST call this API (or an equivalent that awaits the same in-flight) before reading `isVip` for that decision. Widget `build` MUST NOT call this API in a way that synchronously mutates provider state during build.

客户端 **必须** 提供共享 VIP settle API（如 `ensureVipSettled`），以 `vip/status` 或已 settled 缓存解析当前账号 VIP；并发 **必须** single-flight；已有 settled 且非 force 时 **必须** 快速返回；未登录 **必须** 视为非 VIP/不适用且 **不必** 网络请求。后续凡用 `isVip` 分支副作用 HTTP/跳过逻辑的功能 **必须** 先调用该 API（或 awaiting 同一 in-flight 的等价物）。Widget `build` **不得** 以会在 build 期间同步改 provider state 的方式调用。

#### Scenario: 并发 ensure 合并

- **WHEN** 两处副作用几乎同时首次需要 VIP 状态且尚无 settled 结果
- **THEN** 客户端 MUST 只发起至多一次 in-flight `vip/status`（或合并到同一 Future）

#### Scenario: 已 settled 秒回

- **WHEN** VIP 状态已成功或 fail-closed settled 且调用方未要求 force
- **THEN** `ensureVipSettled` MUST 立即返回已有结果且 MUST NOT 再开重复 HTTP

#### Scenario: 后续功能遵循同一规则

- **WHEN** 新增功能在副作用路径用 `isVip` 决定是否请求或跳过
- **THEN** 该路径 MUST 在分支前 await 共享 settle API（或等价）
- **AND** MUST NOT 仅在某一页面 `initState` 复制一套互不共享的 await

#### Scenario: 未登录

- **WHEN** 会话未登录时调用 settle API
- **THEN** 客户端 MUST 返回非 VIP/不适用语义且 MUST NOT 依赖成功的 `vip/status` 响应

### Requirement: Startup splash MUST NOT await VIP status

Cold-start branding overlay / `_runColdStart` MUST NOT `await` VIP status settlement before navigating to the post-login home route. The client MAY kick VIP load after login without blocking splash dismissal. Lengthening the splash solely to wait for `vip/status` is forbidden.

冷启动品牌遮罩 / `_runColdStart` **不得** 在进入主页路由前 `await` VIP settle；登录后 **可以** kick 预热且 **不得** 仅因等待 `vip/status` 而延长遮罩展示。

#### Scenario: 遮罩不堵 VIP

- **WHEN** 已登录用户冷启动完成本地 restore/hydrate
- **THEN** 客户端 MUST 可在 VIP HTTP 完成前关闭启动遮罩并进入主页路由
- **AND** MUST NOT 以 await `vip/status` 作为关闭遮罩的前置条件

### Requirement: Side-effect entitlement gates MUST use settled VIP

When a non-click side-effect path (Riverpod ensure, lifecycle bundle, or equivalent) evaluates `isVip` to decide effective catalog unlock (`unlocked || isVip`), to skip or proceed with gated HTTP, or to apply VIP override behavior, the client MUST await VIP settlement first. The client MUST NOT treat an in-flight / unset Async VIP value as definitive non-VIP for those side-effect decisions. After settlement failure, the client MAY fail-closed as non-VIP. Pure UI rebuild that only displays derived state MAY continue to watch VIP without awaiting, provided it does not fire gated side-effect HTTP from `build`.

非点击副作用路径用 `isVip` 做有效开通、跳过/发起门闸 HTTP、或 VIP 覆盖时，客户端 **必须** 先 await VIP settle；**不得** 把进行中/未设置的 Async VIP 当作副作用上的确定非 VIP。settle 失败后 **可以** fail-closed 为非 VIP。仅展示的 UI watch **可以** 不等待，但 **不得** 从 `build` 触发门闸副作用 HTTP。

#### Scenario: 副作用分支前已 settle

- **WHEN** care-alert 或其它权益 ensure 即将根据 `isVip` 决定是否拉下游 API
- **THEN** 该 ensure MUST 已 await 共享 VIP settle
- **AND** 用于分支的 `isVip` MUST 来自 settle 结果（含 fail-closed）

#### Scenario: build 不发门闸 HTTP

- **WHEN** 预测页或其它页面正在 `build`
- **THEN** 客户端 MUST NOT 在 `build` 同步路径调用会立即 `state=` 的 catalog/VIP ensure 作为门闸副作用
