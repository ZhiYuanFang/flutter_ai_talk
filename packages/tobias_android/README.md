# tobias（Android-only 裁剪）

Vendored from [OpenFlutter/tobias](https://github.com/OpenFlutter/tobias) **5.3.4**.

- `plugin.platforms` **仅** `android`（已删除 `ios/`、`ohos/`）。
- 包名仍为 `tobias`，便于 `import 'package:tobias/tobias.dart'`。
- 升级：对照上游 changelog 同步 `android/` + `lib/`，保持 platforms 不含 ios。

胖宝 VIP：iOS 走 Apple IAP，故不在 iOS 嵌入支付宝 SDK。
