## Why

成长轨迹追问已支持按住说话填框（`growth-trajectory-voice-input`），但输入区仍是默认描边 TextField + 扁按住条，长文案不便阅读，按住时也无能量反馈。需要自适应增高输入、功能色浅玻璃，以及可全局复用的语音能量柱原子（本 change 轨迹先用，首页后迁）。

## What Changes

- 追问文本输入：随文案增高，**最大高度 120**；触顶后自动滚到底；语音结束后仍可滚动查看/编辑。
- 输入框与按住说话条：工作台 **功能色浅玻璃**（成长 `resolveFeatureColor`），不得用无主题硬编码灰边框作主视觉。
- 按住说话时：按钮左右两侧展示语音能量柱形条；响度来自既有 `onLevel`（0..1）+ 平滑。
- 抽出全局原子组件（如 `VoiceLevelBars`）：入参含 `level` / `accent` / `cancelled` 等；**本 change 仅轨迹接入**；首页 `HomeVoiceLevelBars` **不强制迁移**（后迁）。
- **不**设置最大语音时长；WS 仍为共用 `/voice/asr/ws`。

## Capabilities

### New Capabilities

- `voice-level-bars-atom`：可复用的语音能量柱形条原子（视觉与入参约定）。
- `growth-ask-composer-ui`：成长轨迹追问输入区自适应高度、功能色玻璃与按住能量条布局。

### Modified Capabilities

- `growth-trajectory-voice-input`：追问填框 UI MUST 符合自适应高度与玻璃/能量条布局（行为上仍松手不自动提交、共用 ASR）。

## Impact

- UI：`growth_trajectory_screen.dart`；新建 `ui/widgets/voice_level_bars.dart`（或等价路径）。
- 平滑：可复用 `VoiceLevelSmoother`。
- 首页语音球：本 change **不改**（后迁）。
- 无服务端 / 无新 WS。
