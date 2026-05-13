## Why

网关 JSON 与客户端请求体在部分接口上混用 `snake_case`（如 `device_no`、`access_token`）与 **camelCase**（如 `deviceNo`），增加联调成本且与产品约定「统一采用 `deviceNo` 风格（camelCase）」不一致。需要在客户端与文档层面对齐命名，并与后端确认契约。

## What Changes

- **出站（请求体 / query / WebSocket 首包）**：凡发往 `API_BASE_URL` 及同源 WebSocket 的 JSON 字段，统一为 **camelCase**；修正当前已知的 snake 写法（例如 `device_login` 的 `device_no` → `deviceNo`，历史 WebSocket 鉴权里的 `access_token` → `accessToken` 等，以排查清单为准）。
- **入站（解析响应 envelope `data`）**：以 **camelCase 为主**读取；是否 **删除** 对 `device_no`、`access_token`、`download_url` 等 snake 的兼容分支，由与后端对齐结果决定——若后端已全量 camelCase，则删除 fallback 为 **BREAKING** 于「仍返回 snake 的旧网关」。
- **UI 文案与注释**：用户可见文案中的「字段名说明」改为与网关一致的 camelCase（如「胖宝号（deviceNo）」），避免继续写 `device_no`。
- **README / OpenSpec**：补充「网关 JSON 命名约定」条目，便于后续 PR 审查。

## Capabilities

### New Capabilities

- `api-gateway-json-keys`：定义客户端与网关之间 JSON 字段采用 camelCase 的规范范围（HTTP 与 WebSocket）、出站修正与入站解析策略。

### Modified Capabilities

- （无）仓库内尚无已归档到 `openspec/specs/` 根目录的独立 spec 文件名；本变更以新能力 spec 承载。

## Impact

- **Dart**：`remote_auth_repository.dart`、`remote_feed_repository.dart`（WebSocket 首帧）、`remote_version_repository.dart`、`remote_settings_repository.dart`、`baby_bind_screen.dart`、`session/session_controller.dart`、`data/history_mapper.dart` 等；可能新增小型 `api_json_keys.dart` 辅助函数（可选）。
- **后端**：`device_login`、WS `auth` 等若当前仍只认 snake，需同步升级为认 camelCase 或双写；否则客户端单独改会导致 **BREAKING**。
