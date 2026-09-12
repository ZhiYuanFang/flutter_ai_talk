## Why

预测页横屏唤醒对话依赖的对话模型尚未训练完成；竖屏入口已用 `kPredictionPortraitVoiceEnabled` 关掉，横屏监听 chip / KWS / chat 仍会要麦并进入不可用会话。需临时关闭整条横屏语音助手表面，待模型就绪再翻回。

## What Changes

- 新增编译期开关 `kPredictionLandscapeVoiceEnabled`（默认 `false`）：关闭时横屏预测 **完全无** 语音表面（无生命周期 activate、无左下监听 chip、无字幕 toast）。
- `syncLandscapeVoiceLifecycle`（及 binder 挂载）在 flag 为 false 时 **必须**视为不需要会话，**不得** `activate` / 请求麦克风 / 启动 KWS。
- **竖屏**继续由既有 `kPredictionPortraitVoiceEnabled` 控制；本变更不改其默认 `false`。
- **不删除** `landscape_voice_provider` / KWS / chat WS 实现；模型就绪后将横屏 flag 翻 `true` 即可恢复。
- 喂养页及其他非预测语音路径 **不在本变更范围**。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `prediction-landscape-voice`：未开放时横屏 MUST NOT 展示语音入口且 MUST NOT activate；开放时仍遵循既有唤醒/会话契约。
- `landscape-voice-listen-chip`：未开放时 MUST NOT 展示监听 chip。

## Impact

- 开关：`app/lib/ucg/data/ucg_feature_flags.dart`（旁注竖屏 flag 文案：横屏改由新开关管）。
- UI / 生命周期：`smart_prediction_screen.dart`（横屏 binder、chip、字幕）；`syncLandscapeVoiceLifecycle` 双保险。
- 无后端、不改 `app/android/**`、不新建 `**/test/**`。
- 对照基线 `openspec/specs/v2.1.0.md`；横屏语音细则来自未/已归档的 `prediction-landscape-voice` 系列 change；对称参考 `pause-prediction-portrait-voice`。
