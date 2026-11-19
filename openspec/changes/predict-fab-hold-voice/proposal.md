## Why

预测竖屏需要「类语音球」记录能力，但不该再维护贴边唤醒球；底部「去记录」pill 已是自然入口。同时竖屏回复只展示文案、跳过服务端 TTS，避免无谓的百度合成消耗；横屏仍保留唤醒 + 播报。

## What Changes

- 预测竖屏「去记录」pill 增加副文案「· 长按语音记录」；**短按**仍切喂养页，**长按按住**进入语音对话（PTT）。
- 从横屏语音编排抽出「无唤醒 hold」会话 API：页可见预连 `/voice/chat/ws`，长按后播与唤醒相同的本地 ding，再 `beginListen`；松手为唯一业务 `commit`；滑出超过 pill 外容错距离后松手可取消。
- 竖屏 hold 会话 `start` 带 `outputModality=text`（Go 已支持），客户端以 `answer` 收口话轮、只展示字幕；横屏仍 `audio` + TTS 播报。
- 竖↔横旋转时撕掉进行中会话，下一轮 `start` 按当前方向切换 text/audio。
- **BREAKING（产品）**：删除竖屏预测语音贴边球（`PredictionVoiceEdgeDock` / `kPredictionPortraitVoiceEnabled` 及相关 engage 链路）；竖屏不再常驻 KWS 唤醒。
- 基础版能力墙原「语音球唤醒对话」条目：文案改为长按记录导向；点击关墙后让「去记录」pill **心跳 3 次**（仅吸引注意，不自动开麦）。
- 竖屏答复/听写展示复用 `LandscapeVoiceSubtitleToast`；无退场音。

## Capabilities

### New Capabilities

- `prediction-fab-hold-voice`：竖屏「去记录」长按 PTT、预连、无唤醒、text 输出、滑出取消、与横屏 modality 切换的契约。

### Modified Capabilities

- `prediction-go-record-fab`：副文案、短按/长按分工、心跳指引消费。
- `prediction-portrait-voice-dock`：移除竖屏贴边球/portrait flag 产品契约，改为 MUST NOT 再展示该入口。
- `prediction-landscape-voice`：明确常驻唤醒与 audio TTS 仅横屏；旋转时会话撕除与 modality 切换；权限入口不再引用竖屏球。
- `voice-chat-ws`：`start` 支持按会话 `outputModality`；text 模式以 `answer` seal，不得死等 `audio_end`。
- `predict-capability-tier-wall`：基础版「语音球」条目文案与行为改为 FAB 心跳指引。

## Impact

- App：`PredictionGoRecordFab`、`SmartPredictionScreen` / `UcgHomeShell`、`LandscapeVoiceController` / `VoiceChatWsClient`、基础版墙与 `predict_basic_feature_action_providers`、竖屏 dock 相关文件与 flag。
- Go：无需改协议；复用已有 `outputModality=text|audio`。
- Spec：竖屏语音入口从 EdgeDock 唤醒迁到 FAB PTT；横屏语音球路径保持。
