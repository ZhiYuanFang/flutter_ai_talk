## Context

- VIP：`VipPaymentService` 已按平台分流（iOS → StoreKit / `apple_iap`；Android → `alipay` + status 有界轮询）。
- Dart：`vip_alipay.dart` 用 `dart.library.io` 选择实现；`vip_alipay_io.dart` 虽有 `Platform.isAndroid` 门闩，但仍 `import package:tobias`，且 **无法阻止** Flutter 按插件元数据在 iOS 注册原生插件。
- 根因：上游 `tobias` 的 `plugin.platforms` 含 `ios` → `pod install` 拉入 AlipaySDK；`no_utdid: true` 在「工程无第二份 UTDID」时反而可能造成 `UTDevice` undefined。
- 约束：不新建 `**/test/**`；Android 改原生依赖后须 `flutter build apk --release`；iOS 以 CI archive / `flutter build ipa` 验证链接。

## Goals / Non-Goals

**Goals:**

- iOS Runner / archive **不得** 链接 AlipaySDK、不得注册 `TobiasPlugin`。
- Android 支付宝调起与 ProGuard keep 行为保持可用。
- Dart 业务 API（`payWithAlipay` / `isAlipayInstalled`）在非 Android 上继续安全失败 / stub。

**Non-Goals:**

- 不改变服务端建单渠道契约，不引入 iOS 支付宝支付。
- 不解决「关 `no_utdid` 用 Standard SDK」的临时止痛方案（本变更用平台剔除取代）。
- 不改造鸿蒙 / ohos 路径（若包装包未声明 ohos，与当前 app 一致即可）。

## Decisions

### D1：Android-only 插件元数据（核心）

- **选择**：仓库内 path 包（建议 `packages/tobias_android`）依赖或再导出上游 `tobias`，但自身 `flutter.plugin.platforms` **仅声明 android**（不声明 ios）。
- **备选曾考虑**：
  - 仅改 Dart 条件导入 → **否决**（不改变原生注册）。
  - 去掉 `no_utdid` 保留 iOS Alipay → **否决**（与产品「iOS 不用支付宝」不符，仍留死代码与审查噪音）。
  - git fork 整仓 tobias → 可维护性更差；path 包装优先。
- **实现要点**：主 app `dependencies` 指向 path 包；包名对外仍可 `import 'package:tobias/...'`（若 path 包 `name: tobias` 并 `dependency_overrides` / 或 app 改 import 到包装名——优先 **保持 import 路径不变**：path 包 `name: tobias` 覆盖 pub.dev，内部 `publish_to: none`，android 实现委托官方源码或依赖官方 android 实现）。

更稳妥的薄包装形态（推荐落地）：

```
packages/tobias_android/
  pubspec.yaml   # name: tobias; platforms: android only; 依赖无法直接「只取 android」时改为 vendoring 官方 android 目录或 git path
```

若 pub 无法对同一 package 做「只裁平台」，则：

1. path 包 `name: tobias`，从上游拷贝/ submodule **android + lib + 必要文件**，删除 `ios/` 与 platforms.ios；或  
2. path 包新名 `tobias_android`，app 仅 Android 编译单元 import 之（条件导出）。

**默认采用 2（新名 + 条件导出）**，避免与 pub 缓存 `tobias` 混淆，且明确语义：

- `vip_alipay.dart`：`stub` | `android` 实现（`dart.library.io` + 文件拆分：`vip_alipay_android.dart` import `package:tobias_android/...` 或继续 `tobias`）。
- iOS 编译图不出现 `package:tobias*` 的 plugin registrant 条目。

### D2：条件导出形状

```
vip_alipay.dart
  → stub（默认 / web）
  → if (dart.library.io) vip_alipay_io.dart

vip_alipay_io.dart
  → 仅用 dart:io Platform 分支调用
  → Android：import 含 tobias 的实现文件（独立 part/库）
  → 非 Android：不引用 tobias（拆成 vip_alipay_android.dart，由 io 用条件 import）
```

Dart 无 `dart.library.android`。可靠做法：

- `vip_alipay_io.dart` 用  
  `import 'vip_alipay_stub_impl.dart' if (dart.library.io) 'vip_alipay_mobile.dart'`  
  不够；应：

```
// vip_alipay_mobile.dart — 仍会被 iOS 编译
```

**正确模式**：依赖「插件未声明 ios」——即使 Dart 在 iOS 上 import 了 tobias Dart API，**只要插件 platforms 无 ios，就不会编 AlipaySDK**。仍建议 iOS 不 import，减少无用依赖与 tree 噪音：

- `vip_alipay.dart`：  
  `export stub if (dart.library.html)` / 默认 stub；  
  对 IO：导出 `vip_alipay_io.dart`，其中 **动态** `Platform.isAndroid` 再 `call`；tobias import **仅**放在 `vip_alipay_android.dart`，并由  

  ```dart
  import 'vip_alipay_noop.dart'
    if (dart.library.io) 'vip_alipay_android_gate.dart';
  ```

  实际上 Flutter 条件导入不能按 OS。因此：

  **硬约束放在插件 platforms**；Dart 侧尽量：Android gate 文件可被 iOS 编译，但 path 包无 ios 原生代码即可满足链接目标。若 path 包仍含纯 Dart `Tobias()`，iOS 可编译 Dart、无原生 → method channel 无实现，故 **不得**在 iOS 调用；现有 `Platform.isAndroid` 已保证。

### D3：配置与文档

- 移除或注释 app 级 `tobias.url_scheme` / `no_utdid`（若包装包不再跑 iOS podspec）；Android Manifest / 文档按官方保留。
- README：写明 iOS 无支付宝 SDK；CI 失败勿再靠 `no_utdid`。

### D4：验证

- iOS：`flutter build ipa` / 现有 workflow；确认 Podfile.lock / GeneratedPluginRegistrant **无 tobias**。
- Android：`flutter build apk --release`（触及支付宝依赖时强制）。

## Risks / Trade-offs

- [Risk] path 包装与上游 tobias 版本漂移 → Mitigation：在包装 `pubspec` / README 钉死上游版本号，升级单独 PR。
- [Risk] 误用 `name: tobias` 覆盖导致依赖解析怪异 → Mitigation：优先新包名 + app 改一处 import。
- [Risk] 某工具仍扫描 Alipay 符号 → Mitigation：以 registrant / Pods 清单验收「无 tobias」为准。
- [Trade-off] 维护薄包装 vs 临时关 `no_utdid`：多一点工程债，换干净 iOS 链接图。

## Migration Plan

1. 落地 path 包与 pubspec 依赖切换 → `flutter pub get`。
2. 调整 `vip_alipay*` 导出。
3. 本机/CI 清 `ios/Pods` 后重装，确认无 Alipay。
4. 回滚：恢复 `tobias: ^5.3.4` 与原导出（不推荐，会带回 UTDevice 风险）。

## Open Questions

- 无阻塞项。包装包放 `packages/tobias_android` 还是 `app/packages/`：默认仓库根 `packages/tobias_android`。
