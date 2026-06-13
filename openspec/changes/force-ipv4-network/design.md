## Context

- **现状**：客户端 HTTP 经 `package:http`（底层 `dart:io` `HttpClient`），WebSocket 经 `web_socket_channel` → `WebSocket.connect`；均无自定义 `connectionFactory`，依赖系统双栈 DNS（A + AAAA）与 Happy Eyeballs 竞速。
- **痛点**：部分网络环境 IPv6 不可达或极慢，导致 `ApiClient` 请求超时、历史/UCG/语音 WS `connect failed`；换 4G 或关闭 IPv6 后恢复。
- **散落出口**：`ApiClient`、`session_controller`、`IosNetworkPermissionProbe`、`event_catalog_store`（`HttpClient`）、`ucg_repository`（OSS PUT）、三条 `WebSocketChannel.connect`——均走 `dart:io`，可被全局 `HttpOverrides` 统一影响。
- **不可控出口**：`NetworkImage` / `UcgNetworkImage`、CDN、`video_player`、`fluwx` 走 Flutter/原生栈；Web 端由浏览器决定，应用层无法强制 IPv4。
- **约束**：最小改动（方案 A）；默认行为不变；不新增第三方依赖。

## Goals / Non-Goals

**Goals:**

- 原生端（Android/iOS）在 `FORCE_IPV4=true` 时，所有经 `dart:io` `HttpClient` / `WebSocket.connect` 的出站连接 MUST 仅解析并连接 IPv4 地址。
- 在 `main()` 启动最早阶段安装全局覆盖，业务 Repository 无需改签名。
- 提供 `AppEnv.forceIpv4` 编译时常量，便于 CI/联调文档引用。
- 默认 `FORCE_IPV4=false`，与变更前行为一致。

**Non-Goals:**

- 强制 CDN（`resorce.cuplay.top`）或 `video_player` 走 IPv4。
- Web 构建支持（`kIsWeb` 跳过）。
- 运行时设置页开关（仅 `--dart-define` 编译期开关）。
- 按域名白名单选择性强制（首版全局 IPv4-only，网关与 OSS 同策略）。
- 服务端 DNS / AAAA 记录治理。

## Decisions

### 1. 方案 A：`HttpOverrides.global` + `connectionFactory`

**Decision**：`ForceIpv4HttpOverrides` 在 `connectionFactory` 中仅 `lookup(IPv4)`；**HTTP** 走 `Socket.startConnect`；**HTTPS/WSS** 在 TCP 连上 IPv4 后显式 `SecureSocket.secure(raw, host: 原域名)` 以保证 SNI 与证书校验用域名而非 IP（避免严格网关握手失败）。多 A 记录依次尝试；`HttpClient.connectionTimeout = 10s`。

**Why**：初版仅 `Socket.startConnect(ip)` 交由 `HttpClient` 升级 TLS 时，SNI 可能错误为 IP，导致全接口挂起且无日志；阿里云 HTTPDNS Flutter 实践与 dart-lang/http#1161 均要求 HTTPS 手动 `secure(..., host: domain)`。

**Alternatives**：

- **初版（已废弃）**：`return Socket.startConnect(addresses.first, port)` — test 环境验证失败。

### 2. 安装时机：`main()` + `kIsWeb` / `dart:io` 守卫

**Decision**：`app/lib/main.dart` 在 `WidgetsFlutterBinding.ensureInitialized()` 之后：

```dart
if (!kIsWeb && AppEnv.forceIpv4) {
  HttpOverrides.global = ForceIpv4HttpOverrides();
}
```

文件通过条件 import 或 `force_ipv4_http_overrides_stub.dart` 避免 Web 编译引用 `dart:io`。

**Why**：必须在首包 HTTP/WS 之前生效；与 `IosNetworkPermissionProbe` 同级 bootstrap 模式。

### 3. 编译开关：`AppEnv.forceIpv4`

**Decision**：`bool.fromEnvironment('FORCE_IPV4', defaultValue: false)`。

**Why**：生产默认可保持双栈；问题网络联调/发版时 `flutter run/build --dart-define=FORCE_IPV4=true`；与现有 `API_BASE_URL` 等 env 模式一致。

**Alternatives**：默认 `true` — 可能影响 IPv6-only 网络（极少），且改变全局默认行为，不采纳。

### 4. WebSocket 不单独传 `customClient`

**Decision**：依赖 `WebSocket.connect` 默认创建 `HttpClient()` 时读取全局 `HttpOverrides`，不在 `RemoteFeedRepository` / `UcgRepository` / `VoiceAsrWsClient` 逐处改代码。

**Why**：Dart SDK 文档：`WebSocket.connect` 在未提供 `customClient` 时使用带 `HttpOverrides` 的 `HttpClient`；WS 升级请求的 TCP 连接走同一 `connectionFactory`。

**验证点**：实现后手工确认三条 WS 在 `FORCE_IPV4=true` 下握手成功。

### 5. 模块位置：`app/lib/bootstrap/force_ipv4_http_overrides.dart`

**Decision**：与 `ios_network_permission_probe.dart` 并列；stub 文件供 Web 树编译。

**Why**：bootstrap 层职责清晰；`main.dart` 仅一行安装调用。

## Risks / Trade-offs

- **[Risk] 主机无 A 记录** → 连接抛 `SocketException`；网关/OSS 须保证有 IPv4 A 记录（当前生产域名满足）。
- **[Risk] TLS 连 IP 但校验域名证书** → `HttpClient` 默认仍用原 URI host 做 SNI，一般可行；实现后需 HTTPS + WSS 真机抽测。
- **[Risk] 代理环境** → `connectionFactory` 需保留 `proxyHost`/`proxyPort` 分支（若未来启用）；首版按直连实现，企业代理场景可能需后续增强。
- **[Risk] CDN/图片仍走 IPv6** → 文档与 spec 明确非目标；若图片失败需运维或自定义 `ImageProvider`，不在本 change。
- **[Trade-off] 全局强制 vs 按域** → 首版全局简化实现；OSS PUT 与网关同策略，一般同为 IPv4 可达。

## Migration Plan

1. 合并代码后默认构建 **无行为变化**（`FORCE_IPV4` 默认 false）。
2. 问题网络验证：`flutter run --dart-define=FORCE_IPV4=true` 真机抽测 API + 三条 WS。
3. 若验证通过，可在 CI/release 渠道（如特定 APK 渠道）通过 build 参数开启；回滚则去掉 dart-define 或设为 false。
4. README / `app/README.md` 可选补充一行 dart-define 说明（tasks 中列为文档任务，非阻塞）。

**联调结论（2026-06-13）**：初版 `connectionFactory` 直连 IP 时网关静默丢弃；修复 HTTPS SNI 后 API 恢复。图片展示走 Flutter 引擎，不在本 change 范围；不追加 `[NetworkImage]` 诊断日志。

## Open Questions

- 是否需要在验证稳定后将 `FORCE_IPV4` 默认改为 `true`？（当前 proposal 保持 false，待运营反馈。）
- OSS 上传域名（presign 返回的 host）是否保证 A 记录？若个别区域仅 AAAA，强制 IPv4 会导致上传失败——需上线前核对 presign 域名。
