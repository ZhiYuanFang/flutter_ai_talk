## 1. 准备与验证

- [x] 1.1 在 `app/README.md`（或 `assets/models/README.md`）记录：下载 `vosk-model-small-cn-0.22`、解压至 `assets/models/vosk-model-small-cn-0.22/` 的步骤；说明 release APK 约增 50MB
- [x] 1.2 Spike：在 `pubspec.yaml` 加入 `vosk_flutter_service`、`record`，在目标华为/Android 10 设备上验证能加载模型并完成一句中文转写
- [x] 1.3 配置 `pubspec.yaml` 的 `assets` 包含模型目录；构建脚本或文档：缺模型时 release 构建失败

## 2. 端侧 ASR 模块

- [x] 2.1 新增 `lib/asr/on_device_asr.dart` 抽象（init、startListening、partial 流、stop→final）
- [x] 2.2 实现 `lib/asr/vosk_on_device_asr.dart`：asset 解压到私有目录、Vosk Model/Recognizer、16kHz mono 录音喂入
- [x] 2.3 实现懒加载与错误类型（解压失败、无权限、引擎异常），供 UI 展示简短提示

## 3. 主页集成（Android）

- [x] 3.1 `home_screen.dart`：Android 分支改用 `VoskOnDeviceAsr`，保留按住/松手与 `_partial` UI
- [x] 3.2 松手后非空文本仍走 `sendCommand`；与登录/绑定/WebSocket 门禁逻辑不变
- [x] 3.3 语音模式切换时不再调用 `android_speech_availability` / 安装引擎弹窗

## 4. 清理与依赖

- [x] 4.1 移除或限定 Android 专用：`android_speech_availability.dart`、`speech_services_prompt.dart`、`MainActivity` speech MethodChannel（若仅服务系统 STT）
- [x] 4.2 `pubspec.yaml`：Android 路径不再依赖 `speech_to_text`（若 iOS 仍需要则保留依赖并在 iOS 分支继续使用）
- [x] 4.3 确认 `AndroidManifest.xml` 保留 `RECORD_AUDIO`；移除仅用于查询 Google 语音包的 `<queries>`（若无其它用途）

## 5. 验收

- [x] 5.1 华为无 GMS 真机：安装后**不联网**可按住说话并得到文本（或合理 partial→final）
- [x] 5.2 同机：不出现「去应用市场安装 Google 语音服务」类引导
- [x] 5.3 测量 release APK 体积增量并记入发布说明
- [x] 5.4 用 20 条母婴场景短句记录识别率备注（通过/需优化），供产品决定是否后续换模型

## 6. iOS 设置（用户追加）

- [x] 6.1 设置中心 iOS：可切换「端侧 Vosk」/「系统语音识别」并 `SharedPreferences` 记忆
- [x] 6.2 Android 设置中心仅展示说明（固定 Vosk），不提供切换项
- [x] 6.3 模型随整包内置，不做分包（见 README / assets/models/README.md）
