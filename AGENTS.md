# 仓库级 AI 执行约定

## 权威文档

编写或修改代码、OpenSpec 产物前，**必须**阅读：

1. **[openspec/project.md](openspec/project.md)** — 工程约束全文（WebSocket、日志、Android R8、测试、OpenSpec 基线、归档等）。
2. **[openspec/specs/v2.0.3.md](openspec/specs/v2.0.3.md)** — 当前合并行为基线（Requirement / Scenario 验收）。

OpenSpec CLI 制品生成时亦须对照 `openspec/project.md`；细则以 project.md 为准，本文仅摘要高频 MUST。

## 文档语言

- OpenSpec 制品（proposal / design / specs / tasks）默认使用中文；Requirement 正文须含英文 **SHALL** 或 **MUST**。
- 代码符号、包名、路由、环境变量可保留英文。
- 在代码实现过程中，尽可能用中文描述每一行代码的含义。

## WebSocket（强制）

- 鉴权业务 WebSocket **必须**经 `ResilientWebSocketClient` + `WsConnectionConfig`；禁止 feature 内手写建连/重连/心跳。
- 语音 ASR（`/voice/asr/ws`）为例外，可用 `VoiceAsrWsClient`。
- 细则见 **`openspec/project.md`**「WebSocket 韧性传输约定」；架构见 `app/README.md`「WebSocket 架构」。

## Debug 日志（强制）

- `app/lib/**` 禁止裸 `debugPrint` / `print`；唯一出口 `ApiHttpLog` / `AppDebugLog.*`。
- 新 tag 须三联改：`app_debug_log.dart`、`logcat_api_http.ps1`、`app/README.md` Debug 表。
- 细则见 **`openspec/project.md`**「Debug 日志白名单」。

## Android Release（强制）

- 改动 `app/android/**` 或新增原生 SDK/AAR 时，合并前 **必须** `flutter build apk --release` 通过，并更新 `app/android/app/proguard-rules.pro`。
- R8 Missing class → 从 `missing_rules.txt` 复制 `-dontwarn`。
- 细则见 **`openspec/project.md`**「Android Release / R8」。

## 测试文件

- 不自动新建 `**/test/**` 下测试文件；用户明确要求时例外。
- 细则见 **`openspec/project.md`**「测试文件约定」。

## 副作用 HTTP（强制）

- Riverpod `listen`、原生/SDK 回调、lifecycle 触发的 HTTP **必须** single-flight、失败熔断、自触发 ignore、成功幂等跳过；provider 创建 **不得** 自动 push/未读/WS。
- 细则见 **`openspec/project.md`**「副作用 HTTP 治理」；范例见 `syncUcgUnreadFromServer`、`_syncUcgUnreadInFlight`。

## OpenSpec 工作流

- 新变更前对照 **`openspec/specs/v2.0.3.md`**；行为变更须有 spec delta。
- 收版默认 `scripts/sync_specs_to_version.py <version> --remove-changes`；收版后更新 project.md 基线版本号。
- 细则见 **`openspec/project.md`**「OpenSpec 基线参考约定」「OpenSpec 归档约定」。
- 工作流技能：`.cursor/skills/openspec/SKILL.md`；命令：`/opsx-propose`、`/opsx-apply`、`/opsx-archive`。
