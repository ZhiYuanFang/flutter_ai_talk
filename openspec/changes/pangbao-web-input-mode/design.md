## Context

- 现状：`HomeScreen` 用 `kIsWeb` 在 Web 上渲染 `_buildWebInput`，且在 `initState` 中仅在 `!kIsWeb` 时初始化 `speech_to_text`。
- 既有规范（`pangbao-app` 的 `home-input-history-sse`）写明 Web 主控件不得语音采集；本变更将改为**可配置**。
- 用户诉求中的「全局变量」理解为：**单一源码位置或构建期开关**，供团队显式切换，而非终端用户在 App 内频繁切换（后者可作为后续能力）。

## Goals / Non-Goals

**Goals:**

- 提供**一处**即可切换的 Web 主输入模式：**文本**（当前行为）或**语音**（与移动端一致的按住说话交互，最终以转写文本提交）。
- 默认保持**文本**，保证未改构建参数时行为与现网一致。
- 非 Web 构建路径不受影响。

**Non-Goals:**

- 本变更不要求在设置页提供 UI 开关（若后续需要，可单独提案）。
- 不要求识别「手机浏览器 vs 桌面浏览器」的自动切换（与此前讨论解耦）。
- 不规定具体语音识别在 Web 上的实现细节（插件 vs `dart:js_interop`），由实现任务在验证浏览器支持后选定。

## Decisions

| 决策 | 选择 | 理由 |
|------|------|------|
| 配置形态 | 优先：**单文件顶层常量**（或 `bool.fromEnvironment` 的 `dart-define`）二选一或组合：常量便于本地改一行；`dart-define` 便于 CI 多环境 | 符合「全局变量」心智；避免过早引入复杂配置中心 |
| 默认值 | `text`（与当前一致） | 避免破坏性变更 |
| 语音在 Web 上的技术路径 | 实现阶段：**先尝试**沿用 `speech_to_text` 在 Web 上初始化与 `listen`；若包或浏览器不支持，再落 **Web Speech API** 薄封装 | 减少重复代码；保留退路 |
| 与 Riverpod 关系 | 可选：用 `Provider` 暴露枚举仅便于测试；**规范上的真值**仍以编译期/单文件全局为准 | 避免把「全局」误解为运行时多实例状态 |

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| iOS Safari / 部分浏览器对语音识别限制多 | 文档注明支持矩阵；语音模式下初始化失败时**降级为文本输入**并 `debugPrint` 或 SnackBar 提示 |
| `speech_to_text` 在 Web 不可用 | design 已列 Web Speech API 备选；任务中包含验证 |
| 团队误开语音导致体验回退 | 默认文本；README 或 `app/README.md` 中说明如何开启 |

## Migration Plan

- 合并后默认无操作即可保持原 Web 文本行为。
- 需在 Web 语音环境验证时：按文档设置常量或 `--dart-define`，执行 `flutter run -d chrome` 及目标移动浏览器手测。

## Open Questions

- 是否在后续迭代将「设置页持久化」与「全局默认值」分层（本地覆盖 > 构建默认值）。
