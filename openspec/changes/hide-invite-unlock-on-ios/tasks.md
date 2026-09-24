## 1. 平台闸门

- [x] 1.1 在 `feature_unlock_models.dart` 为 `supportsInviteCode` 增加原生 iOS 否决：`!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS` 时恒 false；Android/Web 仍要求 `invite_code` + `inviteAvailable`
- [x] 1.2 确认开通中心 CTA 仍仅依赖 `supportsInviteCode`（无需平行改 Hub UI 硬编码平台判断）

## 2. 槽位邀码残留清理

- [x] 2.1 删除 `smart_prediction_screen.dart` 中对 `feature_unlock/invite_code_dialog.dart` 的无用 import
- [x] 2.2 确认预测页无「预测槽位已满」邀码调用路径

## 3. 验收

- [x] 3.1 对照本 change specs：原生 iOS 即使 catalog 允许也不显示邀请开通；Android/Web 在 catalog 允许时显示
- [x] 3.2 手工或说明：免费体验 / 支付 / 广场发码不受影响
