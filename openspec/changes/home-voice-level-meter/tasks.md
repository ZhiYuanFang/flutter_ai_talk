## 1. 电平数据层

- [x] 1.1 新增 `pcm16` RMS 归一化工具（如 `app/lib/audio/pcm_level.dart`）
- [x] 1.2 扩展 `HomeSpeechRecognizer.startSession` 增加可选 `onLevel(double 0..1)`，并更新全部实现类签名
- [x] 1.3 `VoskHomeSpeechRecognizer`：在 `_feedPcm` 中计算 RMS 并回调 `onLevel`
- [x] 1.4 `VoiceAsrWsClient` / `CloudAsrHomeSpeechRecognizer`：PCM 路径回调 `onLevel`（经 recognizer 转发）
- [x] 1.5 `SystemSttHomeSpeechRecognizer`：`listen(onSoundLevelChange: …)` 映射真电平到 `0..1`

## 2. 首页状态与平滑

- [x] 2.1 `HomeScreen`：`_listening` 时注册 `onLevel`；结束/取消时重置电平
- [x] 2.2 实现 attack/release 平滑与 ~30Hz 节流（`ValueNotifier` 或等价）
- [x] 2.3 由单值 `_level` 生成 5 柱高度系数（中间柱最高）

## 3. UI 组件与布局

- [x] 3.1 新建 `HomeVoiceLevelBars`（5 柱、高度 + 渐变配色）
- [x] 3.2 底部 `Stack` 右上 `Positioned`：仅 `voice && _listening` 显示；避让输入切换按钮
- [x] 3.3 `_slideToCancel` 为 true 时柱体使用 `ColorScheme.error` 色系

## 4. 验证

- [x] 4.1 云端 ASR：`_listening` 中说话柱随音量变化，松手隐藏
- [x] 4.2 滑出取消态：柱与圆同为 error 色，滑回恢复
- [x] 4.3 系统 STT（若可用）：确认为真电平而非假动画
- [x] 4.4 连接中（未 `_listening`）不显示电平柱
