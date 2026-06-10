# Tasks: hide-ucg-treasure-entry

- [x] 1.1 新增 `ucg_feature_flags.dart`，定义 `kUcgTreasureEnabled = false`
- [x] 1.2 `UcgBottomDock`：flag 为 false 时隐藏「宝藏」槽位
- [x] 1.3 `UcgShell`：flag 为 false 时精简 `IndexedStack` 与 `_stackIndex` 映射
- [x] 1.4 `UcgProfileShell`：flag 为 false 时去掉 TabBar，直接展示动态 Tab
- [x] 1.5 手工验证：底栏四栏、我的/他人资料页仅动态、发布/消息/我的行为不变
- [x] 1.6 修复宝藏隐藏后资料页动态列表遮挡关注按钮：保留单 Tab `TabBarView` 作 NestedScrollView body
- [x] 1.7 宝藏隐藏时以 pinned 间隙 sliver（48px）替代 TabBar，恢复资料头与动态列表间距
- [x] 1.8 修复 pinned gap 导致 `layoutExtent exceeds paintExtent`：改为增大资料头 expandedHeight +48px
- [x] 1.9 宝藏隐藏时移除资料头 +48px 补偿，资料卡片与动态列表紧贴无占位空白
- [x] 1.10 宝藏隐藏时 `NestedScrollView.body` 直挂 `postsTab`（去掉单 Tab `TabBarView`），消除 TabBar 槽位占位、使动态列表上移
- [x] 1.11 修复他人主页动态遮挡关注按钮：宝藏关闭时 `floatHeaderSlivers: false`；访客含操作行时按资料卡内容高度计算 `expandedHeight`（非 TabBar +48 补偿）
