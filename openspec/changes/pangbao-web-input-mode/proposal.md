## Why

当前主页在 Web 上固定为文本输入，无法在不改代码的情况下切换为与移动端一致的按住说话体验。产品需要一种**工程上单一来源**的配置（全局开关），便于按环境或发布策略选择 Web 主输入为文字或语音，而无需在业务组件内散落判断。

## What Changes

- 引入**全局可解析的 Web 主输入模式**（文本 / 语音），在 `kIsWeb` 为真时决定主页主控件展示为现有 `TextField` 提交流还是与 Android/iOS 对齐的按住说话 + STT 流。
- 非 Web 平台**不得**因该配置改变行为（仍仅为语音球 + STT）。
- 默认值与现状一致：**Web 仍为文本主输入**，避免静默改变线上行为。
- 更新与「主页输入 / 历史 / SSE」相关的规范：放宽原「Web 不得语音」的绝对表述，改为**由全局配置决定**。

## Capabilities

### New Capabilities

- `web-home-input-mode`：定义全局配置项的语义、生效范围（仅 Web）、默认值及与主页实现的对应关系。

### Modified Capabilities

- `home-input-history-sse`（见变更 `pangbao-app` 下同名 spec）：修改「主输入方式按平台区分」需求，使 Web 侧在配置为语音模式时允许语音主输入，并保持载荷仍为转写后的文本。

## Impact

- 代码：`app/lib/ui/home_screen.dart`（分支与 `speech_to_text` 在 Web 上的初始化）、可能新增小型配置模块（如 `lib/config/...` 或 `dart-define` 读取）。
- 依赖：确认 `speech_to_text` 在 Flutter Web 目标上的支持情况；若不支持，需在实现阶段采用 Web Speech API 等备选（见 design）。
- 构建/CI：若采用 `dart-define`，需在文档中说明构建参数。
