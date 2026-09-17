## Why

桌面 large 小组件在 Android / iOS 上点「跳过」后，`recentLast` 常从约 6 条塌成约 3 条（第二行消失）。根因是后台 `applyWidgetHeroSkipAndRefresh` 仍用喂养分页磁盘 `HomeHistoryStore` 整包重算预测，而前台 sync 已与 7 日 range∪回忆间隔对齐——浅历史可预测根变少，native 按 payload 长度画格，两端共用同一 Dart 回调故一起坏。

## What Changes

- 前台成功 sync 时 **必须** 持久化一份可供后台读取的「预测结果快照」（有序可重建 hero + `recentLast` 的预测行，深度覆盖 large 预算 6）。
- 桌面「跳过」后台路径 **必须** 基于该快照（叠加 skip store）重建 payload，**不得**再以 `HomeHistoryStore` 分页作为主路径整包 `predictAllUpcoming`。
- large 在跳过后 **必须** 在候选充足时保持与跳过前同级的 `recentLast` 槽位数（最多 6），不得因浅历史重算塌成约 3。
- Android / iOS 继续共用同一 Dart interactivity 回调；本变更以 Flutter 共享逻辑为主，**不**要求为修此 bug 分端改 native 布局裁切规则。
- 快照缺失时的降级策略在 design 明确（优先用上一份 widget payload 晋升；禁止静默退回仅分页重算作为默认成功路径）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `widget-hero-skip`：后台跳过重建 MUST 使用前台 sync 写出的预测结果快照；MUST NOT 默认用喂养分页磁盘整包重算；large 跳过后槽位深度 MUST 与跳过前同源快照一致（在候选充足时）。
- `home-feed-upcoming-widget`：前台 widget sync 成功写出 payload 时 MUST 同步持久化可供后台 skip 使用的预测结果快照。

## Impact

- **Flutter**：`widget_interactivity.dart`（`applyWidgetHeroSkipAndRefresh`）、`home_widget_sync.dart` / `buildHomeWidgetPayload` 或邻近新模块（快照读写）、既有 `WidgetHeroSkipStore` / `pushHomeWidgetPayload`。
- **存储**：SharedPreferences 与/或 `HomeWidget` App Group 可读键（后台 isolate 可访问）；须与 `setAppGroupId` 后的交互回调兼容。
- **Android / iOS native**：布局与 `maxSlots`/`prefix(6)` 不变；两端验收大布局跳过槽位。若未改 `app/android/**`，不强制本 change 的 release APK；若触及原生则按 project.md 验证。
- **测试**：不新建 `**/test/**`；手工验收 Android + iOS large 跳过仍约 6 格、hero 晋升、medium 仍最多 3。
