## 1. 统一解析工具

- [x] 1.1 新增 `app/lib/api/gateway_absolute_url.dart`：`resolveGatewayAbsoluteUrl`（基于 `AppEnv.apiBaseUrl`）
- [x] 1.2 `event_catalog_paths.resolveEventLogoUrl` 改为转调统一函数，行为不变

## 2. 版本 APK 下载

- [x] 2.1 `RemoteVersionRepository`：对 `downloadUrl` / `download_url` 解析后再写入 `androidApkUrl`
- [x] 2.2 （可选）`version_prompt` 下载前再 resolve 一次，避免遗漏入口

## 3. 文档与校验

- [x] 3.1 `app/README.md` 补充：logo、`downloadUrl` 可为相对路径，客户端拼 `API_BASE_URL`
- [x] 3.2 运行 `openspec validate gateway-relative-asset-urls --strict` 并通过
- [x] 3.3 联调：相对 `downloadUrl` 可进入下载；相对 `logo` 仍可加载
