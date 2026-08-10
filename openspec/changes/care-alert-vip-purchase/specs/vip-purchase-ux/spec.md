## ADDED Requirements

### Requirement: Purchase page SHALL show current and optional original price

The VIP purchase screen MUST display the current price derived from `priceFen`. When `originalPriceFen` is greater than zero, the screen MUST also show a strikethrough original price. When product load fails, the screen MUST show an error or retry affordance and MUST NOT start payment with a fabricated price.

购买页 **必须** 展示现价；原价大于 0 时 **必须** 划线展示；商品失败时 **不得** 用假价支付。

#### Scenario: 有划线价

- **WHEN** 商品 `originalPriceFen` 为 9900 且 `priceFen` 为 1900
- **THEN** UI MUST 展示约 ¥19.00 现价与划线 ¥99.00

#### Scenario: 无划线价

- **WHEN** `originalPriceFen` 为 0
- **THEN** UI MUST NOT 展示划线原价

### Requirement: Payment channel SHALL follow platform

On iOS the purchase flow MUST use Apple IAP (`apple_iap`). On Android the purchase flow MUST use Alipay (`alipay`). After Alipay returns to foreground, the client MUST poll VIP status with a bounded retry (single-flight, finite attempts) until VIP or timeout. Unsupported platforms MUST NOT silently charge.

iOS **必须** Apple IAP；Android **必须** 支付宝；支付宝回前台 **必须** 有界轮询 status。

#### Scenario: Android 支付后回前台开通

- **WHEN** 用户完成支付宝支付并回到 App
- **THEN** 客户端 MUST 在有限次数内轮询 status
- **AND** 当 `isVip` 为 true 时 MUST 展示成功并结束轮询

#### Scenario: iOS 购买完成

- **WHEN** StoreKit 购买成功且服务端验单成功且 status 为 VIP
- **THEN** UI MUST 视为开通成功

### Requirement: Successful activation SHALL refresh VIP state for callers

After a successful activation, the purchase flow MUST invalidate or refresh the shared VIP status so the care-alert detail CTA can hide without requiring App restart.

开通成功后 **必须** 刷新共享 VIP 状态，使详情 CTA 可隐藏。

#### Scenario: 从购买页返回详情

- **WHEN** 用户开通成功并返回留意详情
- **THEN** 详情页 MUST 不再展示「开通 VIP」CTA（以刷新后的 `isVip` 为准）
