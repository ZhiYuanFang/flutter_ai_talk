## Why

`ucg-moments-compose-redesign` 已落地微信式发布流程（入口 sheet、9 宫格、草稿三选、AI 润笔等），但发布动线视觉仍为 UCG 简约轻表面（`UcgSurfaceCard`），与产品期望的「喂养模块玻璃拟态 + 可爱风」不一致；相册仍依赖系统 picker 二次「图片/视频」分流，无法在**选择侧**实现图/视频互斥。需在**不改变后端 API** 的前提下，将发布动线（入口 sheet、自建相册、发布页、退出 dialog）统一为玻璃拟态，并补齐自建相册页。

## Cross-Repo Scope

本变更为 **Flutter 客户端专属**，**不涉及 go_ai_talk 后端**：

| 仓库 | 是否变更 | 说明 |
|------|----------|------|
| **flutter_ai_talk** | ✅ 是 | 发布动线 UI、自建相册、`photo_manager` 依赖、平台权限配置 |
| **go_ai_talk** | ❌ 否 | 沿用 `ucg-moments-compose-redesign` 已有 upload/delete/polish API，无新接口、无 DB、无 Admin |

**前置依赖**：`ucg-moments-compose-redesign` 中媒体上传、delete、compose 流程、草稿语义已实现或联调可用。

## What Changes

### 发布动线玻璃化（可爱风）

- **入口 bottom sheet**（拍摄 / 从相册选择）与 **拍摄子 sheet**（拍照 / 录像）改用 `showGlassAdaptiveBottomSheet` + `HistoryEditGlassPanel` 风格。
- **退出三选 dialog**（保存草稿 / 放弃 / 取消）改用玻璃 dialog（扩展 `showGlassDialog` 或等价三按钮实现）。
- **发布页**：
  - 顶栏改为微信式 **「取消 | 发表」** 同排，**不得**展示页面标题/副标题。
  - **发表**按钮使用 `ColorScheme.primary` 胶囊（随宝宝主题）。
  - 正文 + 9 宫格 + AI润笔 **同一块** `HistoryEditGlassPanel`（`eventAccent` = primary）。
  - 九宫格图片 cell 使用玻璃圆角（约 12–14px）与轻描边；「+」占位格使用玻璃 tap field 风格。
  - 拖拽删除区仍为底部浮层红色条（微信交互，非玻璃）。
- **广场/消息/我的** Tab 内联 UI **保持** `ucg-minimal-visual-system` 简约风（ intentional 分叉）。

### 自建玻璃相册页

- 新增全屏 **`UcgAlbumPickerScreen`**（或等价 route）：`photo_manager` 加载相册缩略图，3 列网格，分页。
- **选择侧互斥状态机**：
  - 未选：图片与视频均可点；
  - 先选图片 → photo 模式（最多 9 张，视频格 disabled）；
  - 先选视频 → video 模式（仅 1 个，图片格 disabled）。
- 「从手机相册选择」→ **直接进入自建相册页**，移除「选择图片 / 选择视频」二次 sheet。
- 完成 → 复用现有压缩/upload 管线 → 进入 compose 预填媒体。
- **Web 降级**：无 `photo_manager` 完整能力时降级 `pickMultipleMedia` + 确认后互斥校验。

### 规范修订

- **MODIFIED** `ucg-visual-system`：发布动线（入口 sheet、相册页、compose、退出 dialog）允许 `HistoryEditGlassPanel` / `BackdropFilter`；Tab 内联仍禁止玻璃。
- **MODIFIED** `ucg-minimal-visual-system` 对 compose「不得玻璃」条款 — 由本变更 supersede 于发布动线范围。

## Capabilities

### New Capabilities

- `ucg-album-picker`：自建玻璃相册页、选择侧 photo/video 互斥、完成上传返回预填媒体

### Modified Capabilities

- `ucg-compose-post`：微信顶栏、单块 glass panel、primary 发表按钮、玻璃九宫格 cell、玻璃退出 dialog
- `ucg-shell-navigation`：玻璃入口/拍摄 sheet；相册路径改为 push 自建相册页
- `ucg-visual-system`：发布动线 glass 例外条款

## Impact

**flutter_ai_talk**

- `app/lib/ucg/ui/ucg_compose_screen.dart` — 顶栏、glass panel、dialog
- `app/lib/ucg/ui/widgets/ucg_compose_entry_sheet.dart` — 玻璃 sheet、移除相册二次分流
- 新建 `app/lib/ucg/ui/ucg_album_picker_screen.dart`（及 widgets）
- 新建 `app/lib/ucg/data/ucg_album_picker.dart`（权限、asset 读取、upload 编排）
- `app/lib/ucg/ui/widgets/ucg_compose_media_grid.dart` — 玻璃圆角 cell
- 复用 `app/lib/ui/home_history_edit_glass_panel.dart`、`app/lib/ui/widgets/app_glass_overlay.dart`

**新依赖**

- `photo_manager` — 相册资产与缩略图
- `permission_handler` — iOS/Android 相册权限

**平台配置**

- iOS `Info.plist`：`NSPhotoLibraryUsageDescription`
- Android `AndroidManifest.xml`：`READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`（或兼容旧版）

**go_ai_talk**：无变更。
