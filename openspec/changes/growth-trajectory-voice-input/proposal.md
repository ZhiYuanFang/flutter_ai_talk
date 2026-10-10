## Why

成长轨迹预测在 SSE 追问阶段（`free_text`，或 choice 下「手动输入」）需要用户打字补充说明，移动端输入成本高。用户需要按住说话把语音转成中文填入现有输入框，并复用全局已有 ASR（`/voice/asr/ws` + `HomeSpeechRecognizer`），不引入多语翻译、不接预测横屏 dialogue chat。

## What Changes

- 仅在成长轨迹工作台 **提问作答** 且出现文本输入时，提供与伴侣/首页一致的 **按住说话 → 中文转写**。
- 转写结果写入现有 `_freeTextController`；**保留「提交」** 走既有 `submitAnswer` / turn SSE。
- **MUST** 使用全局共用的 `VoiceAsrWsClient`（`voiceAsrWsClientProvider`）与 `createHomeSpeechRecognizer`；**MUST NOT** 新建第二条 ASR 连接或改用 `/voice/chat/ws`。
- choice 双按钮主路径不变；仅「手动输入」展开文本框后显示语音控件。
- 本 change **不**覆盖喂养分析、护理留意、邀码/支付弹窗。

## Capabilities

### New Capabilities

- `growth-trajectory-voice-input`：成长轨迹追问阶段的按住说话填框行为与 ASR 复用约束。

### Modified Capabilities

- `growth-trajectory-predict`：追问 `free_text` / 手动输入态 MUST 提供语音填框入口（交互细节见新 capability）。

## Impact

- UI：`growth_trajectory_screen.dart`（追问 TextField 旁按住控件）。
- ASR：`HomeSpeechRecognizer` / `voice_asr_ws_provider`（ensure connect，不新增 transport）。
- 规格：相对基线 `v2.1.3` 增量；不改 Go growth-trajectory turn API。
