## 1. 配置与统计

- [x] 1.1 新增 `RecordingDiagnosticsStore`（`SharedPreferences`，默认 `false`）
- [x] 1.2 扩展 `pcm_level.dart`：`pcm16AbsStats`（块级 + 会话累计，单次遍历）及 `PcmAbsSessionAccumulator`
- [x] 1.3 `VoiceAsrWsClient`：utterance 内累计 abs，`onPcmDiagnostics` 回调；`CloudAsrHomeSpeechRecognizer` 转发

## 2. 设置页

- [x] 2.1 `settings_screen.dart` 增加「显示录音数据」`SwitchListTile`（说明仅云端有效）

## 3. 首页 UI

- [x] 3.1 新建 `HomeVoiceRecordingStats` 小组件（五行文案）
- [x] 3.2 `HomeScreen`：加载 prefs、`Stopwatch` 时长、诊断状态节流更新
- [x] 3.3 底部 `Stack` 左侧 `Positioned`：条件 `开关 && cloudAsr && _listening`；`IgnorePointer`

## 4. 验证

- [x] 4.1 默认关：主页无面板
- [x] 4.2 云端 + 开关开 + 按住：左侧显示 PCM16/16k/双 avgAbs/秒数
- [x] 4.3 Vosk 引擎 + 开关开：仍不显示
- [x] 4.4 松手后隐藏；按住手势与滑出取消正常
