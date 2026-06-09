## 1. 后端 go_ai_talk（跨仓库）

- [x] 1.1 `entity.History` 增加 `PostId`、`MediaType`、`ImageKeys`、`VideoKey` 字段及 DB 迁移（列 **NULL** 可空，无媒体时为 NULL 非占位零值）
- [x] 1.2 历史 list / latest / WS push 序列化输出新媒体字段（`history-event-media-api`）
- [x] 1.3 `DeviceHistoryEventUpdateReq` 接受可选 `postId` 并持久化（含清零）
- [x] 1.4 确认 gateway 已暴露 `PUT /ucg/app/api/posts/{id}` → `UcgAppCtrl.PostUpdate`（无变更则勾选验证）

## 2. Flutter 数据层

- [x] 2.1 `history_mapper.dart` / `HistoryRecord.rawPayload` 解析 `postId`、`imageKeys`、`videoKey`、`mediaType`
- [x] 2.2 新增 `EventSquareSyncPreferenceStore`（per historyId，默认 true）
- [x] 2.3 新增 `EventMediaLocalStore`（documents 复制、映射读写、全量清理）
- [x] 2.4 `RemoteFeedRepository` / history update 请求携带可选 `postId` 与媒体元数据占位
- [x] 2.5 抽取 `HistoryEditMediaItem` 模型与远程/本地合并加载逻辑

## 3. 历史编辑 UI

- [x] 3.1 新建 `HistoryEventMediaStrip` 横向条带（缩略图、右上角删除、拖拽排序，复用 `UcgComposeImageGrid` 排序逻辑）
- [x] 3.2 `home_history_edit_sheet.dart` 备注右侧「+」接入 `showUcgComposeEntrySheet` / `UcgAlbumPickerScreen`
- [x] 3.3 实现 9 图 / 1 视频互斥与 pending 只读禁用
- [x] 3.4 保存栏：「同步广场」Switch + 下方小字标签（紧凑间距），位于保存按钮左侧；底栏左「删除」、右「保存」，顶栏 × 仅关闭
- [x] 3.5 保存流程：校验 → history update → 同步 ON/OFF/删帖分支（`history-event-square-sync`）

## 4. UCG 同步与编辑

- [x] 4.1 `UcgRepository.updatePost` 实现（`PUT /posts/{id}`，镜像 `createPost` body）
- [x] 4.2 保存时 sync ON：`ucg_media_compress` + presign/upload + `createPost`/`updatePost`，remark 作 caption
- [x] 4.3 sync ON 且 `sub=0`：Toast 提示，跳过 UCG API（不以 unionid 拦截）
- [x] 4.4 曾同步后 sync OFF：`deletePost` 并清除 `postId`
- [x] 4.5 `UcgComposeScreen` 编辑模式（`editPostId`、标题「更新」、预填媒体）
- [x] 4.6 `UcgMomentsActionMenu` + `ucg_post_detail_screen.dart` 作者「编辑」入口（删除左侧）

## 5. 设置与本地缓存

- [x] 5.1 sync OFF 保存：复制媒体至 `documents/history_media/{historyId}/` 并更新映射
- [x] 5.2 `settings_screen.dart` 增加「清除历史媒体缓存」+ 确认对话框
- [x] 5.3 清理实现：删 `history_media/` 文件 + 清空 `EventMediaLocalStore`（**不**调用 `feedRepository.clearCache()`）

## 6. 联调与验收

- [ ] 6.1 手工：全部 eventNumber 类型添加图片/视频、拖拽、删除（含 sync OFF 删图后保存，已修 persistLocalMedia 先删后拷问题）
- [ ] 6.2 手工：sync ON 发帖 → 再编辑 update → 关 sync 删帖
- [ ] 6.3 手工：sync OFF 本地保存 → 重开编辑 → 设置清理后媒体消失
- [ ] 6.4 手工：UCG 详情「更新」编辑帖子
- [ ] 6.5 跨仓库：go_ai_talk list 返回字段与 Flutter 回显一致
