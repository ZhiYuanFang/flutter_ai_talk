## Why

冷启动时用户会先看到原生白屏，再在 Splash 页长时间转圈：当前 `SplashScreen._boot()` 串行等待版本检查与 `loadBaby` 等网络请求后才进入主页，且安装包内置约 50MB 的 Vosk 模型与 native 插件增加引擎启动成本。需要缩短「可交互主页」到达时间，并用品牌启动图消除白屏；产品已默认云端 ASR，可移除 Vosk 以减小包体与依赖。

## What Changes

- **启动视觉**：Android/iOS 原生 Launch/Splash 使用与 App 主题一致的品牌背景（非纯白）；Flutter `/splash` 展示 Logo/品牌色，避免白 Scaffold + 孤立转圈。
- **Splash 瘦身**：Splash 仅 await 本地恢复（会话 token、`deviceNo` 缓存、登录渠道、本地宝宝性别/自定义背景缓存等）；**不得**阻塞 `go('/home')` 等待版本检查、`loadBaby`、历史全量拉取。
- **主页后台并行**：进入 `/home` 后并行/懒加载：版本提示、`loadBaby` 写主题、事件目录同步、历史 HTTP/WS；可选展示骨架或沿用上次的本地快照。
- **移除 Vosk（BREAKING）**：删除 `vosk_flutter_service`、内置模型 zip 及相关 ASR 代码；设置中移除「本地识别」；已持久化为 `vosk` 的引擎选择迁移为 `cloudAsr`（Android）或 `systemStt`（iOS）。
- **语音引擎保留**：Android 默认「云端识别」；iOS 默认「系统识别」；设置可选「云端 / 系统识别」（Android 亦可选系统 STT 作弱网兜底）。

## Capabilities

### New Capabilities

- `cold-start-splash`：原生与 Flutter 启动图、Splash 本地门禁时序、进主页前不得阻塞的网络任务边界。
- `speech-engine-without-vosk`：移除 Vosk 后的语音识别引擎枚举、默认项、设置 UI 与 prefs 迁移。

### Modified Capabilities

- `android-on-device-asr`：废弃 Android 必须内置 Vosk 离线转写的要求（以 REMOVED delta 记录）。
- `home-input-history-sse`：Android 按住说话不再强制 Vosk 端侧识别，与云端/系统 STT 策略一致。

## Impact

- `app/lib/ui/splash_screen.dart`、`app/lib/ui/home_screen.dart`、`app/lib/app.dart`
- `app/android/.../styles.xml`、iOS LaunchScreen（若存在）
- 删除 `app/lib/asr/vosk_*.dart`、`assets/models/vosk-model-small-cn-0.22.zip`、`tool/check_vosk_model.dart`
- `app/pubspec.yaml`（移除 `vosk_flutter_service` 与模型 assets）
- `app/lib/config/speech_engine.dart`、`speech_engine_store.dart`、设置页 `SpeechEngineTile`
- `app/README.md`；归档语义上 supersede `android-on-device-vosk-asr`
