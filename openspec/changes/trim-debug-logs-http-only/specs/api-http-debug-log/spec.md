## ADDED Requirements

### Requirement: Debug builds SHALL emit only ApiHttpLog for network diagnostics

In `kDebugMode`, the Flutter app MUST NOT emit console diagnostic output for WebSocket connections, home history cache/sync, voice ASR, UCG media, push registration, event catalog, or IPv4 overrides. The ONLY permitted console network diagnostic logs MUST be those from `ApiHttpLog` invoked by `ApiClient` (and its multipart path), prefixed with `[ApiHttp]`.

Debug 构建下 MUST NOT 向控制台输出 WS、主页历史、语音、UCG 等诊断日志；唯一允许的网络诊断输出 MUST 为 `ApiClient` 触发的 `[ApiHttp]` 日志。

#### Scenario: Debug 运行无 HomeHistory 日志

- **WHEN** 开发者在 debug 模式下打开主页并触发历史加载/刷新
- **THEN** 控制台 MUST NOT 出现 `[HomeHistory]` 前缀日志

#### Scenario: Debug 运行无 WebSocket 连接日志

- **WHEN** 开发者在 debug 模式下建立 history 或 ucg-chat WebSocket
- **THEN** 控制台 MUST NOT 出现 `history connect` / `ucg-chat` 等 WS 调试行

### Requirement: ApiHttpLog lines SHALL include ISO8601 timestamps

Each `ApiHttpLog` request, response, and 401-retry line MUST prefix an ISO8601 timestamp with millisecond precision before the `[ApiHttp]` marker or immediately after it in the form `[ApiHttp] <timestamp> …`.

每条 `[ApiHttp]` 日志 MUST 含 ISO8601 毫秒时间戳。

#### Scenario: HTTP 请求日志含时间

- **WHEN** `ApiClient` 在 debug 模式发起 `GET /ucg/app/api/...`
- **THEN** 控制台 SHALL 输出一行含 ISO8601 时间戳与 `→ GET` 的请求日志

#### Scenario: HTTP 响应日志含时间

- **WHEN** 上述请求返回 HTTP 200
- **THEN** 控制台 SHALL 输出一行含 ISO8601 时间戳、`← 200` 与耗时毫秒数的响应日志

### Requirement: ApiHttpLog SHALL retain redaction and kDebugMode guard

`ApiHttpLog` MUST continue to no-op outside `kDebugMode` and MUST redact sensitive headers and JSON body keys (Authorization, tokens, password, etc.) as implemented before this change.

`ApiHttpLog` MUST 仅在 `kDebugMode` 输出，并 MUST 保持既有脱敏规则。

#### Scenario: Release 无 HTTP 日志

- **WHEN** 应用以 release/profile 模式运行并发 HTTP 请求
- **THEN** 控制台 MUST NOT 输出 `[ApiHttp]` 日志

#### Scenario: Authorization 脱敏

- **WHEN** debug 模式下请求带 Bearer token
- **THEN** 请求日志 MUST 显示 `Authorization=Bearer ***` 而非明文 token
