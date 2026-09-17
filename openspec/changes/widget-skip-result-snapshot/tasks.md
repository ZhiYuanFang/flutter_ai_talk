## 1. 预测结果快照读写

- [x] 1.1 新增快照模型与常量键（如 `widgetPredictionSnapshot`），字段足以重建 hero / `recentLast`（`eventId`、`nextAt`、`lastAt`、展示名/色等）
- [x] 1.2 实现后台 isolate 可读的 save / load / clear（SharedPreferences 与/或 `HomeWidget` App Group，与 `setAppGroupId` 后回调兼容）
- [x] 1.3 失败路径经 `AppDebugLog.homeWidget` 记录 `err=`，禁止静默吞错

## 2. 前台 sync 写出与登出清理

- [x] 2.1 在 `buildHomeWidgetPayload` 持有完整 `predictions` 处或紧随成功 `pushHomeWidgetPayload` 的前台 sync 路径写入快照（至少覆盖 large：hero + 6）
- [x] 2.2 登出 / empty payload 路径清除或覆盖为空快照，避免串用户

## 3. 后台跳过改走快照

- [x] 3.1 改写 `applyWidgetHeroSkipAndRefresh`：有快照时用快照 + `WidgetHeroSkipStore` 重建 payload（`recentLast` count=6；仅 hero 排除 skip）
- [x] 3.2 移除默认成功路径上的 `HomeHistoryStore` + 裸 `predictAllUpcoming`
- [x] 3.3 快照缺失降级：优先上一份 ready payload 晋升 hero；打降级日志；不得把浅分页整包重算当首选成功路径
- [x] 3.4 保留 visual/header 从上一 payload 回填；enrich 可用磁盘 catalog

## 4. 静态检查与双端手工验收

- [x] 4.1 `flutter analyze` 覆盖改动的 `app/lib/home_widget/**`（及新增快照文件）通过
- [ ] 4.2 Android：large 跳过前约 6 格 → 跳过后仍约 6（第二行仍在）；hero 换下一条；`recentLast` 仍可含已 skip
- [ ] 4.3 iOS：同上 large 跳过验收（共用 Dart，须实机/模拟器确认）
- [ ] 4.4 medium 仍最多 3、无「跳过」控件行为不回归
- [x] 4.5 本 change 默认不改 `app/android/**`；若实现中触及原生，须补 `flutter build apk --release` 与必要时 `proguard-rules.pro`
