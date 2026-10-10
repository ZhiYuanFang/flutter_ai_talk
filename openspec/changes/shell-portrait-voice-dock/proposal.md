## Why

竖屏语音球目前只挂在智能预测页 Stack 内，滑到喂养 / UCG 即消失且会话随 `predictionVisible` 拆掉。产品需要主壳三页竖屏常驻同一贴边球，滑动切页不断会话；此前 explore 已收敛范围，尚未落地。

## What Changes

- 将竖屏 `PredictionVoiceEdgeDock` + 字幕 toast + 竖屏 lifecycle binder 从 `SmartPredictionScreen` **上移**到 `UcgHomeShell` Stack（盖住 PageView）。
- 竖屏会话 `want`：**主壳挂载 ∩ 主壳路由 `isCurrent` ∩ 竖屏 ∩ 竖屏 flag ∩ 非 Web Android/iOS**；**不再**要求预测页可见。
- 当前页为 UCG 且资格未合格时 **藏球**（不浮在 `FeatureLockOverlay` 之上）。
- **横屏**监听 chip / binder / `predictionVisible` 门禁 **本变更不改**，仍只在预测页。
- 预测页内移除竖屏球挂载，避免双球。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `prediction-portrait-voice-dock`: 竖屏入口宿主从「仅智能预测页」改为「主壳三页竖屏」；activate 与预测页可见脱钩；补充 UCG 未合格藏球与推入子路由时 deactivate。

## Impact

- **代码**：`ucg_home_shell.dart`、`smart_prediction_screen.dart`、`landscape_voice_provider.dart`（`syncLandscapeVoiceLifecycle` 参数/语义）、可能抽出共享 binder/字幕小组件以免壳层复制私有类。
- **不改**：`/voice/chat/ws` 协议、横屏 chip、广场贴边球、喂养按住 ASR（喂养已锁按钮模式）。
- **关联**：依赖已开启的 `kPredictionPortraitVoiceEnabled`（`enable-prediction-voice-dialogue`）。
