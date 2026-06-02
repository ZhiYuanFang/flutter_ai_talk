## Why

「显示录音数据」是面向云端 ASR 联调的开发者诊断能力，不应暴露给普通用户。当前设置中心仍展示该开关，且用户开启后主页会出现 PCM 技术读数，与产品面向育儿记录的定位不符。现决定从设置页移除入口，并强制关闭该能力；诊断相关代码保留，便于后续在源码中手动启用。

## What Changes

- 设置中心移除「显示录音数据」`SwitchListTile`；「语音识别」引擎选择保留不变。
- `RecordingDiagnosticsStore.load()` 在功能开关关闭时**必须**恒返回 `false`，即使用户本地 prefs 曾为 `true` 也不得生效。
- 主页移除从设置返回后刷新诊断 pref 的耦合逻辑（`_refreshRecordingDiagnosticsPref` 等）。
- 保留 `home_screen.dart` 内诊断 session、overlay 组件及 PCM 回调路径，不删除联调基础设施。
- **BREAKING（用户可见）**：用户无法再于设置中开启录音诊断面板；已开启 prefs 的用户升级后面板不再显示。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-voice-recording-diagnostics`：设置页不再提供用户可见开关；诊断能力默认且对用户恒为关闭，仅可在代码中显式启用后按原规则展示。

## Impact

- `app/lib/config/recording_diagnostics_store.dart`（功能级硬关常量）
- `app/lib/ui/recording_diagnostics_tile.dart`（移除诊断 tile，或整文件删除并简化设置引用）
- `app/lib/ui/settings_screen.dart`、`app/lib/ui/speech_engine_tile.dart`（可选简化 `VoiceInputSettingsGroup` / `onEngineChanged`）
- `app/lib/ui/home_screen.dart`（删除 pref 刷新路径；继续通过 store 读取，实际恒 false）
- `openspec/specs/home-voice-recording-diagnostics/spec.md`（归档合并时更新基线）
