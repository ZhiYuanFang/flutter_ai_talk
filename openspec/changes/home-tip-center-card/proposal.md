## Why

首页小贴士当前贴在历史区顶部、半透明、streaming 即显，右上 ✕ 关闭且整卡进陪伴，打断感弱、入口不清晰。产品改为**屏幕居中的不透明卡片**：有思考/答案内容即展示，弹性放大入场；下方「关闭 / 对话」明确分流，且不挡住历史区操作。

## What Changes

- **BREAKING（相对进行中 tip UI）**：小贴士从历史区顶条改为**主页可视区居中**叠层；卡片背景**不透明**（去掉 alpha 透出）。
- **BREAKING**：删除右上角关闭图标与整卡点击进陪伴；在卡片**正下方**展示「关闭」「对话」按钮。
- 展示条件：`thinking` 或 `answer` **任一非空**即展示（含 streaming 思考阶段）；无内容保持隐藏。
- 首次从「无可展示 → 有内容」时播放**从小变大弹性展开**；同一会话内容增量不再重复播入场。
- **关闭**：thinking / streaming / done 均可点「关闭」dismiss。
- **对话**：仅 `done` 且可注入时启用，进入陪伴页（沿用既有 tip 注入）；streaming 禁用。
- 居中后**无模态遮罩**，历史区与其它控件仍可点。
- 展示中再次按钮添加成功并触发新 tip：`startStreaming` **直接换内容**并**再播一次**入场弹性动画。
- Markdown done 态仍经 `ClinicAnswerBody`（含 `##`）。

## Capabilities

### New Capabilities

- `home-tip-center-presentation`：居中不透明卡片、出现条件（有思考/答案）、弹性入场、下方关闭/对话、无遮罩、替换再弹。

### Modified Capabilities

- `home-tip-companion-bridge`：进陪伴入口由「整卡点击」改为下方「对话」按钮；streaming 不得经对话进入；横滑进陪伴带 tip 规则保留。

## Impact

- 代码：`home_tip_panel.dart`（布局/动效/按钮）、`home_screen.dart`（Stack 挂载从顶条改为居中）、`tip_models.dart` / `tip_provider.dart`（`shouldShow`、dismiss 放宽、可选 presentation generation 供再弹）。
- 规格：与 `smart-companion-home-layer` / `sync-feed-add-remove-outbox` 中 tip 展示语义衔接；不改 tip SSE 触发（仍本机 HTTP add 成功）。
- 无 Android 原生 / 无新 Debug tag 预期。
