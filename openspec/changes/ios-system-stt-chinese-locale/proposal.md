## Why

iOS 上选择「系统识别」按住说话时，识别结果常为英文而非中文。根因是 `SystemSttHomeSpeechRecognizer` 调用 `speech_to_text.listen()` 时未指定 `localeId`，插件回退到设备系统语言（`Locale.current`），与 App 固定中文 UI（`zh_CN`）不一致。胖宝是中文母婴记录场景，系统识别应默认识别简体中文。

## What Changes

- 在 `SystemSttHomeSpeechRecognizer` 的 `listen()` 调用中显式传入简体中文 `localeId`（优先从设备可用 locale 列表解析，与 App `zh_CN` 对齐）。
- `prepare()` 阶段可选解析并缓存首选中文 locale，避免每次按住说话重复查询。
- 当设备未安装中文听写语言包时，保持现有错误处理路径（不崩溃；用户可改用云端识别或文字输入）。
- 不改变设置页引擎选项、默认引擎策略（iOS 仍默认系统识别）及云端 ASR 行为。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `speech-engine-without-vosk`：补充 iOS 系统 STT 必须使用简体中文 locale 识别的需求。

## Impact

- **代码**：`app/lib/asr/system_stt_home_speech_recognizer.dart`（主要改动点）。
- **依赖**：无新增；继续使用现有 `speech_to_text` ^7.x。
- **平台**：仅影响 iOS（及共用该类的其它非 Android 云端默认路径）；Android 云端识别不受影响。
- **用户可见**：iOS「系统识别」下按住说话应输出中文转写（在设备已启用中文听写的前提下）。
