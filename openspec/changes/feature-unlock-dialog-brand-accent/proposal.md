## Why

预测槽位满额时的共享邀请码弹窗未传入 catalog 的 logo / 功能色，视觉上像通用主题弹窗，与开通中心预测卡、AI 分析 / 成长轨迹邀请弹窗不一致。同时，开通家族弹窗虽已支持 `eventAccent` 刷玻璃边与 logo，确认 `FilledButton` 仍写死 `ColorScheme.primary`，品牌色链路半截。

## What Changes

- 预测满额闸门调用 `showInviteCodeDialog` 时，从 catalog 取 `prediction_unlock` 项，传入 `logoUrl` 与 `resolveFeatureColor` 的 `eventAccent`（缺项时回退主题色）。
- 共享邀请码弹窗确认钮背景改为 `eventAccent ?? ColorScheme.primary`（前景仍 `onPrimary`，与记事 sheet 一致）。
- `showGlassConfirmDialog` 在传入 `eventAccent` 时，确认钮同样跟色（惠及开通中心「看广告」等）。
- 开通中心支付确认弹窗确认钮同样跟已解析的功能色。
- 开通中心**功能卡内**：CTA 描边按钮（字/边）与状态文案（激活徽章、已开通剩余时效）跟该行功能色；**标题与介绍**保持中性 `onShell`，不跟功能色。
- 未传 `eventAccent` 的其它玻璃确认框行为不变。

## Capabilities

### New Capabilities

- `feature-unlock-dialog-brand`：功能开通家族玻璃弹窗的 logo / 功能色与确认钮品牌对齐约定

### Modified Capabilities

- `prediction-toggle-slot-gate`：满额邀请码弹窗 MUST 带预测槽位 catalog logo 与功能色
- `invite-code-howto`：共享邀请码弹窗 MUST 消费可选 `eventAccent` / `logoUrl`，确认钮跟色
- `feature-unlock-hub`：支付/广告确认钮跟功能色；卡内 CTA 与状态文案跟功能色（标题/介绍除外）

## Impact

- 客户端：`smart_prediction_screen.dart`（满额调用点）、`feature_unlock/invite_code_dialog.dart`、`widgets/app_glass_overlay.dart`（`showGlassConfirmDialog`）、`feature_unlock_hub_screen.dart`（支付确认 + 卡内 CTA/状态色）
- 无服务端 / API / **BREAKING** 变更
- AI 分析 / 成长轨迹邀请弹窗自动受益于共享组件按钮跟色
