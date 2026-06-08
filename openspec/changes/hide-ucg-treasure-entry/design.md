# Design: 临时隐藏 UCG 宝藏入口

## Decision: 编译期 feature flag

新增 `app/lib/ucg/data/ucg_feature_flags.dart`：

```dart
const kUcgTreasureEnabled = false; // vNext: 宝藏上线时改回 true
```

与现有 `kUcgPageSize` 等常量风格一致；单版本周期内无需远程配置。

## 底部导航

- `UcgBottomDock`：`kUcgTreasureEnabled == false` 时不渲染「宝藏」`_DockItem`，底栏为 4 等分槽位
- 内部 tab 索引保持不变：0 广场、2 发布、3 消息、4 我的（index 1 无 UI 入口）
- `UcgShell`：`IndexedStack` 在 flag 为 false 时仅含广场/消息/我的三页；`_stackIndex` 单独映射

## 资料页

- `UcgProfileShell`：flag 为 false 时不展示 `TabBar`；资料头 `expandedHeight` 增加 48px（原 TabBar 高度），`body` 为单 Tab `TabBarView`（仅动态）。不使用额外 pinned gap sliver（会与 `floatHeaderSlivers` 触发 SliverGeometry 异常）
- 主人态与 `UcgUserProfileScreen` 访客态共用同一 flag，行为一致
- `UcgProfileTreasureTab`、`UcgTreasurePlaceholder` 保留，flag 为 true 时复用

## 恢复路径（下版）

1. `kUcgTreasureEnabled = true`
2. 验证底栏五栏与资料双 Tab
3. 更新 OpenSpec delta（若宝藏有真实内容则另开 change）
