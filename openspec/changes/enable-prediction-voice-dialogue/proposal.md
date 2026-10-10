## Why

预测页语音对话（KWS「你好，胖宝」+ `/voice/chat/ws` + TTS）此前因「对话模型未训练完成」用编译期 flag 默认关闭。模型已可交付，需在竖屏与横屏一并恢复入口与会话；竖屏仅翻 flag 仍无法 activate（lifecycle 只认横屏），必须一并打通。

## What Changes

- 将 `kPredictionLandscapeVoiceEnabled` 与 `kPredictionPortraitVoiceEnabled` **默认改为 `true`**（仍保留 flag 可关）。
- 修 `syncLandscapeVoiceLifecycle`（或等价）：预测页可见且对应方向 flag 开启时，竖屏与横屏均 MUST `activate`（非 Web 的 Android/iOS）；离开可见预测或 flag 关则 `deactivate`。
- 竖屏恢复 `PredictionVoiceEdgeDock`；横屏恢复左下监听 chip、字幕与 binder——行为对齐既有契约，不新造对话栈。
- **不**改成长轨迹/喂养按住说话 ASR；**不**改 `/voice/chat/ws` 协议。

## Capabilities

### New Capabilities

- （无）行为落在既有预测语音能力上。

### Modified Capabilities

- `prediction-landscape-voice`：产品默认开启横屏语音；flag=`true` 时横屏可见 MUST 可 activate（既有 gate 语义保留）。
- `prediction-portrait-voice-dock`：产品默认开启竖屏语音；flag=`true` 时竖屏可见 MUST 与横屏同等 activate 会话（不得仅有 UI 无会话）。

## Impact

- `app/lib/ucg/data/ucg_feature_flags.dart`：两常量默认 `true`；注释改为可关而非「模型未就绪默认关」。
- `app/lib/providers/landscape_voice_provider.dart`：`syncLandscapeVoiceLifecycle` 的 `want` 条件纳入竖屏∩portrait flag。
- `app/lib/ui/smart_prediction_screen.dart`：既有 binder/UI 分支随 flag 恢复；必要时清理「竖屏改 true 常量」类过时注释。
- 无 Go / 新 WS 端点；平台约束仍为非 Web Android/iOS。
