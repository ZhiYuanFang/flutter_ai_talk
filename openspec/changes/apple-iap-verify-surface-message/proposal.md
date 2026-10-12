## Why

兄弟仓 `go_ai_talk` 已在 Apple IAP 异号复用同一 `transactionId` 时返回业务错误文案「一个 Apple 账号仅支持开通一个胖宝账号」。VIP 支付路径已透传 `ApiBusinessException.message`，但小智 MCP 与功能开通的 Apple 验单失败被 `catch` 后写死为「验单失败，请稍后重试」，用户看不到服务端真实原因。

## What Changes

- 小智 MCP Apple 验单失败时：若为 `ApiBusinessException` 且 `message` 非空，MUST 将该 `message` 作为 `VipPaymentOutcome.message`（或等价 UI 文案）展示。
- 功能开通 Apple 验单失败时：同上，对齐 VIP 行为。
- VIP 路径保持现有透传逻辑，可不改或仅做一致性核对。
- 非业务异常（超时、未知错误）仍可用通用「验单失败，请稍后重试」等 fallback。
- 失败路径 MUST 用 `AppDebugLog` 记录 `err=`，禁止 `catch (_)` 静默吞错（对齐 `project.md` Debug 约定）。

## Capabilities

### New Capabilities

- `apple-iap-verify-surface-message`：Apple 服务端验单业务错误文案在小智 MCP / 功能 / VIP 支付结果中的透传规则。

### Modified Capabilities

- `cash-vip-client`：补充「验单业务失败 MUST 展示服务端 message」场景（VIP 已基本符合，规格对齐）。

## Impact

- **代码**：`app/lib/services/xiaozhi_mcp_payment_service.dart`、`feature_payment_service.dart`；可选核对 `vip_payment_service.dart`。
- **依赖**：`ApiBusinessException`（`app/lib/api/api_exceptions.dart`）；后端文案来自 `go_ai_talk` cash-service。
- **发版**：需发 Flutter 客户端；仅 redeploy cash 不足以让用户看到新文案。
- **测试**：不新增 `*_test.dart`（项目约定）；手工换号复购验收。
