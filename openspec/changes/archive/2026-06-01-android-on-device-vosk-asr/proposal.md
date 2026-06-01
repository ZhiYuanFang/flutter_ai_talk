## Why

在华为等国内 Android 设备上，主页「按住说话」依赖系统 `SpeechRecognizer`（`speech_to_text`），常要求用户安装或切换 Google 语音服务，且在国内无法稳定打开应用市场对应页面，语音入口不可用。产品要求：**语音转文字在 App 内自主完成**、**不采用百度等付费云端 SDK**、**不要求用户额外安装系统语音引擎**；网关仍只接收文本（`sendCommand`），后端不变。

**已决方案**：采用 **Vosk 离线 ASR**，中文小模型 **`vosk-model-small-cn-0.22` 随 release APK 内置**（接受安装包增大约 50MB），安装后即可离线识别，无需首次联网下载模型、无需跳转应用市场。

## What Changes

- Android 主页按住说话：由 `speech_to_text` + 系统引擎改为 **Vosk 端侧识别**（录音 → Vosk → 文本 → `sendCommand`）。
- **模型交付**：模型目录打包进 `assets`（或 Android assets），应用首次启动或首次使用语音时解压到应用私有目录并复用；**不得**依赖 CDN 首次下载作为主路径。
- **交互**：保留按住开始 / 松手结束；识别中可展示 partial 文本；失败回退文字输入。
- **移除/降级**：Android 上安装 Google Speech Services、切换系统默认识别引擎的引导与 `MainActivity` 语音检测 `MethodChannel`（实现阶段删除或仅 iOS 保留）。
- **平台范围**：本变更以 **Android** 为主；iOS 可继续 `speech_to_text`；Web 不变（文本主输入）。
- **非目标**：百度短语音/翻译 API、服务端 ASR、自定义声学训练、medium 大模型（>100MB）内置。

## Capabilities

### New Capabilities

- `android-on-device-asr`：Android 端 Vosk 识别、内置中文小模型、录音格式、初始化与失败回退、不得要求用户安装第三方语音引擎。

### Modified Capabilities

- `home-input-history-sse`：修改「主输入方式按平台区分」——Android 必须使用 App 内 Vosk 转写，不得依赖系统语音服务或引导用户去应用市场装引擎。

## Impact

- **代码**：`home_screen.dart`、新增 `lib/asr/`（或等价）、`pubspec.yaml`；可能移除 `android_speech_availability.dart`、`speech_services_prompt.dart`、精简 `MainActivity.kt`。
- **依赖**：`vosk_flutter`（或经评审的等价封装）、`record`（16kHz mono PCM）。
- **包体**：release APK/AAB 增大约 **42–55MB**（以官方 small-cn 模型为准）；需在 README/发布说明中注明。
- **构建**：Android 需确认 NDK/ABI（arm64-v8a、armeabi-v7a 等）与 Flutter 目标一致；模型不进入 Git 时需在 CI/本地构建文档说明下载与放置路径。
