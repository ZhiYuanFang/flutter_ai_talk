## ADDED Requirements

### Requirement: Android 使用内置 Vosk 模型进行离线转写

The Android client MUST perform press-and-hold speech recognition using an on-device Vosk model bundled in the application package, without requiring the user to install a system speech engine or download the model from the network on first use. Android 客户端必须使用**随安装包内置**的 Vosk 中文小模型（`vosk-model-small-cn-0.22` 或设计文档指定的等价版本）完成按住说话转写；**不得**要求用户安装 Google Speech Services 或其它系统语音引擎；**不得**将「首次联网下载模型」作为主交付路径。

#### Scenario: 安装后离线按住说话

- **WHEN** 用户在 Android 上已安装应用、无 Google 语音服务、设备可访问麦克风，且用户按住说话并松手
- **THEN** 系统必须在本地将语音转为文本，且不得弹出引导前往应用市场安装语音引擎的对话框

#### Scenario: 无网络仍可转写

- **WHEN** 设备处于飞行模式或无法访问互联网，且用户完成一次按住说话
- **THEN** 系统仍必须完成本地转写（若麦克风与模型可用）；仅在上传指令时可能因无网失败，该失败与 ASR 无关

### Requirement: 模型随 APK 内置并在本地解压复用

The Android client MUST ship the Vosk model inside the installable artifact and MUST copy or extract it to app-private storage before recognition. 中文 Vosk 模型目录必须包含在可安装的 APK/AAB 产物中（Flutter `assets` 或 Android `assets`）；首次需要识别时，客户端必须将模型解压或复制到应用私有目录并在后续识别中复用，**不得**依赖用户从应用市场或浏览器下载模型文件。

#### Scenario: 首次使用语音前准备模型

- **WHEN** 用户第一次在 Android 上触发语音输入且私有目录中尚无可用模型文件
- **THEN** 客户端必须从内置资源解压模型到私有目录，完成后方可开始识别；该过程不得要求用户离开应用去外部商店下载

### Requirement: 音频格式与识别输出

The Android client MUST capture mono PCM at 16 kHz (or the sample rate required by the loaded Vosk model) and MUST expose partial and final transcript text to the home input flow. 录音必须为与 Vosk 兼容的格式（默认 **16 kHz、单声道、PCM16**）；按住期间可向 UI 提供 **partial** 文本；松手后必须产出 **final** 文本供主页逻辑使用。

#### Scenario: 松手后提交文本指令

- **WHEN** 用户松手且 final 转写文本经 trim 后非空
- **THEN** 系统必须以该文本为载荷调用与现有主页一致的指令发送逻辑（`sendCommand` 或 Mock 等价物），且不得上传原始音频到 ASR 厂商

### Requirement: 识别失败时回退文字输入

The Android client MUST allow text input when on-device ASR is unavailable and MUST NOT block non-voice features. 当模型解压失败、麦克风权限被拒、或识别引擎初始化失败时，系统必须允许用户继续使用文字输入发送指令；**不得**因语音不可用而阻止登录、历史浏览或其它非语音功能。

#### Scenario: 麦克风权限被拒

- **WHEN** 用户拒绝 `RECORD_AUDIO` 并尝试语音输入
- **THEN** 系统必须提示权限原因并保留文字输入路径，且不得反复弹出「安装语音引擎」类引导

### Requirement: 不得引导安装第三方系统语音引擎（Android）

The Android client MUST NOT prompt the user to install or switch Google Speech Services (or equivalent system recognition packages) as a prerequisite for home voice input. 在 Android 上，系统**不得**再展示「前往应用市场安装 Google 语音服务」或「切换默认识别引擎」作为使用主页语音的前置条件（相关检测与弹窗必须移除或仅用于已废弃路径）。

#### Scenario: 华为无 GMS 设备打开语音

- **WHEN** 用户在华为等无 Google 移动服务的设备上选择语音输入模式
- **THEN** 系统必须直接进入内置 Vosk 流程或展示与 Vosk 相关的准备状态，而非应用市场安装 Google 引擎的引导

### Requirement: iOS 可在设置中心切换语音后端并记忆

The iOS client MUST let the user choose between on-device Vosk and system STT in Settings and MUST persist the choice across app restarts. Android MUST NOT expose an equivalent switch and MUST always use on-device Vosk. iOS 客户端必须在设置中心提供「端侧 Vosk」与「系统语音识别」选项，并将选择持久化；**Android 不得**提供同类切换，且必须始终使用内置 Vosk。

#### Scenario: iOS 切换为系统识别

- **WHEN** 用户在 iOS 设置中心选择「系统语音识别」并返回主页按住说话
- **THEN** 系统必须使用 `speech_to_text`（或等价系统 STT）转写，而非 Vosk

#### Scenario: Android 设置页无切换项

- **WHEN** 用户在 Android 打开设置中心
- **THEN** 系统不得展示 Vosk/系统 STT 切换控件；可展示只读说明「内置 Vosk 离线引擎」
