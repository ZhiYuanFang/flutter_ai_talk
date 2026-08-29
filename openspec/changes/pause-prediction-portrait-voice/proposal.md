## Why

预测页竖屏语音对话所依赖的对话模型尚未训练完成，继续对用户展示竖屏入口会造成不可用的体验与不必要的麦克风权限请求。需临时关闭竖屏语音表面，待模型就绪后再翻回。

## What Changes

- 新增编译期开关（如 `kPredictionPortraitVoiceEnabled`，默认 `false`）：关闭时竖屏预测 **完全无** 语音入口（无贴边球、无字幕 toast、无占位提示）。
- 竖屏下 **不得** 对预测语音会话执行 `activate` / 请求麦克风；`_LandscapeVoiceLifecycleBinder` **必须** 按真实横竖屏传参，去掉「写死 landscape: true」的竖屏旁路。
- **横屏** 预测语音（固定监听 chip + 会话）**继续开放**，行为不变。
- 喂养页及其他非预测语音路径 **不在本变更范围**。
- 模型就绪后将开关翻回 `true` 即可恢复竖屏贴边球与既有 `prediction-portrait-voice-dock` 行为。

## Capabilities

### New Capabilities

- （无）本变更为对既有竖屏语音能力的临时闸门。

### Modified Capabilities

- `prediction-portrait-voice-dock`：未开放时竖屏 MUST NOT 展示入口且 MUST NOT activate；开放时仍遵循既有贴边球契约。横屏监听不在此 capability 关闭。

## Impact

- UI / 生命周期：`smart_prediction_screen.dart`（竖屏 Stack 语音层、`_LandscapeVoiceLifecycleBinder`）。
- 开关：宜放在既有 feature flags 旁（如 `ucg_feature_flags.dart`）或预测专用 flags 文件，注释标明暂停原因与翻回条件。
- 语音管线：`landscapeVoiceControllerProvider` / `syncLandscapeVoiceLifecycle` 契约不变；仅修正竖屏误传 `landscape: true`。
- 无后端、不改 `app/android/**`、不新建 `**/test/**`。
- 对照基线 `openspec/specs/v2.1.0.md`；竖屏贴边球来自未/已归档的 `prediction-portrait-voice-edge-dock`。
