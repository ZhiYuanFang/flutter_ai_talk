## Why

用户点击「永久开通」时可能误以为付款包含小智音箱实体。页面虽有自购说明，但不足以在付款瞬间形成可拒绝的知情确认；需在调起支付前二次提示：须自行购机，本次付款不含硬件。

## What Changes

- 所有进入小智 MCP 永久开通支付的入口，在建单/调起支付前 **必须** 弹出玻璃确认（可取消）。
- 确认文案明确：使用本功能前须自行购买小智音箱；本次付款不包含音箱实体。
- 用户取消则 **不得** 进入支付流程；确认后走既有 `XiaozhiMcpPaymentService.purchase` 路径。
- 不改动建单 API、SKU、划线价展示与页面静态自购说明（静态说明保留作教育）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `xiaozhi-speaker-unlock`: 在永久开通支付前增加「硬件自购 / 付款不含实体」二次确认要求（能力定义见未归档变更 `xiaozhi-speaker-app-binding`，本变更为其行为增量）。

## Impact

- **代码**：`app/lib/ui/xiaozhi_speaker_screen.dart`（建议在 `_purchasePermanent` 入口统一确认，覆盖主 CTA 与「体验已用完」引导开通路径）。
- **依赖**：复用既有 `showGlassConfirmDialog`；无新 API / 无 Android 原生改动。
- **关联变更**：依赖小智音箱管理页与永久开通 CTA 已存在（`xiaozhi-speaker-app-binding`）。
