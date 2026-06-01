## Context

- 云端 ASR：`VoiceAsrWsClient` 使用 `RecordConfig(encoder: pcm16bits, sampleRate: 16000)`，`start` 报文同样声明 16kHz / 16bit / mono。
- 主页已有 `_listening`、右上 `HomeVoiceLevelBars`、`home-voice-slide-cancel` 手势层。
- 设置页已有 `SpeechEngineTile`；持久化模式参考 `SpeechEngineStore` / `custom_background_persist`（`SharedPreferences`）。

## Goals / Non-Goals

**Goals:**

- 设置开关（**默认关**）控制是否在云端聆听时显示诊断面板。
- 语音圆**左侧**展示：`PCM16`、`16000 Hz`、块级 `avgAbs`、会话 `avgAbs`、时长（秒）。
- 数据来自真实 PCM 回调；块级与会话累计在一次遍历中计算。
- UI 刷新节流（约 10Hz），`IgnorePointer`。

**Non-Goals:**

- Vosk / 系统 STT 下的诊断面板（开关打开也不显示）。
- float32 格式、频谱、WS 字节计数、服务端返回字段。
- 非 `_listening` 阶段（含连接中）显示占位。

## Decisions

### 1. 可见性条件

同时满足才渲染：

```text
prefs.showRecordingDiagnostics == true
&& _speechEngine == SpeechEngine.cloudAsr
&& _inputChannel == voice
&& _listening == true
```

### 2. Prefs

- Key：`show_recording_diagnostics`（bool）
- `RecordingDiagnosticsStore.load()` / `save(bool)`，默认 `false`
- 设置页：`SwitchListTile`「显示录音数据」，副标题说明仅云端按住说话时有效

### 3. avgAbs 双指标

`pcm16AbsStats(Uint8List bytes)` 返回块级 `chunkAvgAbs`（int，四舍五入）：

- 对块内样本：`mean(|int16|)`
- 会话累计：`sessionSumAbs += sum(|sample|)`，`sessionSampleCount += n`，`sessionAvgAbs = sessionSumAbs / sessionSampleCount`
- 在 `VoiceAsrWsClient._sendPcm` 中更新；`beginUtterance` 时清零；`endUtterance` / `cancel` 时停止上报

经 `onDiagnostics` 或扩展 `startSession` 可选回调传入 `HomeScreen`：

```dart
void Function({
  required int chunkAvgAbs,
  required int sessionAvgAbs,
})? onPcmDiagnostics;
```

仅 `CloudAsrHomeSpeechRecognizer` 转发；Vosk/System 不实现。

### 4. 时长

`HomeScreen` 在 `_listening` 置 true 时 `Stopwatch.start()`，面板用 `Ticker` 或每秒 `setState`（与诊断节流合并）显示 `elapsed.inMilliseconds / 1000` 一位小数。

### 5. 布局

`Positioned(left: 16, top: 0, bottom: 0)` + `Align(centerLeft)` + `HomeVoiceRecordingStats` 小字号 `Text` 列：

```
格式  PCM16
采样  16 kHz
块    avg 1234
场    avg 2100
时长  3.2 s
```

层序：在语音球 `Align` 之上、全屏 `Listener` 之下（与响度柱一致），`IgnorePointer`。

### 6. 与 onLevel 关系

`_sendPcm` 内同一次 `pcm16` 解析可同时算 RMS（已有）与 abs 统计，避免双遍循环（合并到 `pcm_level.dart` 的单一遍历函数）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 左侧与字幕/圆盘挤占 | 小字 + 左 padding；必要时 `left: 8` |
| 频繁 setState | 诊断 ValueNotifier + 100ms 节流 |
| 用户误开开关 | 默认关 + 设置说明 |

## Migration Plan

- 无后端变更；卸载不受影响（prefs 残留可接受）。

## Open Questions

- （无）已确认：双 avgAbs、仅云端、默认关。
