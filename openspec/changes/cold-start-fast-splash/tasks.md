## 1. 启动图与 Splash 瘦身

- [x] 1.1 Android `LaunchTheme` / 启动背景：品牌色 + 居中 Logo（`splash_logo`）；Android 12+ `values-v31` 系统 Splash；`NormalTheme` 同背景避免白闪
- [x] 1.2 Flutter `SplashScreen`：品牌背景 + 上传 Logo + 「胖宝」应用名；无孤立白底转圈
- [x] 1.3 重构启动：`main()` 内 [ColdStartBootstrap] 本地 restore；直达 `/home` 或 `/login`（跳过 Flutter Splash 中间页，避免名字闪屏）
- [x] 1.4 将 `maybeShowVersionPrompt`、`loadBaby` 移至 `HomeScreen` 后台 bootstrap；Android `installSplashScreen` 保持原生 logo 至主页首帧

## 2. 移除 Vosk

- [x] 2.1 从 `pubspec.yaml` 移除 `vosk_flutter_service` 与 Vosk 模型 asset；删除 `assets/models/vosk-model-small-cn-0.22.zip`、`tool/check_vosk_model.dart`
- [x] 2.2 删除 `vosk_home_speech_recognizer.dart`、`vosk_text_parser.dart`；`SpeechEngine` 移除 `vosk`；`home_speech_factory` 仅 cloud/system
- [x] 2.3 `SpeechEngineStore.load()`：读到 `vosk` 时迁移为 `cloudAsr`（Android）或 `systemStt`（iOS）并 persist
- [x] 2.4 `SpeechEngineTile` 与 README 更新；移除 Vosk/iOS install 说明

## 3. 验证

- [x] 3.1 冷启动：原生非白 → 品牌 Splash 短暂 → 主页壳子（弱网下不卡在 Splash 等网络）
- [x] 3.2 进主页后版本/宝宝信息仍能加载；强制更新弹窗仍可用
## 4. 启动动画与冷启动续期

- [x] 4.1 Flutter Splash：`SplashLogoPulse` 心跳缩放动画（Logo only，与原生视觉一致）
- [x] 4.2 恢复 `/splash` 首屏；`ColdStartBootstrap` 含 `ensureFreshSession`（JWT 将过期/已过期时主动 refresh）
- [x] 4.4 Logo 双拍心跳（1.0→1.14）+ 最短展示 1.8s；原生 Splash 在 Flutter 启动页首帧后收起
- [x] 4.6 全屏 `StartupBrandingOverlay` 叠在 App 之上（bootstrap 期间始终播放心跳，不受路由切换影响）