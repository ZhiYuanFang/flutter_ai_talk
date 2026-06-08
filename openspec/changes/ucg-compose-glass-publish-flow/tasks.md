## 1. 依赖与平台配置（Flutter only，无 go_ai_talk）

- [x] 1.1 `pubspec.yaml` 添加 `photo_manager`、`permission_handler`
- [x] 1.2 iOS `Info.plist` 添加 `NSPhotoLibraryUsageDescription`（若缺失）— 仓库无 iOS Runner 目录，待原生工程补齐时添加
- [x] 1.3 Android `AndroidManifest.xml` 添加相册读取权限（API 33+ `READ_MEDIA_*` 或兼容声明）— 已存在
- [x] 1.4 新建 `ucg_album_permission.dart`：请求/拒绝/永久拒绝处理与 toast

## 2. 自建相册页（ucg-album-picker）

- [x] 2.1 新建 `UcgAlbumSelectionController`：idle / photoMode / videoMode 互斥状态机
- [x] 2.2 新建 `UcgAlbumPickerScreen`：全屏、玻璃顶栏（取消 | 计数 | 完成 primary 胶囊）
- [x] 2.3 `photo_manager` 加载 Recent 相册、3 列网格、分页 80 条 + 缩略图 200px
- [x] 2.4 视频格时长角标；disabled 格遮罩与 `IgnorePointer`
- [x] 2.5 「完成」：读 asset bytes → 现有 compress/upload → 返回 `UcgComposeInitialMedia`
- [x] 2.6 Web 降级：`pickMultipleMedia` + 混选 toast 拒绝（`kIsWeb` 分支）

## 3. 玻璃入口 sheet（ucg-shell-navigation）

- [x] 3.1 `showUcgComposeEntrySheet` 改用 `showGlassAdaptiveBottomSheet`
- [x] 3.2 `showUcgCameraCaptureSheet` 改用玻璃 sheet
- [x] 3.3 「从手机相册选择」改为 push `UcgAlbumPickerScreen`；删除图片/视频二次 sheet
- [x] 3.4 `ucg_shell.dart` 联调：相册返回 → compose 预填不变

## 4. 发布页玻璃 UI（ucg-compose-post）

- [x] 4.1 移除 `UcgImmersiveHeader` title/subtitle；顶栏改为「取消 | 发表」同排
- [x] 4.2 发表按钮 `FilledButton` + `StadiumBorder` + `ColorScheme.primary`
- [x] 4.3 正文 + 九宫格 + AI润笔 包入单块浅色玻璃 panel（`UcgComposeLightGlassPanel`，`eventAccent: primary`）
- [x] 4.4 正文 placeholder 改为「这一刻的想法…」；保留 `ManagedKeyboardTextField` scene
- [x] 4.5 `UcgComposeImageGrid`：图片 cell 12–14px 圆角 + 玻璃轻描边；「+」格 glass tap 风格
- [x] 4.6 退出三选 dialog 改用 glass dialog（保存草稿 / 放弃 / 取消）
- [x] 4.7 可选：shell 背景极浅 primary 渐变
- [x] 4.8 发布流浅色玻璃：入口 sheet / 退出 dialog / 九宫格「+」格与描边改用 `UcgComposeLightGlassPanel` 与 `onShell` 前景色

## 5. 联调与验收

- [ ] 5.1 原生：相册互斥（先图后视频 disabled、先视频后图 disabled、9 张上限）
- [ ] 5.2 原生：玻璃入口 → 相册 → compose → 发表 / 放弃 / 存草稿
- [x] 5.3 确认广场 Feed 仍为 `UcgSurfaceCard` 简约风（无玻璃回归）— 未改 feed 组件
- [x] 5.4 Web：相册降级与混选拒绝 toast — 代码已实现
- [x] 5.5 `openspec validate ucg-compose-glass-publish-flow` 通过

**说明**：本变更 **不涉及 go_ai_talk**；后端沿用 `ucg-moments-compose-redesign` 已有 upload/delete/polish API。
