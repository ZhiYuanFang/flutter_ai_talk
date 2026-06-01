## Context

- 现状：`home_screen.dart` 使用 `speech_to_text`，Android 经系统 `SpeechRecognizer` 转写；华为设备存在 Fake 服务、SecurityException 及「去应用市场装 Google 引擎」死胡同。
- 约束：仅上传**文本**至既有 `FeedRepository.sendCommand`；用户明确 **Vosk + 增大包体内置模型**，不要百度付费云端、不要首次联网下模型。
- 参考模型：[vosk-model-small-cn-0.22](https://alphacephei.com/vosk/models)（约 42MB 压缩包，解压后略大）。

## Goals / Non-Goals

**Goals:**

- Android 按住说话在无 Google 服务的华为机上可用。
- 模型随 APK 安装，**离线**可用（除发送指令本身所需的网络）。
- 统一 ASR 抽象，便于 `home_screen` 在 Android 走 Vosk、其它平台走现有实现。
- 去掉「安装/切换系统语音引擎」用户路径。

**Non-Goals:**

- iOS/Web 改用 Vosk（除非实现阶段发现成本极低，默认不改）。
- 网关侧 ASR、百度/讯飞 SDK。
- 运行时从 CDN 拉模型（仅作应急备选，本设计不采用）。
- Grammar/热词定制（后续迭代）。

## Decisions

### 1. 引擎：Vosk（非百度、非系统 STT）

| 选项 | 结论 |
|------|------|
| Vosk 内置模型 | **选用** — 满足端侧、免费、华为可离线 |
| 百度付费语音识别 | **不选用** — 费用、密钥、音频上云、与「非付费 SDK」冲突 |
| 继续 `speech_to_text` | **Android 弃用** — 根因未消除 |

### 2. 模型交付：随 APK 内置（增大包体）

- 将 `vosk-model-small-cn-0.22` 以 **Flutter assets**（推荐 `assets/models/vosk-model-small-cn-0.22/`）或 Android `assets` 形式打入安装包。
- **首次**需要识别时：若私有目录尚无解压后的模型，从 asset **一次性解压**到 `getApplicationSupportDirectory()`（或 `path_provider` 等价路径），后续直接 `Model(path)` 加载。
- **不**在首启强制联网；**不**弹窗引导用户去应用市场装语音引擎。
- 版本升级：模型目录带版本子路径（如 `vosk-cn-0.22`），避免旧缓存与新区块不兼容。

**备选（本变更不采用）**：首次启动从 CDN 下载 — 包体小但违背当前产品选择。

### 3. Flutter 集成：`vosk_flutter` + `record`

- 使用社区维护的 `vosk_flutter`（alphacep 生态）绑定 Android 原生 Vosk；实现前在目标 Flutter/NDK 版本上做一次 **spike 编译**（项目已有 NDK/CMake 链）。
- 录音：`record` 插件输出 **16 kHz、mono、PCM16**，与 Vosk `Recognizer.acceptWaveform` 一致；按住期间周期性喂入音频块，UI 显示 `partial`，松手取 `final` 文本。
- 抽象层建议：`OnDeviceAsrService` 接口，`VoskOnDeviceAsr`（Android 实现）、`SpeechToTextAsr`（iOS 可选保留）。

### 4. 主页集成

```
按住 (onVoiceStart)
  → 确保模型已解压 + Recognizer 已创建
  → 开始 record 流
  → 循环 acceptWaveform → 更新 _partial UI
松手 (onVoiceEnd)
  → 停止录音 → final result
  → trim 非空则 sendCommand(text)
```

- 初始化：**懒加载**（用户第一次切到语音模式或第一次按住时），避免冷启动阻塞；可显示简短「正在准备语音…」。
- 权限：沿用 `RECORD_AUDIO`；拒绝权限时仅文字输入。

### 5. 清理华为/Google 引擎引导

- 删除或 `#ifdef` 仅 Android 不再使用的：`android_speech_availability.dart`、`speech_services_prompt.dart`、`MainActivity` 中 `com.pangbao.pangbao_app/speech` channel（若仅服务 STT 检测）。
- `pubspec.yaml`：Android 构建可移除 `speech_to_text`（若 iOS 仍需要则保留依赖，平台分支调用）。

### 6. 包体与仓库策略

- 模型体积大：**不建议**提交到 Git；在 `app/README.md` 或 `assets/models/README.md` 说明下载地址、解压后放置路径、CI 拷贝步骤。
- Release 构建脚本可增加「若缺少模型目录则失败」的检查，避免发空包。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 小模型中文准确率不足（母婴口语、噪声） | 上线前用 20+ 条真实话术在华为机验收；不达标再评估 Sherpa-ONNX 或 medium 模型（另开变更） |
| APK 增大 ~50MB 影响下载转化 | 发布说明写清；必要时后续做 AAB + Play 按需分发（国内渠道仍整包） |
| `vosk_flutter` 与当前 Gradle/NDK 不兼容 | 实现任务 0：spike；失败则评估 FFI 直连 vosk-api |
| 冷启动/首次解压耗时 | 后台 isolate 解压；语音模式懒加载 + 进度提示 |
| 内存占用（约数百 MB 运行时） | 不在后台长期持有 Recognizer；松手后释放或单例复用 |

## Migration Plan

1. 引入依赖与 assets 占位文档；本地/CI 放置模型。
2. 实现 `VoskOnDeviceAsr` + 单元/手工验证转写。
3. `home_screen` Android 分支切换；保留文字输入。
4. 移除 Android 系统 STT 引导代码。
5. 华为 CLT AL00（或无 GMS）真机：离线按住说话 → `sendCommand` 成功。
6. 回滚：恢复 `speech_to_text` 分支（保留 git 历史即可）。

## Open Questions

- **已决**：iOS 在设置中心可切换 Vosk / 系统 STT 并记忆；Android 固定 Vosk，设置页仅说明。
- iOS 构建前需 `dart run vosk_flutter_service install -t ios`（见 README）。
- 是否在设置页展示「语音模型版本」供客服排查（可选，非阻塞）。
- 国内应用商店对 APK 体积上限是否需分包（实现时按渠道要求调整）。
