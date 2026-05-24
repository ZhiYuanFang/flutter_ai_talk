## Context

- 主页底部 220px 输入区：语音球居中、右下为语音/键盘切换；`home-voice-slide-cancel` 已实现 `_listening`、`_slideToCancel` 与全屏 `Listener`。
- 云端 ASR / Vosk 经 `record.startStream` 获取 PCM16 16kHz；系统 STT 经 `speech_to_text.listen`，支持 `onSoundLevelChange(double)` 真电平。
- 当前无任何响度回调或可视化组件。

## Goals / Non-Goals

**Goals:**

- `_listening` 期间在输入区右上方展示 **5 根**竖条，高度映射归一化响度 `0..1`。
- 三引擎均上报**真实**电平（PCM RMS 或 STT sound level），经统一平滑后驱动 UI。
- `_slideToCancel` 时柱体与描边使用 `ColorScheme.error` 色系；正常态随响度由 `primary` → 更亮/饱和色渐变。
- UI 更新节流（约 30Hz），避免每 PCM 块 `setState` 拖慢列表。

**Non-Goals:**

- 音高（F0）检测、频谱分析、识别置信度条。
- `_voiceHoldActive` 但尚未 `_listening`（连接/准备中）的假电平动画。
- Web 端若某引擎无电平 API 的降级（本变更按用户要求 STT 真电平；Web 若缺失则在实现时文档化并返回 0，不造假波动）。

## Decisions

### 1. 电平抽象：`onLevel` 回调

在 `HomeSpeechRecognizer.startSession` 增加可选参数：

```dart
Future<void> startSession(
  void Function(String partial) onPartial, {
  void Function(double level)? onLevel, // 0..1
});
```

`HomeScreen` 在 `setState(() => _listening = true)` 后传入 `onLevel`，写入 `_voiceLevelSmoothed`（单值）或 `_voiceLevels`（多柱错位，见下）。

**理由**：首页不直接依赖 PCM；三引擎各自适配。  
**备选**：独立 `StreamProvider` — 过度拆分，按住会话生命周期与 screen 绑定更简单。

### 2. PCM 响度：RMS + 分贝映射

新建 `pcm16PeakRmsNormalized(Uint8List bytes)`：

- int16 little-endian RMS → `20 * log10(rms/ref)`，ref 取满幅常数（如 32768 的 0.05 倍作噪声底）。
- 钳制到 `[0, 1]`，对典型说话约 0.2–0.9 区间可再乘 gentle gain（design 实现时调参）。

在 `VoskHomeSpeechRecognizer._feedPcm` 与 `VoiceAsrWsClient._sendPcm`（或仅 feed 路径）每块调用一次 `onLevel?.call(level)`。

**理由**：与现有单路 `AudioRecorder` 一致，不并行 `onAmplitudeChanged`。  
**备选**：`record.onAmplitudeChanged` — Android 性能与 `startStream` 并行行为未统一验证。

### 3. 系统 STT：`onSoundLevelChange`

`SystemSttHomeSpeechRecognizer.startSession` 在 `listen(..., onSoundLevelChange: (db) { ... })` 中将平台 dB 映射到 `0..1`（按插件文档典型范围 -2..10 或类似，实现时读 `lastSoundLevel` 标定）。

**理由**：用户明确要求真电平，非假动画。

### 4. 多柱形态：单源 + 相位错位

维护一个平滑标量 `_level`（attack ~80ms，release ~300ms）。5 根柱高度：

`bar[i] = clamp(_level * wobble[i], minHeight, maxHeight)`，其中 `wobble` 为固定系数如 `[0.55, 0.85, 1.0, 0.75, 0.6]`，使中间柱最高，形成均衡器观感。

**理由**：实现简单、性能好；非真 FFT。  
**备选**：滚动历史环缓冲 — 更炫但成本高，非 MVP。

### 5. 组件与布局

- `HomeVoiceLevelBars`：`barCount: 5`，`level: double`，`cancelled: bool`（→ error 色），`maxHeight` ~36–44。
- 置于底部 `Stack` 的 `Positioned(top: 8, right: _canSwitchInputMode ? 56 : 16)`，**仅** `_inputChannel == voice && _listening`。
- 置于语音 `Listener` **之下**、语音球 **之上**（与 slide-cancel 层序一致），避免挡切换按钮（切换在最顶）。

### 6. 取消态配色

`cancelled == _slideToCancel`：`ColorScheme.error` 及 `error.withValues(alpha: 0.6)` 作柱渐变；正常态 `primary` → `primary` 高 alpha。柱高仍随 `_level` 变化。

### 7. 性能

- `onLevel` 内更新 `ValueNotifier<double>` 或节流 `setState`（≥33ms 间隔）。
- `HomeVoiceLevelBars` 优先 `ListenableBuilder`/`AnimatedContainer` 仅重建柱区域。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| PCM 每块回调过频 | 节流 + 平滑 |
| 系统 STT dB 范围因平台而异 | 实现时 clamp + 文档注释；设置页引擎为 system 时人工验收 |
| 与右上切换按钮重叠 | `right` 留白 56 when toggle visible |
| 静音环境柱全矮 | 可接受；表示「在听但无声」，与产品「听得清」在有声时体现 |
| Web cloud/vosk PCM 可用性 | 与现有录音路径一致；无电平则保持 0 |

## Migration Plan

- 纯客户端增量；无数据迁移。
- 发布：随下一版 APK；设置默认引擎为 cloud 时优先验收 cloud + Vosk。

## Open Questions

- （无）用户已确认：响度、多柱、仅 `_listening`、STT 真电平、取消 error 色。
