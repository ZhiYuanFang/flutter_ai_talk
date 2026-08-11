## Why

iOS VIP 支付契约已是 Apple IAP，但 `tobias`（支付宝 SDK）仍在插件元数据中声明 `ios`，CI archive 会链接 AlipaySDK，并触发 `_OBJC_CLASS_$_UTDevice` 未定义链接失败。需要让支付宝原生依赖**仅进入 Android**，从根上消除 iOS 打包阻塞，并与产品「iOS 不用支付宝」对齐。

## What Changes

- 引入 Android-only 的 `tobias` 接入方式（薄包装 / path 依赖或等价手段），使 Flutter 插件注册**不包含 iOS** `TobiasPlugin`，iOS 工程不再 CocoaPods 拉取 AlipaySDK。
- Dart 侧将 `package:tobias` 的引用收束为 Android 编译路径；iOS / Web 继续 stub，运行时不得调起支付宝。
- 清理或修正 `pubspec.yaml` 中仅服务于 iOS Alipay 回跳的 `tobias.url_scheme` / `no_utdid` 配置与 README 表述（Android 所需配置保留）。
- **非 BREAKING** 用户可见支付路径：iOS 仍 IAP，Android 仍支付宝。

## Capabilities

### New Capabilities

- `tobias-android-only`: 约束支付宝 Flutter 插件与原生 SDK 仅在 Android 链接与注册；iOS 构建不得依赖 AlipaySDK / UTDID。

### Modified Capabilities

- `vip-purchase-ux`: 在既有「渠道按平台」需求上，补充 iOS **不得** 将支付宝 SDK 编入 Runner 的工程约束（行为不变，工程边界收紧）。

## Impact

- 依赖：`app/pubspec.yaml` 的 `tobias` 指向；可能新增 `packages/` 或 `dependency_overrides` / path 包。
- 代码：`app/lib/services/vip_alipay*.dart` 条件导出；插件 registrant / Pods 生成物随 `flutter pub get` 变化。
- CI：`.github/workflows/ios-build-core.yml` 预期不再因 UTDevice 失败；Android Release 仍须验证支付宝调起。
- 文档：`app/README.md` VIP 联调说明中 iOS 支付宝回跳相关表述调整。
