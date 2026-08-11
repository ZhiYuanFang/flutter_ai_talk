## ADDED Requirements

### Requirement: iOS VIP build MUST NOT embed Alipay SDK

Beyond routing purchase to Apple IAP at runtime, the iOS application binary produced for distribution MUST NOT embed Alipay native SDK artifacts introduced via the Tobias plugin. Payment UX on iOS MUST continue to use `apple_iap` only.

除运行时走 Apple IAP 外，用于分发的 iOS 应用二进制 **不得** 因 Tobias 插件嵌入支付宝原生 SDK；iOS 购买 UX **必须** 仅使用 `apple_iap`。

#### Scenario: iOS archive 无 Alipay 链接依赖

- **WHEN** CI 或本地对 Runner 执行 release/archive（如 `flutter build ipa`）
- **THEN** 链接步骤 MUST NOT 因 `_OBJC_CLASS_$_UTDevice` 或 AlipaySDK 缺失/冲突而失败
- **AND** 购买页文案与流程 MUST 仍导向 Apple 内购而非支付宝
