## Context

首页 AI 对话通过 `FeedRepository.sendCommand` 调用 `POST /device/history/api/chat`，载荷为 `deviceNo` + `transcript`；服务端会结合近期喂养数据生成 AI 回复。当前仅有登录/注册页的通用《用户协议》《隐私政策》提示，无针对 AI 对话数据出口的专项同意。

`sendCommand` 在客户端仅有两处调用：
- `HomeScreen._onVoiceEnd`（语音松手后）
- `HomeScreen._onTextSubmit`（文字提交）

语音按住流程在 `_onVoicePointerDown` 中依次通过 `_ensureRemoteGate`、`_ensureHistoryWsForSend`、`_prepareVoiceInput` 后才 `startSession`。同意门应置于开录之前，避免未同意时采集麦克风。

## Goals / Non-Goals

**Goals:**

- 未同意时拦截所有 `sendCommand` 路径（语音与文字）。
- 未同意时，每次按住语音球或每次文字提交均展示同一告知弹窗；「同意并继续」持久化同意后不再弹窗。
- 弹窗文案统一、轻量：无勾选框、无隐私政策链接；不区分 ASR 引擎。
- 与现有 `_voiceHoldSeq` 竞态机制兼容：弹窗期间松手则同意后不自动开录。

**Non-Goals:**

- 设置中心撤回同意入口。
- 弹窗内展示隐私政策或用户协议链接。
- 修改网关 API、ASR WebSocket 协议或登录页隐私文案。
- 拦截按钮记录模式（非 `sendCommand` 路径）。

## Decisions

### 1. 持久化：`AiChatDataConsentStore`

- 新建 `app/lib/config/ai_chat_data_consent_store.dart`，使用 SharedPreferences 布尔键（建议 `ai_chat_data_consent_v1`）。
- `load()` → `bool`；`saveAccepted()` 在用户点「同意并继续」时写入 `true`。
- **登出不清除**：与 `SpeechEngineStore` 等设备级偏好一致；卸载或清应用数据自然失效。无撤回 API。

### 2. 统一门控：`_ensureAiChatDataConsent()`

在 `HomeScreen` 内抽取私有方法：

```dart
Future<bool> _ensureAiChatDataConsent({required int? voiceHoldSeq}) async
```

- 若 `AiChatDataConsentStore.load()` 为 `true` → 直接返回 `true`。
- 否则调用 `showGlassConfirmDialog`：
  - **title**: `使用 AI 对话前请知悉`
  - **message**: `您输入的内容及近期喂养记录将发送至第三方 AI 服务，用于分析与回复。`
  - **cancelLabel**: `取消`
  - **confirmLabel**: `同意并继续`
- 用户确认 → `saveAccepted()` → 返回 `true`；取消 → 返回 `false`。
- 若传入 `voiceHoldSeq`，在弹窗关闭后检查 `_isVoiceHoldCurrent(voiceHoldSeq)`；若用户已松手则仍返回 `true`（已同意）但**调用方**不得继续开录（见决策 3）。

**为何不在 Repository 层拦截**：同意是 UI/合规关注点，且仅首页两处入口；在 `HomeScreen` 门控与现有 `_ensureRemoteGate` 模式一致。

### 3. 集成点

| 路径 | 调用位置 | 行为 |
|------|----------|------|
| 语音按住 | `_onVoicePointerDown`，在 `_ensureRemoteGate` 之后、`_ensureHistoryWsForSend` 之前 | 未同意 → 弹窗；取消 → return，不开录；同意且仍按住 → 继续后续门控与 `startSession` |
| 文字提交 | `_onTextSubmit`，在 `_ensureRemoteGate` 与 `_ensureHistoryWsForSend` 之后、`sendCommand` 之前 | 未同意 → 弹窗；取消 → return，不清空输入框；同意 → `sendCommand` |

`_onVoiceEnd` **不再**重复门控：能进入 `_listening` 说明按下时已同意。

### 4. 弹窗 UI

复用 `showGlassConfirmDialog`，不新增 checkbox 组件、不嵌入 `buildAuthPrivacyAgreement`。点击「同意并继续」即视为知悉并同意，无需二次勾选。

### 5. 告知范围文案

单一文案，不提及云端 ASR、系统 STT 或音频上传差异；聚焦 **chat 会将输入 + 近期喂养数据发往第三方 AI**。与产品/legal 后续可微调措辞，但须保持「输入内容 + 近期喂养记录 + 第三方 AI」三要素。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 按住期间弹窗，用户松手后误开录 | 同意后检查 `_isVoiceHoldCurrent(seq)`，无效则 return |
| 每次提交/按住都弹，体验打扰 | 一次性持久化同意；属合规有意设计 |
| 无撤回，用户误点同意 | 产品接受；仅卸载/清数据可重置；不在本变更范围 |
| 登出后仍视为已同意 | 与设备本地偏好一致；若未来需跟账号走可另开变更 |

## Migration Plan

- 纯客户端增量；旧用户升级后首次按住或提交文字即见弹窗。
- 无服务端迁移；无 feature flag 要求。
- 回滚：移除门控与 store 即可恢复旧行为。

## Open Questions

（无。探索阶段已确认：文字提交同样每次弹窗；无撤回；无政策链接。）
