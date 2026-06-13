## Why

部分运营商与校园/企业网络存在 IPv6 路由黑洞或双栈 Happy Eyeballs 优先 IPv6 导致连接超时，而同一域名 IPv4 可达。当前客户端使用 Dart 默认双栈 DNS 解析，网关 HTTP 与 WebSocket（历史、UCG 聊天、语音转写）在真机上偶发「API 超时 / WS connect failed」，换网络后恢复。需在原生端（Android/iOS）提供可开关的 IPv4-only 连接策略，避免改动业务层 API 调用代码。

## What Changes

- 新增 `HttpOverrides` 全局覆盖：在 `connectionFactory` 中对目标主机执行 `InternetAddressType.IPv4` 解析并建立 TCP 连接，覆盖 `package:http` 与 `dart:io` `WebSocket.connect` 默认路径。
- 在 `main()` 最早阶段（`WidgetsFlutterBinding.ensureInitialized` 之后）按 `--dart-define=FORCE_IPV4=true` 安装覆盖；默认 **关闭**，不改变现有联调与生产默认行为。
- 在 `AppEnv` 增加 `forceIpv4` 布尔常量，供启动与文档引用。
- **不**改动 `ApiClient`、各 Repository 方法签名；**不**覆盖 Flutter 引擎 `NetworkImage` / `video_player` / 微信 SDK 等原生网络栈。
- Web 构建 MUST NOT 安装 `HttpOverrides`（`kIsWeb` 守卫）。

## Capabilities

### New Capabilities

- `force-ipv4-network`：原生端可选 IPv4-only HTTP/WebSocket 连接策略、`FORCE_IPV4` 编译开关与启动安装时机。

### Modified Capabilities

（无。不改变对外 API 契约、路由或用户可见 UI 文案；仅网络栈连接族选择。）

## Impact

- **Affected code**：`app/lib/main.dart`；新增 `app/lib/bootstrap/force_ipv4_http_overrides.dart`（或等价路径）；`app/lib/config/env.dart` 增加 `forceIpv4`。
- **受益调用链（无需改签名）**：`ApiClient`、`session_controller` 散落 `http.*`、`IosNetworkPermissionProbe`、`event_catalog_store` 的 `HttpClient`、`ucg_repository` OSS `http.put`、三条 `WebSocketChannel.connect`（历史 / UCG / 语音 ASR）。
- **不受影响**：`UcgNetworkImage` / CDN、`video_player`、fluwx、Web 端浏览器网络。
- **风险**：目标主机无 A 记录时连接直接失败（不再回退 IPv6）；IPv6-only 网络不可用（目标用户群风险低）。
- **验证**：`FORCE_IPV4=true` 真机构建下 API、历史 WS、UCG WS、语音 WS 连通；默认构建行为与变更前一致。
