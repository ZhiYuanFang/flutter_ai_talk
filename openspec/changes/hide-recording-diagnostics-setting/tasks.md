## 1. 功能开关（store）

- [x] 1.1 在 `recording_diagnostics_store.dart` 增加 `kRecordingDiagnosticsFeatureEnabled = false` 及恢复说明注释
- [x] 1.2 `load()` 在功能关闭时直接返回 `false`，保留 prefs 读取逻辑于开关启用分支

## 2. 设置页 UI

- [x] 2.1 从设置中心移除「显示录音数据」`SwitchListTile`（删除 `RecordingDiagnosticsTile` 引用）
- [x] 2.2 `settings_screen.dart` 改为直接使用 `SpeechEngineTile()`，删除对 `recording_diagnostics_tile.dart` 的依赖
- [x] 2.3 删除 `recording_diagnostics_tile.dart`（或确认无其他引用后删除）
- [x] 2.4 可选：`speech_engine_tile.dart` 移除仅服务于诊断联动的 `onEngineChanged` 参数

## 3. 主页耦合清理

- [x] 3.1 删除 `_refreshRecordingDiagnosticsPref()` 方法
- [x] 3.2 删除 `HomeImmersiveHeader.onSettingsTap` 中从设置返回后的 pref 刷新调用
- [x] 3.3 确认 `_showRecordingStatsPanel` 在默认功能关闭下永不成立（保留 session / overlay 代码不动）

## 4. 验证

- [x] 4.1 设置中心仅见「语音识别」，无「显示录音数据」
- [x] 4.2 云端 ASR 按住说话时主页不显示诊断面板（含 prefs 曾为 true 的设备）
- [x] 4.3 `flutter analyze` 无新增错误
