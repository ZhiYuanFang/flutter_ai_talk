## 1. Flutter 品牌常量与遮罩

- [x] 1.1 `startup_branding.dart`：渐变三色 + `kStartupTaglineColor`（固定蓝）
- [x] 1.2 `StartupBrandingOverlay`：`DecoratedBox` 渐变 + 蓝色标语
- [x] 1.3 `SplashScreen` 占位页背景与遮罩一致

## 2. Android 原生衔接（可选）

- [x] 2.1 `launch_gradient.xml` + `launch_background` 底层改用渐变；`values-v31` 背景对齐

## 3. 验证

- [x] 3.1 真机冷启动：原生 → Flutter 遮罩 → 主页，无灰闪；标语为蓝色
- [x] 3.2 `dart analyze` 启动相关文件无新增告警

## 4. 事件 logo 启动预热

- [x] 4.1 `EventCatalogStore.mergeLocalLogoPaths`；`refreshAndPersist` 返回带路径的合并列表
- [x] 4.2 `EventCatalogNotifier` 后台下载完成后更新 `state`
- [x] 4.3 `EventLogoStartupWarmup.precacheCatalog` 于冷启动 catalog 后、`go(home)` 前执行（最多 6 并发）

## 5. 标语视觉修正

- [x] 5.1 移除标语下方横线：无 `TextDecoration`、收紧行高，并裁切 Logo 底缘高光避免误读为下划线
