## 1. 配置降噪

- [x] 1.1 `pubspec.yaml`：`fluwx.debug_logging` 改为 `false`

## 2. 文档与脚本

- [x] 2.1 `app/README.md` 新增「Debug HTTP 日志」：Dart 仅 `[ApiHttp]`、原生/系统噪声说明、logcat 过滤示例
- [x] 2.2 更新 README 推送验证章节：移除已删除的 `[ucg-push]` debugPrint 引用
- [x] 2.3 （可选）新增 `app/scripts/logcat_api_http.ps1` 封装 `adb logcat` + `ApiHttp` 过滤

## 3. Spike：ScreenUtils 来源

- [x] 3.1 在 Gradle 依赖 / Pub Cache 中搜索 `ScreenUtils` 或 `hasVivoFreeformTasks`，结论写入 design.md「Open Questions」或 tasks 备注

## 4. 验收

- [x] 4.1 默认配置下 fluwx 不再因 `debug_logging` 额外输出（对比改前 logcat 或读 fluwx 文档确认）
- [x] 4.2 README 含可复制的 ApiHttp 过滤命令
- [x] 4.3 `flutter run` 仍可能有 OEM 行 — 文档已说明，不视为失败
