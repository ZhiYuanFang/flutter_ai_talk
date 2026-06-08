## Context

- **现状**：`home_screen.dart` 通过 `_showButtonsInputMode => !kIsWeb` 与 `_isInputChannelAvailable` 在 Web 上禁用 `HomeInputChannel.buttons`；Web 初始 channel 为 `voice`，再由 `WebHomeInputMode`（`WEB_HOME_INPUT` dart-define）覆盖为 `text` 或保持 voice。`_canSwitchInputMode` 在 Web 默认 text 时为 false，dock 不显示；voice 模式下 dock 在 voice ↔ text 间轮转，但 `_prepareVoiceInput()` 在 Web 直接 toast 失败。
- **既有组件**：`HomeButtonEventGrid`、`showEventCatalogPickerSheet`、`_onEventGridTap` 无 Web 平台守卫，放开 buttons 即可复用完整记事件路径。
- **游客门禁**：`blockHomeInputChrome`（未登录或未绑宝宝）时已强制 `buttons` 并隐藏 dock，与 App 一致，本变更保持不变。
- **基线**：`openspec/specs/v1.0.1.md` 中 `home-button-input-mode` 明确「Web 不修改」；`web-home-input-mode` 定义默认 text；`home-input-mode-dock` 定义 Web text-only 不显示 dock。

## Goals / Non-Goals

**Goals:**

- Web 冷启动默认事件按钮网格，与 Android/iOS 一致。
- 已登录且已绑宝宝时，Web dock 在 **buttons ↔ text** 间轮转；text 模式保留 Enter/提交 NLU 路径。
- 删除 `web_home_input_mode.dart` 与 `WEB_HOME_INPUT` 构建参数。
- `HomeInputModeDock` 支持平台化 channel 轮转列表，避免 `showButtonsOption` 布尔无法表达 Web `[buttons, text]`。
- 持久化：Web 接受 `buttons`/`text`，忽略 `voice` → 回退 `buttons`。

**Non-Goals:**

- Web 端语音输入（不实现、不保留 `WEB_HOME_INPUT=voice`）。
- 修改事件网格布局、eventType 分支、NLU 接口或游客路由。
- 修改移动端 voice ↔ buttons 行为。

## Decisions

### 1. 全平台默认 `HomeInputChannel.buttons`

**Decision**：`_inputChannel` 初始值统一为 `buttons`；移除 Web 对 `voice`/`text` 的 initState 覆盖。

**Why**：与产品决策「Web 默认和 App 一样」一致；减少平台分支。

**Alternatives**：Web 仍默认 text、仅 dock 可切 buttons — 与已确认产品方向不符。

### 2. Dock 传入显式 `dockCycleChannels`

**Decision**：`HomeInputModeDock` 新增 `List<HomeInputChannel> dockCycleChannels` 参数，由 `HomeScreen` 传入：

- Mobile：`[HomeInputChannel.buttons, HomeInputChannel.voice]`
- Web：`[HomeInputChannel.buttons, HomeInputChannel.text]`

移除或弃用 `showButtonsOption` 布尔（实现期可保留为 deprecated 别名，最终以 `dockCycleChannels` 为准）。

**Why**：现有 `showButtonsOption ? [buttons, voice] : [voice, text]` 无法表达 Web 需求。

**Alternatives**：新增 `enum DockPlatformSet { mobile, web }` — 多一层间接，扩展性不如显式列表。

### 3. 删除 `WebHomeInputMode` 与 `WEB_HOME_INPUT`

**Decision**：删除 `app/lib/config/web_home_input_mode.dart`；移除 `home_screen.dart` 中所有 `_webHomeInputMode` / `resolveWebHomeInputMode` 引用；README 删除相关 dart-define 说明。

**Why**：新模型下 Web 行为由 buttons 默认 + dock 承担，无需编译期开关；`voice` 路径在 Web 本就不可用。

**Alternatives**：保留 `WEB_HOME_INPUT=text` 作调试 — 用户明确选择完全删除。

### 4. Web 可用 channel 与 dock 显示

**Decision**：

- `_isInputChannelAvailable`：Web 允许 `buttons`、`text`；`voice` 为 false。
- `_canSwitchInputMode`：Web 恒为 true（与移动端一致，仍受 `blockHomeInputChrome` 隐藏 dock）。
- `_showButtonsInputMode`：删除或改为恒 true；平台差异仅体现在 `dockCycleChannels`。

**Why**：简化谓词；dock 显示逻辑与移动端对齐。

### 5. 持久化恢复规则

**Decision**：

| 平台 | 有效持久化 | 无效 → 默认 |
|------|-----------|------------|
| Android/iOS | `buttons`, `voice` | `text` → `buttons` |
| Web | `buttons`, `text` | `voice` → `buttons` |

移除 `_restoreSavedInputChannel` 中「Web text-only 拒绝非 text」分支。

### 6. Web dock 仍限制左右吸附

**Decision**：保留 `restrictToHorizontalEdges: kIsWeb`，不改动 dock 几何行为。

**Why**：既有 Web 交互约定，与本变更无关。

## Risks / Trade-offs

- **[Risk] 习惯 Web 默认文字框的开发者需多点一次 dock** → README 与变更说明注明；text 仍一键可达。
- **[Risk] 本地持久化 `text` 的用户升级后若曾存 `voice`（旧 Web voice 模式）** → 恢复时回退 `buttons`，可接受。
- **[Risk] `showButtonsOption` 其它引用点遗漏** → 实现时全仓 grep 并统一改为 `dockCycleChannels`。
- **[Risk] 事件网格在宽屏布局** → 复用现有 `HomeButtonEventGrid`，无新布局；若体验问题另开变更。

## Migration Plan

1. 合并代码后 Web 冷启动即见按钮网格；无需服务端变更。
2. 删除 `WEB_HOME_INPUT`：CI/脚本中若引用该 dart-define 需同步删除（仓库内 grep 确认）。
3. 回滚：恢复 `web_home_input_mode.dart` 与 `kIsWeb` 门禁即可，无数据迁移。

## Open Questions

（无 — 产品方向已在 explore 阶段确认：游客仅 buttons、完全删除 `WEB_HOME_INPUT`。）
