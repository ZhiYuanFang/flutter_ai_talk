## ADDED Requirements

### Requirement: Third-party SDK debug logging SHALL be disabled in default dev config

Project-configurable native SDK debug flags that emit console noise unrelated to HTTP diagnostics MUST be disabled in the default repository configuration. At minimum, `fluwx.debug_logging` in `pubspec.yaml` MUST be `false`.

项目内可配置的第三方 SDK debug 开关 MUST 默认关闭；至少 `fluwx.debug_logging` MUST 为 `false`。

#### Scenario: 默认 clone 后 fluwx 不刷 SDK 日志

- **WHEN** 开发者使用仓库默认 `pubspec.yaml` 构建 debug APK
- **THEN** fluwx MUST NOT 因 `debug_logging: true` 额外输出微信 Open SDK 调试日志

### Requirement: README SHALL document ApiHttp-only logcat workflow

The app README MUST describe that Dart-side diagnostics are limited to `[ApiHttp]` (see `api-http-debug-log` baseline) and MUST provide at least one command or script example to filter device logcat for `[ApiHttp]` while developing on Android.

README MUST 说明 Dart 侧仅 `[ApiHttp]`，并 MUST 提供 Android 开发时过滤 logcat 查看 HTTP 日志的示例命令或脚本。

#### Scenario: 新开发者查阅 README

- **WHEN** 开发者打开 `app/README.md` 查找调试 HTTP 日志方法
- **THEN** 文档 SHALL 包含 `[ApiHttp]` 过滤示例（如 `adb logcat` + 关键字）

### Requirement: OEM and system logcat noise is out of app elimination scope

Android log lines not emitted by Dart `ApiHttpLog` (including OEM tags such as `ScreenUtils`, system GC messages, and Flutter engine verbose output) SHALL NOT be required to be removed from device logcat by application code. Documentation MUST state this boundary explicitly.

OEM/系统 logcat 噪声（如 `ScreenUtils`）SHALL NOT 要求应用代码消除；文档 MUST 明确该边界。

#### Scenario: vivo 机仍见 ScreenUtils

- **WHEN** 开发者在 vivo 设备上 `flutter run` 且已合并 Dart 日志收口变更
- **THEN** `D/ScreenUtils` MAY 仍出现
- **AND** 该现象 MUST NOT 视为 `api-http-debug-log` 回归
