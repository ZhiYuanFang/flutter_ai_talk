## Context

- 现状：`initialLocation: '/splash'` → `SplashScreen` 全屏 `CircularProgressIndicator`；`_boot()` 串行 `restore` → `deviceNo` → 渠道 → `readPackageVersion` → **`checkForUpdate`（网络）** → **`loadBaby`（网络）** → `go('/home')`。Android `LaunchTheme` 为 `@android:color/white`。
- 语音：Android 默认 `cloudAsr`；可选 Vosk（约 42MB zip + `vosk_flutter_service` native 插件）。Vosk 模型在 `prepare()` 懒加载，但插件注册与 APK 体积仍影响冷启动体感。
- 约束：`GoRouter` 对 `sessionProvider` 使用 `ref.read` + `refreshListenable`，Splash 期间 `restore()` 的 `notifyListeners` 不得重建整棵路由树（已有注释）。

## Goals / Non-Goals

**Goals:**

- 用户从点击图标到看见**主页壳子**（AppBar + 历史区，可为空或缓存）目标 **≤1s 量级**（弱网除外；以本地 restore 完成为准）。
- 冷启动全程**不得**出现长时间纯白屏：原生 Splash → Flutter 品牌 Splash → 主页，视觉连续。
- Splash **仅**阻塞：会话 restore、本地 `deviceNo`、登录渠道 prefs、本地主题/宝宝 sex 缓存（若有）。
- 版本检查、`loadBaby`、历史 list、事件目录远端同步在**进入 `/home` 之后**执行，且不重复 Splash 已完成的本地步骤。
- 完全移除 Vosk：依赖、assets、代码、设置项；迁移旧 prefs。

**Non-Goals:**

- 重构全部 `HomeScreen._init` 为 isolate（可后续迭代）。
- 历史列表磁盘缓存（本变更可选「沿用内存/上次会话」；完整离线首屏可后续 change）。
- Web 端冷启动（随现有 Web 策略，不强制原生 Splash）。

## Decisions

1. **Splash 时序**
   ```text
   postFrame → restore session
            → deviceNo.refresh (prefs only)
            → signInChannel restore/clear
            → load local babySex / customBackground from prefs if cached
            → go('/home')   // 不再 await version / loadBaby
   ```
   未登录：`go('/login')` 或保持现有 redirect 策略（与 `go_router` redirect 对齐）。

2. **主页 bootstrap**
   - `HomeScreen._init`：`unawaited` 版本检查 + `maybeShowVersionPrompt`（非强制更新可延迟 1–2s 或 idle 后）。
   - `loadBaby` → 更新 `babySexProvider`（Splash 已用本地缓存时仅 patch）。
   - 保留 `_reloadHistoryIfLoggedIn` 与 WS，但**不**在 Splash 重复 `deviceNo.refresh`（去重）。
   - 云端 ASR WS：维持 `_scheduleVoiceAsrConnectIfNeeded`，不阻塞首帧。

3. **启动图**
   - Android：`LaunchTheme` / `NormalTheme` 使用主题色或 `@drawable/launch_background`（Logo + 品牌色），与 `buildAppTheme` 默认 male/female/unknown 之一或中性品牌色一致。
   - Flutter `SplashScreen`：`Scaffold(backgroundColor: themePrimaryBlend 或 scaffoldBg)` + 居中 Logo/应用名；转圈可选弱化或仅首次无缓存时显示。
   - 可选 `flutter_native_splash` 生成配置；若手写 XML，需在 README 注明维护方式。

4. **移除 Vosk**
   - 删 `SpeechEngine.vosk`；`SpeechEngineStore.load()` 读到 `vosk` 时写回 `cloudAsr`（Android）或 `systemStt`（iOS）并 persist。
   - 删 `VoskHomeSpeechRecognizer`、`vosk_text_parser.dart`、`home_speech_factory` 分支。
   - `pubspec.yaml` 移除 `vosk_flutter_service` 与 `assets/models/vosk-model-small-cn-0.22.zip`。
   - 设置 `SpeechEngineTile` 仅展示 `cloudAsr` + `systemStt`（Android/iOS 均可；Web 保持现有）。
   - OpenSpec delta：`android-on-device-asr` 相关 Requirement **REMOVED**，理由见 spec。

5. **弱网 / 离线**
   - 无 Vosk 后 Android 离线语音依赖系统 STT（可能不可用）或文字输入；云端 ASR 需网络。与旧 spec「语音不可用不阻塞非语音功能」一致。

## Risks / Trade-offs

- **[Risk] 进主页时主题色短暂为默认** → Splash 或 prefs 缓存 `babySex`/自定义背景，与 `app.dart` `_restoreCustomBackground` 合并策略。
- **[Risk] 版本强制更新晚展示** → 若 `forceUpdate`，主页 bootstrap 仍须尽快弹窗；可保留短超时并行请求。
- **[Risk] 删 Vosk 后华为无系统 STT** → 云端 ASR + 文字输入；README 说明。
- **[Trade-off] APK 减小 ~50MB** vs 失去离线 Vosk 转写。

## Migration Plan

- 发布新版本；首次启动自动迁移 `speech_engine=vosk` prefs。
- 无服务端迁移。用户需重新下载较小安装包。

## Open Questions

- （已决）移除 Vosk；Splash 不阻塞网络进主页。
