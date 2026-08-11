## Why

量身定做单卡仍要求用户选「当时是哪一种」、思考结束后需手点「继续」，且卡片无事件 logo、背景统一主题色，辨识度与节奏偏弱。需要改为只读展示子事件、思考完自动下一卡，并让单卡视觉跟事件品牌色/logo 对齐。

## What Changes

- 单卡思考打字机结束后短延迟自动进入下一根事件卡（或收尾页）；可保留「跳过动画」加速。
- 「当时是哪一种」改为「该事件包含」类只读子事件展示；**无真实子事件时整块不展示**；用户不再选择叶子。
- 回忆种子 `leafEventId` 固定为当前根事件 id（不再依赖用户选叶）。
- 事件名左侧展示 `EventLogo`。
- 浮卡背景经 `eventAccent` 使用该根事件色（`resolveEventColor`），非单一主题 primary。

## Capabilities

### New Capabilities

- `prediction-recall-card-ux`：量身定做单卡自动跳转、子事件只读、logo 与事件色背景的行为契约。

### Modified Capabilities

- （无）

## Impact

- UI：`prediction_recall_onboarding_panel.dart`（`_FloatingCard` / 思考结束 / 叶子区 / 标题行）。
- 种子写入：`leafEventId` → root；合成记录仍走既有 `PredictionRecallSeed`。
- 复用：`EventLogo`、`resolveEventColor`、`AppModalGlassPanel.eventAccent`。
