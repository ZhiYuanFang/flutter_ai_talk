## 1. Dart：skip 存储与过滤

- [x] 1.1 新增 hero skip prefs（eventId → baselineLastAt）、add/peek/clear/登出清理 API
- [x] 1.2 sync 构建 payload：仅 hero 排除仍 skip 的 id，recentLast 保留；有更新 lastAt 时解除对应 skip
- [x] 1.3 注册 `HomeWidget.registerInteractivityCallback`：解析 skip URI、写入 skip、重建并 `updateWidget`；后台启动短路完整冷启

## 2. Android 原生

- [x] 2.1 small/large layout：hero 行右侧「跳过」控件；medium 不加
- [x] 2.2 Renderer：跳过独立 Background PendingIntent（带 eventId）；其余区域仍 launch；点跳过不打开 App
- [x] 2.3 `flutter build apk --release` 通过；若 R8 Missing class 则更新 `proguard-rules.pro`

## 3. iOS 原生

- [x] 3.1 Runner + WidgetExtension 共享 AppIntent，调用 `HomeWidgetBackgroundWorker`（含 ForegroundContinuableIntent 如需）
- [x] 3.2 small/large：在可用系统版本上为 hero 加「跳过」Button；旧系统省略按钮、保留整卡打开

## 4. 手工验收

- [ ] 4.1 Android：跳过 A 后 hero=B，后续留意仍可见 A；再记 A 后可回潮 hero
- [ ] 4.2 iOS（支持交互版本）：同上；App 前台/后台/杀进程各验一次
- [ ] 4.3 连续跳过至无预测：展示 empty/noPrediction 合理；登出后 skip 清空
