## 1. Android 后台接线

- [x] 1.1 在 `AndroidManifest.xml` 注册 `HomeWidgetBackgroundReceiver`（BACKGROUND action）与 `HomeWidgetBackgroundService`（BIND_JOB_SERVICE）
- [x] 1.2 复核 `proguard-rules.pro` 对 BackgroundReceiver/Service 的 keep；`flutter build apk --release` 通过
- [x] 1.3 若重装后点跳过仍打开 App：从 `attachLaunchClick` 去掉会抢占的 hero 父级目标，保留 skip 独立 PendingIntent

## 2. iOS 同类缺口核对

- [x] 2.1 确认 `WidgetBackgroundIntent` 在 Runner + PangbaoWidget 双 target；`ForegroundContinuableIntent` 与 AppDelegate `setPluginRegistrantCallback` 仍在
- [x] 2.2 确认 Extension 能 `import home_widget`（CI ruby / SPM `FlutterGeneratedPluginSwiftPackage` 或等价）；缺口则补脚本或 README 步骤
- [x] 2.3 在 `PangbaoWidget/README.md` 或 design 验收段注明：交互依赖上述前置，避免日后删掉 Manifest/Intent 注册

## 3. 手工验收

- [ ] 3.1 Android：完整重装 → 冷启 App 一次 → 点「跳过」hero 切换；log 见 `interactivity skip`（非仅打开 App）
- [ ] 3.2 iOS 17+（若有设备）：点「跳过」同样刷新；App 杀进程后再试一次
