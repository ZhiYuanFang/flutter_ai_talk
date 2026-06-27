## Why

`trim-debug-logs-http-only` 已把 **Dart 层** 收口为仅 `[ApiHttp]`，但 `flutter run` 终端仍混入大量 **Android 原生日志**（如 vivo 机 `D/ScreenUtils: hasVivoFreeformTasks`）及 **fluwx `debug_logging: true`** 的微信 SDK 输出，HTTP 日志仍难辨认。需要在项目可控范围内进一步降噪，并明确开发者应如何只看 API 日志。

## What Changes

- 关闭 `pubspec.yaml` 中 `fluwx.debug_logging`（`true` → `false`）。
- 在 `app/README.md` 补充 **Debug 日志** 小节：说明 Dart 仅 `[ApiHttp]`；原生日志来源；推荐 `adb logcat` / 终端过滤命令。
- （可选脚本）提供 `app/scripts/logcat_api_http.ps1`（或等价）便于 Windows 开发机单独拉 `[ApiHttp]` 行。
- Spike：在 Gradle/Pub 依赖中定位 `ScreenUtils` 来源；若来自不可控 ROM/三方 AAR，在设计中记录结论，**不**承诺从应用内彻底消除。
- 更新 `api-http-debug-log` 规格：界定 Dart vs 原生/系统日志边界及开发者工作流。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `api-http-debug-log`：补充「Flutter 原生日志降噪」与「开发者过滤 logcat」要求；明确系统/ROM 日志不在应用消除范围。

## Impact

- **配置**：`app/pubspec.yaml`（fluwx）。
- **文档/脚本**：`app/README.md`、可选 `app/scripts/`。
- **Release**：无用户可见行为变更。
- **限制**：vivo 等 OEM `ScreenUtils`、GC JIT 等系统行无法由 Dart 删除，仅能通过 logcat 过滤或换设备/ROM 减少。
