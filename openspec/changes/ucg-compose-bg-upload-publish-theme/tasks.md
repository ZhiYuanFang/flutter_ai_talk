## 1. 媒体槽与后台上传引擎（Phase B）

- [x] 1.1 新增 `UcgComposeMediaSlot`（localPath、objectKey、status、uploadFuture）及 `ensureAllUploadsDone` helper
- [x] 1.2 `UcgComposeScreen` 用 slot 列表替换 `_imageKeys`/`_videoKey` 驱动逻辑；远程编辑帖预填为 done 槽
- [x] 1.3 实现 `_startSlotUpload`：入列后 `unawaited` 后台 `ucgUploadBytes`，成功写入 key 并 `_sessionUploadedKeys`
- [x] 1.4 删除/放弃：取消进行中上传；done 槽 `deleteMedia`；`_discardSession` 清理孤儿 key
- [x] 1.5 `UcgComposeImageGrid` / `_ImageTile`：有 localPath 用 `Image.file`，远程用 `UcgNetworkImage`

## 2. 入口与相册 deferUpload（Phase B）

- [x] 2.1 `ucgPickMoreImagesForCompose`、shell 入口相册 push `UcgAlbumPickerScreen(deferUpload: true)`
- [x] 2.2 `showUcgComposeEntrySheet` 拍摄分支返回本地 path；Web 拆 pick-local + compose 后台传
- [x] 2.3 `showUcgCameraCaptureSheet` 不再选完即 upload；compose `initState` 对 initial 媒体建槽并后台传
- [x] 2.4 更新 `ucg_compose_initial_media.dart`（或等价）支持本地 path 列表

## 3. 提交、润笔、草稿等待（Phase C）

- [x] 3.1 `_publish`：先 `ensureAllUploadsDone`，发表按钮内 `_publishing` 转圈，再 `createPost`/`updatePost`
- [x] 3.2 退出 dialog「保存草稿」：按钮内 loading + await 上传 + `_persistDraft`（仅 objectKeys）
- [x] 3.3 `_polishWithAi`：有图即显；点击后按钮内 `_polishing` 先 await 上传再 `polishPost`
- [x] 3.4 收紧 `_busy` / `_showAiPolish`：不含后台 uploading；有图且无视频即显润笔

## 4. 发表后导航（Phase A）

- [x] 4.1 定义 compose pop result（如 `publishedNewPost`）；新帖成功 `pop(result)`，编辑 `pop()` 无结果
- [x] 4.2 `UcgShell._openCompose`：收到新帖结果后 `setState(() => _tabIndex = 4)`
- [x] 4.3 确认 `ucgPostsChangedProvider` bump 后「我的」动态列表首屏含新帖

## 5. 清理旧阻塞 UI（Phase D）

- [x] 5.1 移除 compose `_uploadingMedia` 选图阻塞、`addBusy`、`上传中…` 文案
- [x] 5.2 相册 defer 路径「完成」钮不因 OSS 转圈（仅本地 IO）
- [x] 5.3 确认无全屏 upload barrier 残留

## 6. 定时主题（颜色设置）

- [x] 6.1 新增 `AppThemeSchedule`（本地时区 19:00–05:00 夜空，否则基线）
- [x] 6.2 基线与展示分离：持久化仍用 `ThemePreferences`；展示态由 schedule + baseline 解析
- [x] 6.3 `PangbaoApp` 挂载 `Timer.periodic`（≥1min）+ `WidgetsBindingObserver.resumed` 刷新主题
- [x] 6.4 设置页改色仍写基线；手工验证 19:00/05:00 边界与恢复

## 7. 验证

- [x] 7.1 原生：选图秒显、后台传、新帖发表跳「我的」、编辑回详情刷新
- [x] 7.2 润笔：上传中可见；点击按钮内转圈直至润笔完成
- [x] 7.3 存草稿：等待上传后草稿含 keys；放弃清理 OSS
- [x] 7.4 Web：本地预览 + 发表等待路径可用手工验证
- [x] 7.5 `openspec validate ucg-compose-bg-upload-publish-theme` 通过
