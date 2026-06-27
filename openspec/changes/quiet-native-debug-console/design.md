## Context

- `trim-debug-logs-http-only` 已完成：`app/lib` 内仅 `ApiHttpLog` 输出 `[ApiHttp]`（含 ISO8601 时间戳）。
- `flutter run` 仍转发设备 **完整 logcat**，包含：
  - vivo OEM：`D/ScreenUtils`（多窗口/小窗检测，仓库无源码）
  - 系统：`ActivityThread`、`com.fzy.pangbao: Open vivo delay for GC JIT`
  - 配置：`fluwx.debug_logging: true` → 微信 Open SDK 原生日志
- README 推送章节仍引用已删除的 `[ucg-push]` Dart 日志，需同步更新。

## Goals / Non-Goals

**Goals:**

- 关闭项目内可配置的第三方 debug 日志（fluwx）。
- 文档化「只看 `[ApiHttp]`」的推荐工作流（adb / 终端过滤）。
- 规格明确：Dart 负责 `[ApiHttp]`；原生/ROM 噪声通过过滤或接受，非应用 bug。
- （Spike）记录 `ScreenUtils` 归属，便于后续升级插件或提 issue。

**Non-Goals:**

- Fork 三方 AAR 删 `Log.d`（除非 spike 发现简单可控且低风险）。
- 修改 Flutter 引擎或 `flutter run` 工具链。
- Release 包 ProGuard 剥日志（与 debug 体验无关）。
- 保证所有 OEM 机 `flutter run` 终端零杂音。

## Decisions

### 1. fluwx：关闭 debug_logging

**选择**：`pubspec.yaml` → `fluwx.debug_logging: false`。

**理由**：显式配置、零代码、减少微信 SDK 原生日志。

### 2. 开发者工作流：文档 + 可选脚本，不包装 `flutter run`

**选择**：在 `app/README.md` 增加「Debug HTTP 日志」节，示例：

```powershell
# 终端 A：照常运行
flutter run -d <device> --dart-define=API_BASE_URL=...

# 终端 B：仅看 ApiHttp（flutter 引擎 tag + 关键字）
adb logcat -s flutter | Select-String ApiHttp
```

可选 `app/scripts/logcat_api_http.ps1` 封装终端 B。

**不选**：`flutter run 2>&1 | Select-String ApiHttp` 作为默认 — 会吞掉热重载提示与错误，交互差。

### 3. ScreenUtils：Spike 后写结论，不阻塞交付

**选择**：tasks 含在 `.gradle`/Pub Cache 搜 `ScreenUtils`；若来自 photo_manager / fluwx / ROM hook，在设计或 README **注明无法从 Dart 关闭**。

**理由**：vivo 上高频 `isMultiWindow` 更像插件或 ROM 适配层；无仓库源码时强行消除 ROI 低。

### 4. 规格：MODIFY `api-http-debug-log`

增加「原生/系统日志不在消除范围」与「README 必须描述过滤方式」两条。

### 5. README 推送章节

删除对已移除 `[ucg-push]` debugPrint 的引用，改为「注册失败时查网关 `/push/register` 或断点」。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 关闭 fluwx debug 后微信登录问题难查 | 文档说明临时改回 `true` |
| ScreenUtils 仍刷屏 | README 强调 logcat 过滤；非回归 |
| Windows 开发者不用 adb 在 PATH | 脚本检测 adb 并提示安装 platform-tools |

## Migration Plan

文档 + 配置变更，无迁移。回滚：`debug_logging: true`。

## Open Questions

### ScreenUtils spike（已调查，2026-06-25）

- 仓库 `app/lib`、自有 `app/android/**/*.kt`：**无** `ScreenUtils` / `hasVivoFreeformTasks`。
- Pub Cache 中 `fluwx`、`photo_manager` 等插件 **Java/Kotlin 源码无匹配**。
- logcat 中 `D/ScreenUtils(…): hasVivoFreeformTasks` / `isLittleVExist` / `isMultiWindow` 为 **vivo 多窗口检测** 相关 tag，高概率来自 **vivo ROM 框架 hook 或三方 AAR 内混淆代码**（非 Dart 可控）。
- **结论**：无法在本仓库内删除；开发时用 `adb logcat -s flutter | Select-String ApiHttp` 或 `scripts/logcat_api_http.ps1` 过滤。非 `api-http-debug-log` 回归。
