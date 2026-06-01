## Why

网关对部分资源 URL（事件 `logo`、版本检查 `downloadUrl` 等）返回**去掉域名的相对路径**（如 `/ai_talk_images/event_1.png`、`/device/app/apk/foo.apk`）。客户端须与 HTTP API 使用同一基址（`AppEnv.apiBaseUrl`）拼成可请求的绝对 URL。事件 logo 已在局部实现拼接，但 APK 更新流程仍把相对路径当无效地址；且逻辑分散，易遗漏新字段。

## What Changes

- 新增统一的网关绝对 URL 解析工具（相对路径 + `apiBaseUrl`；已是 `http(s)` 则原样返回）。
- 版本检查：解析 `downloadUrl` / `download_url` 后立即拼绝对 URL，Android「下载并安装」可正常拉取 APK。
- 事件目录：将现有 `resolveEventLogoUrl` 收敛到同一工具（行为保持：以 `apiBaseUrl` 为 origin 拼接路径）。
- 文档/README 补充：服务端可返回以 `/` 开头的相对资源路径。

## Capabilities

### New Capabilities

- `gateway-absolute-url`：相对资源路径相对 API 基址解析为绝对 URL 的规则及在 logo、APK 下载等消费点的要求。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线）与 `pangbao-api-liantiao` / `pangbao-device-login-apk-install` 中版本 `downloadUrl` 语义对齐，通过本变更 delta 明确「相对路径必须可下载」。

## Impact

- `app/lib/api/` 或 `app/lib/config/`：新建或扩展 URL 解析模块
- `app/lib/data/event_catalog_paths.dart`（改为调用统一解析）
- `app/lib/data/remote_version_repository.dart`
- （可选防御）`app/lib/ui/version_prompt.dart`
- `app/README.md` 联调说明
