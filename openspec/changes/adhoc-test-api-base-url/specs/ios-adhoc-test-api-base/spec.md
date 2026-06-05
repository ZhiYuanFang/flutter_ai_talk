# Spec Delta: ios-adhoc-test-api-base

## ADDED Requirements

### Requirement: ad-hoc 构建必须编译测试 API 基址

The ad-hoc iOS build MUST inject the test gateway base URL at compile time.
当 `target_channel` 为 `adhoc` 且执行 `flutter build ipa` 时，系统必须通过 `--dart-define=API_BASE_URL=https://test.pangbao.cuplay.top` 将测试网关基址写入产物；不得依赖 `AppEnv` 默认生产基址。

#### Scenario: ad-hoc 工作流构建 IPA

- **WHEN** 用户触发 `Build iOS ad-hoc` 且构建步骤执行 `flutter build ipa`
- **THEN** 构建命令包含 `--dart-define=API_BASE_URL=https://test.pangbao.cuplay.top`
- **AND** 构建日志输出可识别的 `API_BASE_URL` 摘要

### Requirement: 非 ad-hoc 入口不得注入测试 API 基址

TestFlight and App Store iOS builds MUST NOT inject the test `API_BASE_URL`.
当 `target_channel` 为 `testflight` 或 `appstore` 时，系统不得为 `flutter build ipa` 传入测试域 `API_BASE_URL`。

#### Scenario: TestFlight 构建不注入测试基址

- **WHEN** 用户触发 `Build iOS TestFlight` 且构建步骤执行 `flutter build ipa`
- **THEN** 构建命令不得包含指向 `test.pangbao.cuplay.top` 的 `API_BASE_URL` dart-define
