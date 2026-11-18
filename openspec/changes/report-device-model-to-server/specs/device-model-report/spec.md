## ADDED Requirements

### Requirement: Logged-in client MUST report device model string to server

The client SHALL, after a valid Bearer session is established on Android or iOS, resolve a human-display device model string via `device_info_plus` (or equivalent) and call `PUT /device/app/api/user/device-model` with JSON body `{ "deviceModel": "<string>" }`. The string MUST be trimmed, MUST NOT contain `|` (replace with `/` if needed), and MUST be at most 128 characters. On Android the string SHOULD include brand (or manufacturer) and model when available (e.g. `Xiaomi 2201123G`). On iOS the string MUST be a marketing name resolved from `utsname.machine` via a client-side map (e.g. `iPhone 12`, `iPad Air 2`); if the map misses, the client MUST treat resolution as failed and MUST NOT call the API (MUST NOT upload raw hardware identifiers such as `iPhone13,2`). The server MUST receive the client string as-is for display; the client MUST NOT require a server-side brand enum. Failures MUST be silent (debug log only, no user-visible error). Unauthenticated sessions MUST NOT call the API. Web (and platforms where model cannot be resolved) MUST skip the call. Provider create MUST NOT automatically invoke the report.

客户端在 Android/iOS 已登录会话下 MUST 解析机型展示字符串并调用上述 PUT；Android 宜含品牌+型号；iOS MUST 仅为营销名，map 失败 MUST NOT 上报硬件码；失败静默；未登录与 Web MUST NOT 调用；provider 创建 MUST NOT 自动上报。

#### Scenario: 登录后上报

- **WHEN** 用户在 Android/iOS 完成登录且解析到非空型号（如 `Xiaomi 2201123G`）
- **THEN** 客户端 MUST 异步调用 `PUT /device/app/api/user/device-model` 且 body 含该 `deviceModel`，MUST NOT 因上报阻塞登录成功 UI

#### Scenario: 未登录不报

- **WHEN** 当前无有效登录会话
- **THEN** 客户端 MUST NOT 调用 device-model 上报接口

#### Scenario: Web 跳过

- **WHEN** 运行平台为 Web 或无法解析型号
- **THEN** 客户端 MUST NOT 调用该上报接口

#### Scenario: iOS map 未命中不报硬件码

- **WHEN** iOS 设备 `utsname.machine` 不在客户端营销名映射表中
- **THEN** 客户端 MUST NOT 调用 device-model 上报接口，且 MUST NOT 将 `iPhone13,2` 类硬件码写入请求

#### Scenario: 上报失败静默

- **WHEN** 上报返回业务错误、HTTP 错误或网络失败
- **THEN** 客户端 MUST NOT 向用户展示 Toast/对话框，仅可写 Debug 日志

### Requirement: Device model report MUST be locally throttled per account

The client SHALL key throttle state by the logged-in account identity from JWT `sub` (`wxId`) together with the last successfully reported model and success timestamp (persisted locally). If for the same `wxId` the resolved model equals the last success value and the last success was within 24 hours, the client MUST NOT call the API again. When `wxId` changes or the resolved model changes, the client MAY report immediately (still fire-and-forget). Concurrent calls MUST be single-flight. Repeated failures MUST apply a short cooldown circuit-break before retrying.

客户端 MUST 按账号（JWT wxId）节流：同账号同型号成功后 24h 内不重复；换号或型号变化可再报；并发 MUST single-flight；失败 MUST 短熔断。

#### Scenario: 24 小时内同账号同值不重复

- **WHEN** 同一 `wxId` 在 1 小时前已成功上报 `Huawei ALN-AL10` 且本次解析仍为该值
- **THEN** 客户端 MUST NOT 再次发起 PUT

#### Scenario: 换号可再报

- **WHEN** 本机上一成功上报属于账号 A，当前登录为账号 B，且解析到非空型号
- **THEN** 客户端 MUST 允许为账号 B 发起 PUT（不得因账号 A 的 24h 窗跳过）
