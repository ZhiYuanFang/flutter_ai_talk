# Tasks: hide-ucg-treasure-entry

- [x] 1.1 新增 `ucg_feature_flags.dart`，定义 `kUcgTreasureEnabled = false`
- [x] 1.2 `UcgBottomDock`：flag 为 false 时隐藏「宝藏」槽位
- [x] 1.3 `UcgShell`：flag 为 false 时精简 `IndexedStack` 与 `_stackIndex` 映射
- [x] 1.4 `UcgProfileShell`：flag 为 false 时去掉 TabBar，直接展示动态 Tab
- [x] 1.5 手工验证：底栏四栏、我的/他人资料页仅动态、发布/消息/我的行为不变
- [x] 1.6 修复宝藏隐藏后资料页动态列表遮挡关注按钮：保留单 Tab `TabBarView` 作 NestedScrollView body
- [x] 1.7 宝藏隐藏时以 pinned 间隙 sliver（48px）替代 TabBar，恢复资料头与动态列表间距
- [x] 1.8 修复 pinned gap 导致 `layoutExtent exceeds paintExtent`：改为增大资料头 expandedHeight +48px
