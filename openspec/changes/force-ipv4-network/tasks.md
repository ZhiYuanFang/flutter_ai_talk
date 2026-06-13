## 1. 配置与模块

- [x] 1.1 `env.dart`：新增 `AppEnv.forceIpv4`（`bool.fromEnvironment('FORCE_IPV4', defaultValue: false)`）
- [x] 1.2 新增 `bootstrap/force_ipv4_http_overrides.dart`：IPv4-only `connectionFactory`；HTTPS/WSS 显式 `SecureSocket.secure(..., host: 原域名)` 保证 SNI；多 A 记录回退；`connectionTimeout`
- [x] 1.3 新增 `bootstrap/force_ipv4_http_overrides_stub.dart`（Web 空实现或 no-op），供条件 import

## 2. 启动安装

- [x] 2.1 `main.dart`：在 `ensureInitialized` 之后，当 `!kIsWeb && AppEnv.forceIpv4` 时设置 `HttpOverrides.global`
- [x] 2.2 使用条件 import 确保 Web 构建不引用 `dart:io` 实现文件

## 3. 验证（手工）

- [x] 3.1 默认构建（无 `FORCE_IPV4`）：`flutter analyze` 通过；未传 `FORCE_IPV4` 时不安装覆盖
- [x] 3.2 `flutter run --dart-define=FORCE_IPV4=true` 真机：API 请求成功（根因：网关直连 IP 静默丢弃，客户端 SNI 修复后恢复）
- [ ] 3.3 同上构建：历史 WS、UCG 聊天 WS、语音 ASR WS 握手成功（日志无 `connect failed`）
- [x] 3.4 确认 `UcgNetworkImage` CDN 加载不在本 change 保证范围（引擎栈，非 `HttpOverrides`）

## 4. 文档（可选）

- [x] 4.1 `app/README.md` 补充 `--dart-define=FORCE_IPV4=true` 一行说明（联调/问题网络场景）

## 5. 图片加载失败日志（已取消）

> 联调结论：展示失败与网关策略相关，非客户端 CDN 路径缺日志；不纳入本 change。

- [x] 5.1 ~~图片日志~~ 不实现（用户确认不需要）
- [x] 5.2 ~~UcgNetworkImage 日志~~ 已回滚
- [x] 5.3 ~~EventLogo / downloadLogo 日志~~ 已回滚
