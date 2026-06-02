## Context

2026-06-01 变更 `home-voice-recording-diagnostics` 在设置中心加入「显示录音数据」开关，并在云端 ASR 聆听于主页展示 PCM 诊断 overlay。该能力面向开发者联调，非面向终端用户。当前实现包括：

- `RecordingDiagnosticsStore`（`SharedPreferences`，key `show_recording_diagnostics`）
- `RecordingDiagnosticsTile` / `VoiceInputSettingsGroup`（设置 UI）
- `home_screen.dart` 内 session、`_showRecordingStatsPanel` 与 `HomeVoiceRecordingStats`

用户已确认采用方案 B：**隐藏设置 UI + 强制关闭能力**；后续如需联调，在源码中手动改即可，不引入 `kDebugMode` 分支或隐藏手势。

## Goals / Non-Goals

**Goals:**

- 设置中心不再展示「显示录音数据」开关。
- 对所有用户（含曾开启 prefs 者）诊断面板不得显示。
- 保留诊断 session / overlay / store 代码路径，恢复时仅需改少量常量与 UI。
- 更新 `home-voice-recording-diagnostics` 规格以反映用户可见行为变化。

**Non-Goals:**

- 不删除 `home_voice_recording_stats.dart` 或 PCM 诊断回调链。
- 不清理 SharedPreferences 中既有 `show_recording_diagnostics` 值。
- 不新增 Debug 菜单、版本号连点等隐藏入口。
- 不修改语音识别引擎选择行为。

## Decisions

### 1. 单点功能开关：`kRecordingDiagnosticsFeatureEnabled`

在 `recording_diagnostics_store.dart` 增加顶层常量（默认 `false`）。`load()` 在该常量为 `false` 时**直接返回 false**，不读取 prefs。`save()` 保留原实现。

**理由**：一处改动即可恢复整条链路；prefs 逻辑无需重写。

**备选**：主页删除所有诊断代码（方案 D）—— 恢复成本高，已否决。

### 2. 设置页：移除诊断 tile，保留引擎选择

从 `VoiceInputSettingsGroup` 移除 `RecordingDiagnosticsTile`。若 Group 仅剩 `SpeechEngineTile`，则在 `settings_screen.dart` 直接使用 `SpeechEngineTile()`，删除 `recording_diagnostics_tile.dart` 或将其瘦身为仅 re-export（优先删除文件并改 import）。

**理由**：最小 UI  diff；「语音识别」仍是合法用户设置。

### 3. 主页：删除设置返回刷新，保留 load 调用

删除 `_refreshRecordingDiagnosticsPref()` 及 `onSettingsTap` 中的调用。`_initMobileSpeech` / `_prepareVoiceInput` 可继续 `RecordingDiagnosticsStore.load()`（结果恒 false），或统一依赖 `_showRecordingDiagnostics` 初始 false—— 保持 load 调用便于以后恢复。

**理由**：去除已无 UI 的耦合；session 启动条件 `_showRecordingDiagnostics && cloudAsr` 自然永不成立。

### 4. 规格：MODIFIED「设置开关」需求，保留展示/字段/手势需求

原「设置页必须提供开关」改为「设置页不得展示用户可见开关；对用户诊断恒关闭」。「仅云端 ASR 且聆听中显示」「诊断字段」「不干扰手势」等需求保留，触发前提改为「代码显式启用诊断功能且满足云端聆听条件」。

## Risks / Trade-offs

- **[Risk] Release 包仍含未使用诊断代码** → 可接受；体积与复杂度增量小，换联调可恢复性。
- **[Risk] 老用户 prefs 为 true 但面板消失** → 符合预期；无数据损坏，恢复功能开关后 prefs 仍生效。
- **[Risk] 开发者忘记改常量** → 在 `recording_diagnostics_store.dart` 顶部用中文注释说明恢复步骤。

## Migration Plan

1. 发布含本变更的版本；用户升级后设置项消失、面板不再出现。
2. 无需 prefs 迁移或服务端变更。
3. 回滚：恢复 tile UI，将 `kRecordingDiagnosticsFeatureEnabled` 改回 `true`。

## Open Questions

（无）
