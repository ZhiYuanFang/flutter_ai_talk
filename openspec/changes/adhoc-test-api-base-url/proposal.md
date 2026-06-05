# Proposal: ad-hoc 构建使用测试 API 基址

## Why

蒲公英 ad-hoc 内测包当前未注入 `API_BASE_URL`，编译产物默认连接生产网关 `https://pangbao.cuplay.top`，与内测环境不一致。

## What

- 在 `ios-build-core.yml` 中，当 `target_channel` 为 `adhoc` 时，为 `flutter build ipa` 注入 `--dart-define=API_BASE_URL=https://test.pangbao.cuplay.top`。
- TestFlight / App Store 入口保持现有默认（不注入测试基址）。
- 更新 iOS 发布文档说明 ad-hoc 与 API 环境的对应关系。

## Scope

- 仅 CI workflow 与文档；不修改 `env.dart` 默认值。
- 微信 Universal Link 配置不变；本次内测不覆盖微信登录验证。
