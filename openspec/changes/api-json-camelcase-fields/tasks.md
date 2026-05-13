## 1. 审计与对齐

- [x] 1.1 全仓检索 `device_no`、`access_token`、`refresh_token`、`download_url` 等 snake 与 JSON 字面量，形成「出站 / 入站」对照表（含 `remote_*`、`session_controller`、`history_mapper`、`baby_bind_screen`、WebSocket 首包）。
- [x] 1.2 与后端确认：`device_login`、刷新 token、版本检查、历史相关接口及 WebSocket `auth` 的**正式键名**与兼容期（是否仍返回 snake）。（**说明**：以 README「网关 JSON 字段命名」与「后端对齐」为准；入站保留 `readGatewayStr` snake 回退直至网关公告。）

## 2. 出站（客户端 → 网关）

- [x] 2.1 将 `device_login` 请求体键由 `device_no` 改为 **`deviceNo`**（`RemoteAuthRepository`）。
- [x] 2.2 将 WebSocket 首帧中的 `access_token` 改为 **`accessToken`**（`RemoteFeedRepository`）；确认网关鉴权帧 schema。
- [x] 2.3 回归检查其余 `postJsonEnvelope` / `getEnvelope` query 已为 camelCase（`bindwx`、`chat`、`list` 等）。

## 3. 入站（网关 → 客户端）

- [x] 3.1 按设计「阶段 A/B」调整 `_persistLoginData`、`session_controller.trySilentRefresh`、`remote_version_repository`、`history_mapper`、各 `data?['deviceNo']` 等：优先 camel；兼容期内可抽公共读取函数并标 TODO。
- [x] 3.2 若后端已全 snake 下线，删除 snake 回退并更新 README 声明 **BREAKING** 依赖网关版本。（**本阶段不执行删除**：仍为阶段 A，README 已说明；待网关全 camel 后再删 `readGatewayStr` 的 snake 参数。）

## 4. 文档与 UI

- [x] 4.1 更新 `AuthRepository` 注释、`login_screen` 文案、`README` 网关命名约定小节。
- [x] 4.2 `dart analyze lib` 无 error；关键路径（登录、刷新、版本检查、历史 WS、发指令）联调一次。
