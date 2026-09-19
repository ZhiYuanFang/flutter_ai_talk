## Why

喂养分析次数用尽时，服务端已经返回「今日值得留意分析次数已用完，请明日再来」，客户端却 Toast「分析失败，请稍后重试」。日限等预检在 SSE 头写出之前失败，Go 按项目惯例回 HTTP 200 的 `{code, message}`；流式客户端只在非 200 时读 `message`，把这段 JSON 当成空 SSE 丢掉。成长轨迹 turn 是同一条缝。

## What Changes

- 喂养分析 SSE（`GET /device/api/care-alert/daily/stream`）在 HTTP 200 且响应为业务 envelope（`code != 0`）时，MUST Toast 服务端 `message`，不得再落到「分析失败，请稍后重试」。
- 成长轨迹 turn SSE 对同一类预检 envelope MUST Toast 服务端 `message`，不得再落到本地通用失败文案。
- 不改 Go 状态码，不改日限规则，不改思考流协议。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-care-alert`：手动分析失败时，预检业务 envelope 的 `message` 必须原样 Toast。
- `growth-trajectory-predict`：日限/预检业务 envelope 的 `message` 必须原样 Toast（补上 HTTP 200 壳这条路径，与既有「日限错误 Toast」对齐）。

## Impact

- Flutter：`app/lib/data/care_alert_repository.dart`、`app/lib/data/growth_trajectory_repository.dart`；必要时共享 envelope 解析。
- 调用方 Toast 已透传 repository/provider 返回的文案，不必改 UI 文案表。
- 不改 Go / Python，不改 WebSocket，不新增测试文件。
