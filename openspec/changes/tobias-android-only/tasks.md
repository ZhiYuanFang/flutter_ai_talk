## 1. Android-only 插件包装

- [x] 1.1 在仓库根创建 `packages/tobias_android`（`publish_to: none`），钉死上游 tobias 版本（如 5.3.4），`plugin.platforms` **仅**声明 android
- [x] 1.2 落地包装策略：委托/vendoring 官方 android+lib，确保 `flutter pub get` 后 iOS 无 tobias 插件注册
- [x] 1.3 更新 `app/pubspec.yaml`：依赖改指 path 包；移除或收敛仅服务 iOS Alipay 的 `tobias.url_scheme` / `no_utdid` 顶层配置

## 2. Dart 封装

- [x] 2.1 调整 `vip_alipay*.dart`：Android 实现依赖新包装；iOS/Web 走 stub；保持 `Platform.isAndroid` 门闩
- [x] 2.2 确认 `VipPaymentService` / 购买页仍为 iOS→IAP、Android→支付宝，无行为回归

## 3. 文档与原生校验

- [x] 3.1 更新 `app/README.md` VIP 联调：写明 iOS 不嵌入支付宝 SDK；Android 配置保留
- [x] 3.2 核对 `app/android` Manifest / `proguard-rules.pro` 支付宝 keep 仍有效；执行 `flutter build apk --release`
- [x] 3.3 iOS：`flutter pub get` 后确认 registrant / Pods **无** tobias/AlipaySDK；CI 或本地 archive/`flutter build ipa` 不再出现 `UTDevice` undefined
