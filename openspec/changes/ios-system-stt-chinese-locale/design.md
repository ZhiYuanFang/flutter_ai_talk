## Context

- iOS 默认语音识别引擎为「系统识别」（`SpeechEngine.systemStt`），实现类 `SystemSttHomeSpeechRecognizer` 封装 `speech_to_text` 插件。
- 当前 `listen()` 未传 `localeId`；iOS 原生层（`SpeechToTextPlugin.swift`）在 `localeId` 为空时使用 `Locale.current`，跟随设备系统/首选语言，而非 App 的 `MaterialApp.locale`（`zh_CN`）。
- `speech_to_text` 提供 `locales()` 返回设备已安装听写语言列表；`listen(localeId: ...)` 可指定识别语言。

## Goals / Non-Goals

**Goals:**

- iOS 系统识别按住说话时，以简体中文 locale 启动 `SFSpeechRecognizer`。
- 实现简单、改动面小，仅触及 `system_stt_home_speech_recognizer.dart`。
- 与现有「语音不可用时不阻塞非语音功能」基线兼容。

**Non-Goals:**

- 不新增设置项让用户手动选 STT 语言。
- 不改变云端 ASR、Android 默认引擎或 Web 输入模式。
- 不保证离线/on-device 中文包一定已安装（属 OS 与用户设置范畴）。

## Decisions

### 1. 在 `prepare()` 解析并缓存中文 localeId

**选择**：`prepare()` 成功后调用 `_speech.locales()`，按优先级选取第一个匹配项并缓存为 `_chineseLocaleId`；`startSession()` 传入该值。

**优先级**（`localeId` 不区分大小写、忽略 `-`/`_` 后匹配）：

1. `zh_CN` / `zh-CN`
2. `cmn-Hans-CN` / `cmn_Hans_CN`
3. 任意以 `zh` 或 `cmn-Hans` 开头的 locale

**备选**：每次 `listen()` 硬编码 `localeId: 'zh_CN'`。

**理由**：不同 iOS 版本/设备返回的标识符可能为 `zh-CN` 或 `cmn-Hans-CN`；从 `locales()` 中按规则选取更稳妥。若列表中无中文项，fallback 为 `'zh_CN'`（与 App locale 一致），由插件/OS 处理失败。

### 2. 无中文 locale 时的行为

**选择**：仍尝试 fallback `'zh_CN'`；若 `listen` 失败，沿用现有 `cancelOnError` 与 `home_screen` 错误提示，不新增专用 Toast。

**理由**：与 proposal 一致，最小改动；用户可切云端识别。

### 3. 不修改 `HomeSpeechRecognizer` 接口

**选择**：locale 解析封装在 `SystemSttHomeSpeechRecognizer` 内部。

**理由**：仅 system STT 需要；云端 ASR 语言由服务端决定。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 设备未安装中文听写包，识别失败 | 文档/README 说明需在 iOS 设置中启用中文听写；用户可改用云端识别 |
| `locales()` 在部分设备上为空或不含中文 | fallback `'zh_CN'`；失败时不阻塞文字输入 |
| Android 也走 systemStt 时行为变化 | Android 用户若选手动「系统识别」，同样受益；无破坏性 |

## Migration Plan

- 纯客户端逻辑变更，无数据迁移。
- 发版后 iOS 用户升级即生效；无需服务端配合。
- 回滚：移除 `localeId` 传参即可恢复旧行为。

## Open Questions

- 无。实现范围已明确。
