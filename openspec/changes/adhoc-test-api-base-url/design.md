# Design: ad-hoc 测试 API 基址

## Decision

在 `ios-build-core.yml` 的 **Build signed IPA** 步骤中，根据 `TARGET_CHANNEL` 分支注入 dart-define：

| `target_channel` | `API_BASE_URL` |
|------------------|----------------|
| `adhoc` | `https://test.pangbao.cuplay.top`（写死在 workflow） |
| `testflight` / `appstore` | 不注入（使用 `AppEnv` 默认生产基址） |

## Rationale

- 与 Docker Web 构建已有的 `API_BASE_URL` dart-define 模式一致。
- `WS_HISTORY_URL`、`WS_VOICE_ASR_URL`、用户协议/隐私 URL 由 `apiBaseUrl` 自动推导，无需额外参数。
- 测试域写死在 workflow，避免新增 Secret；域名变更时改 workflow 即可。

## Out of scope

- 测试环境独立微信 Universal Link / Associated Domains。
- TestFlight 或 App Store 使用测试域。
