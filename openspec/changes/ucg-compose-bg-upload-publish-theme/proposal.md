## Why

UCG 发布动线当前在选图/拍摄时即阻塞上传 OSS，用户感知等待明显；发表成功后仅 `pop` 回广场，新帖不易被找到；AI 润笔在上传期间被隐藏。同时产品希望晚间自动切换「夜空」主题、清晨恢复用户在设置中保存的主题色，提升夜间使用舒适度。需在**不改变后端发帖/润笔 API** 的前提下，统一优化发布媒体管线、发表后导航、润笔交互与定时主题。

## Cross-Repo Scope

本变更为 **Flutter 客户端专属**，**不涉及 go_ai_talk 后端**：

| 仓库 | 是否变更 | 说明 |
|------|----------|------|
| **flutter_ai_talk** | ✅ 是 | compose 媒体槽、后台上传、导航、主题调度 |
| **go_ai_talk** | ❌ 否 | 沿用现有 upload/createPost/polish/delete API |

**前置依赖**：`ucg-compose-glass-publish-flow`、`ucg-moments-compose-redesign`、`history-event-media-square-sync` 中相册 `deferUpload`、玻璃发布 UI 已落地或可用。

## What Changes

### Phase A — 发表后导航

- **新帖**发表/更新成功后：`Navigator.pop` 带结果 → `UcgShell` 切换到底栏「我的」（tab index 4），并依赖既有 `ucgPostsChangedProvider` 刷新动态列表。
- **编辑帖**（从详情进入 compose）成功后：仅 `pop` 回详情/原页面，**不得**切换 Tab；详情页继续 `_refresh()`。

### Phase B — 本地先显 + 后台静默上传

- 选图/拍摄/相册完成：立刻以**本地缩略图**展示在 compose 九宫格；**不得**在选图阶段阻塞上传。
- 每条本地媒体入列后**立即在后台**启动 `ucgUploadBytes`（复用现有压缩/dedup 管线），用户无感。
- 引入 **媒体槽（slot）** 模型：本地 path + 可选 `objectKey` + 上传 `Future`/状态（pending / uploading / done / failed）。
- 相册 compose 路径使用 `UcgAlbumPickerScreen(deferUpload: true)`；入口 sheet 拍摄/Web 降级同样返回本地媒体再进 compose。
- 编辑帖中已有远程 `objectKey` 的媒体视为 `done`，仅新选媒体走后台上传。

### Phase C — 提交/润笔/草稿等待 + 按钮内转圈

- **发表/更新**：若仍有未完成上传，在**发表按钮内**转圈并 `await` 全部完成后再 `createPost`/`updatePost`。
- **保存草稿**：退出 dialog「保存草稿」按钮内转圈，等待上传完成后写入 `objectKeys` 草稿。
- **AI 润笔**：只要有图片（无视频）即显示；点击后**润笔按钮内**转圈，先 `await` 全部图片上传完成再调 `polishPost`（上传等待与润笔请求共用同一按钮 loading，不区分阶段）。
- **所有 loading 仅在按钮内转圈**：不得使用全屏遮罩、九宫格 `+` 格转圈、列表下「上传中…」文案行。

### Phase D — 清理旧阻塞 UI

- 移除 compose `_uploadingMedia` 对选图、`+` 格 `addBusy`、`_showAiPolish` 上传态隐藏的耦合。
- 相册「完成」在 deferUpload 路径下不得再因上传而转圈（仅 asset→file 的短暂 IO 可接受）。

### 定时主题（颜色设置）

- 使用设备**本地时区**：每日 **19:00** 起自动应用 `ThemePreset.nightSky`（夜空）；每日 **05:00** 起自动恢复用户在设置页保存的主题（`ThemePreferences` 中的 preset/自定义 seed）。
- 用户在设置页手动改色须更新**持久化基线**并立即生效；定时切换不得覆盖用户对基线的持久化存储，仅影响当前展示。
- App 前台/恢复时须重新评估当前应处于「定时夜空」或「用户基线」哪一套。

## Capabilities

### New Capabilities

- `app-theme-schedule`：基于本地时钟的夜空定时切换（19:00 / 05:00）与用户基线主题恢复

### Modified Capabilities

- `ucg-compose-post`：媒体槽、本地预览、后台上传、发表/草稿等待、按钮内 loading、新帖发表后导航结果
- `ucg-album-picker`：compose 路径 deferUpload 返回本地媒体，完成时不阻塞上传
- `ucg-shell-navigation`：新帖发表成功导航至「我的」；编辑帖保持原页
- `ucg-compose-ai-polish`：有图即显；点击先等待上传完成（按钮内转圈）

## Impact

**flutter_ai_talk**

| 区域 | 路径 |
|------|------|
| 媒体槽与上传编排 | 新建 `app/lib/ucg/data/ucg_compose_media_slot.dart`（或等价）；改 `ucg_compose_screen.dart` |
| 相册/入口 | `ucg_album_picker_screen.dart`、`ucg_compose_entry_sheet.dart`、`ucg_album_picker.dart` |
| 九宫格 | `ucg_compose_media_grid.dart`（本地 `Image.file` 预览） |
| 导航 | `ucg_shell.dart`、`ucg_compose_screen.dart` |
| 退出 dialog | `app_glass_overlay.dart` 或 compose 退出 dialog（保存草稿按钮 loading） |
| 定时主题 | `app_theme_scope.dart`、`theme/custom_background_persist.dart`、新建调度 helper；`app.dart` 挂载 tick |

**go_ai_talk**：无变更。
