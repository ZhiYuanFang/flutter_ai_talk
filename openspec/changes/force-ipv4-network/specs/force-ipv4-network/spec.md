## ADDED Requirements

### Requirement: Native builds SHALL optionally force IPv4 for dart:io HTTP and WebSocket connections

When `FORCE_IPV4` is `true` at compile time, Android and iOS native builds MUST install a global `HttpOverrides` that resolves outbound hostnames with `InternetAddressType.IPv4` only and MUST NOT attempt IPv6 for connections created through `dart:io` `HttpClient` or `WebSocket.connect`. 编译期 `FORCE_IPV4=true` 时，Android/iOS 原生构建必须通过全局 `HttpOverrides` 仅使用 IPv4 解析并建立 `HttpClient` 与 `WebSocket.connect` 的 TCP 连接，不得回退 IPv6。

#### Scenario: FORCE_IPV4 开启时安装覆盖

- **WHEN** 应用运行于 Android 或 iOS 且 `AppEnv.forceIpv4` 为 true
- **THEN** `main()` 在首包网络请求之前 MUST 设置 `HttpOverrides.global` 为 IPv4-only 实现

#### Scenario: 默认构建保持双栈

- **WHEN** 未传入 `FORCE_IPV4` 或其为 false
- **THEN** App MUST NOT 安装 `ForceIpv4HttpOverrides`，且网络行为与变更前一致

#### Scenario: Web 平台不安装

- **WHEN** 应用运行于 Web（`kIsWeb`）
- **THEN** App MUST NOT 引用 `dart:io` 或安装 `HttpOverrides`

### Requirement: IPv4-only override MUST cover gateway HTTP and WebSocket without repository API changes

The IPv4-only `HttpOverrides` MUST affect existing `package:http` calls (including `ApiClient`, `session_controller`, `IosNetworkPermissionProbe`, and `ucg_repository` OSS PUT) and `WebSocketChannel.connect` used for history, UCG chat, and voice ASR, without changing public method signatures on those repositories. IPv4-only 覆盖必须作用于现有 `package:http` 与三条 WebSocket 建连路径，且不得修改 Repository 对外方法签名。

#### Scenario: ApiClient 请求走 IPv4

- **WHEN** `FORCE_IPV4=true` 且 `ApiClient` 请求 `AppEnv.apiBaseUrl` 下路径
- **THEN** 底层 TCP 连接 MUST 仅使用目标主机 A 记录解析出的 IPv4 地址

#### Scenario: 历史 WebSocket 走 IPv4

- **WHEN** `FORCE_IPV4=true` 且 `RemoteFeedRepository` 连接 `wsHistoryUrlEffective`
- **THEN** WebSocket 升级请求的 TCP 连接 MUST 仅使用 IPv4

#### Scenario: UCG 与语音 WebSocket 走 IPv4

- **WHEN** `FORCE_IPV4=true` 且 `UcgRepository` 或 `VoiceAsrWsClient` 建立 WebSocket
- **THEN** 连接 MUST 仅使用 IPv4，与历史 WS 策略一致

### Requirement: AppEnv SHALL expose forceIpv4 compile-time flag

`AppEnv` MUST define `forceIpv4` as `bool.fromEnvironment('FORCE_IPV4', defaultValue: false)` for use at startup and in build documentation. `AppEnv` 必须提供 `forceIpv4` 编译期常量，默认 false。

#### Scenario: dart-define 注入

- **WHEN** 构建命令包含 `--dart-define=FORCE_IPV4=true`
- **THEN** `AppEnv.forceIpv4` MUST 为 true

#### Scenario: 未注入时默认 false

- **WHEN** 构建命令未包含 `FORCE_IPV4`
- **THEN** `AppEnv.forceIpv4` MUST 为 false

### Requirement: Flutter engine and third-party native network stacks are out of scope

`FORCE_IPV4` MUST NOT be documented or implemented as affecting `NetworkImage` / `UcgNetworkImage`, `video_player` network URLs, or `fluwx` SDK traffic. `FORCE_IPV4` 不得声称或实现为覆盖 Flutter 引擎图片加载、视频播放或微信 SDK 的网络栈。

#### Scenario: CDN 图片不受 HttpOverrides 影响

- **WHEN** `FORCE_IPV4=true` 且界面加载 `resorce.cuplay.top` 等 CDN `UcgNetworkImage`
- **THEN** 图片请求 MAY 仍使用平台默认双栈解析（非本能力保证范围）
