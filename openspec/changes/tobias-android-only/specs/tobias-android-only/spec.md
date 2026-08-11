## ADDED Requirements

### Requirement: Tobias plugin SHALL register on Android only

The app dependency graph MUST arrange the Alipay Flutter plugin so that Flutter plugin tooling registers `TobiasPlugin` on Android and MUST NOT register an iOS Tobias/Alipay plugin target. iOS archive and device builds MUST NOT link AlipaySDK or require `UTDevice` / UTDID from Alipay.

应用依赖图 **必须** 使支付宝 Flutter 插件仅在 Android 注册；iOS **不得** 注册 Tobias/Alipay 插件目标，**不得** 链接 AlipaySDK，也 **不得** 因支付宝侧 UTDID 缺少 `UTDevice` 而链接失败。

#### Scenario: iOS 生成插件清单不含 tobias

- **WHEN** 在完成依赖切换后执行 `flutter pub get` 并生成 iOS 插件注册信息
- **THEN** `GeneratedPluginRegistrant`（或等价 registrant）MUST NOT 包含 Tobias/tobias 的 iOS 注册
- **AND** CocoaPods / SPM 依赖树 MUST NOT 拉入 AlipaySDK（Standard 或 NoUtdid）

#### Scenario: Android 仍可调起支付宝

- **WHEN** Android 用户在 VIP 购买页走支付宝渠道且服务端返回有效 `alipayOrderStr`
- **THEN** 客户端 MUST 仍能通过插件调起支付宝 SDK（行为与变更前 Android 路径一致）

### Requirement: Non-Android Dart callers SHALL NOT invoke Alipay SDK

On iOS and Web, Dart entrypoints that wrap Alipay MUST stub or refuse payment and MUST NOT require a native Alipay channel implementation to be present.

在 iOS 与 Web 上，封装支付宝的 Dart 入口 **必须** stub 或拒绝支付，且 **不得** 依赖原生支付宝通道已安装。

#### Scenario: iOS 误调用支付封装

- **WHEN** iOS 运行时调用 `payWithAlipay` / `isAlipayInstalled`（非购买主路径）
- **THEN** MUST NOT 崩溃于缺失插件
- **AND** `isAlipayInstalled` MUST 视为 false 或等价否定；支付 MUST 以错误/不支持结束
