## Why

使用 AI 对话（`sendCommand`）时，客户端会将用户输入内容及近期喂养数据发送至第三方 AI 服务分析；在用户未明确知悉并同意前，不应允许发起该数据出口。当前登录页仅有通用隐私政策提示，缺少针对 AI 对话的专项知情同意门，需在语音按住与文字提交两条路径上统一拦截。

## What Changes

- 新增本地持久化的 **AI 对话数据知情同意** 状态（同意后不再弹窗；不提供设置中心撤回）。
- 未同意时：**每次按住语音球** 或 **每次文字提交** 均弹出告知对话框；点「同意并继续」视为知悉并同意，写入本地并继续当前操作。
- 未同意时：不得调用 `sendCommand`（含语音松手发送与文字提交）；不得进入语音录音/`startSession`。
- 告知文案统一说明 chat 会将输入内容与近期喂养数据发送至第三方 AI，**不区分**云端 ASR 与 iOS 系统识别；弹窗**无**勾选框、**无**「查看隐私政策」入口。
- 复用现有玻璃确认对话框样式（`showGlassConfirmDialog`），确认按钮文案为「同意并继续」。

## Capabilities

### New Capabilities

- `ai-chat-data-consent`: 首页 AI 对话（`sendCommand`）前的知情同意门、持久化与弹窗交互。

### Modified Capabilities

（无。本变更不修改既有 spec 基线的行为定义，仅在 `sendCommand` 调用前增加同意门；语音 ASR、登录隐私等既有能力保持不变。）

## Impact

- **代码**：`app/lib/ui/home_screen.dart`（`_onVoicePointerDown`、`_onTextSubmit`）；新增 consent store（如 `app/lib/config/ai_chat_data_consent_store.dart`）；可选抽取 `_ensureAiChatDataConsent()` 辅助方法。
- **数据**：SharedPreferences 新增布尔键；登出策略见 design（默认不清除，与设备本地偏好一致）。
- **API**：无网关契约变更；仍调用 `POST /device/history/api/chat`。
- **合规/产品**：按钮记录模式不受影响；同意后永久生效直至卸载或清数据。
