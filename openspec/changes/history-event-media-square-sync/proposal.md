## Why

家长在编辑历史事件备注时，常常想附上照片或短视频留存瞬间，并可选同步到 UCG 广场与家人分享。当前历史编辑 Sheet 仅支持文字备注，无法附带媒体，也无法一键发布到广场；已发布的 UCG 帖子也缺少从详情页进入编辑更新的入口。需要在**全部历史事件类型**的编辑流程中统一支持多媒体与「同步广场」开关，并打通本地缓存与 UCG 发帖/更新/删除链路。

## What Changes

- **历史编辑多媒体**：在 `home_history_edit_sheet.dart` 为**所有**历史事件（非仅喂养）增加最多 9 张图片或 1 条视频；备注输入框右侧「+」唤起现有 UCG 相册选择器；媒体在备注下方以**横向条带**展示（非九宫格），支持右上角删除与拖拽排序（复用 `UcgComposeImageGrid` 排序逻辑）。
- **「同步广场」开关**：保存按钮左侧增加小号 Switch + 下方标签「同步广场」，默认开启；偏好按 history 记录 id 本地持久化（SharedPreferences，模式同 `EventRemarkMemoryStore`）。
- **同步 ON 保存**：压缩至 UCG 限制 → presign/upload → `createPost` 或 `updatePost`（有 `postId` 时）；备注作为帖子正文；身份门禁仅要求 JWT `sub≠0`（wx.id），**不**以 WeChat unionid / `isWxBound` 拦截。
- **同步 OFF 保存**：将媒体复制到应用 documents 目录，维护 eventId→本地路径映射；支持再次编辑时替换与重排。
- **曾同步后关闭同步**：保存时若记录已有 `postId` 且开关关闭，调用 `deletePost` 删除 UCG 帖子并清除关联。
- **后端契约（go_ai_talk）**：`history` 表与 list/update API 增加 `postId`、图片集与视频字段；历史 list 响应携带媒体元数据供客户端回显。
- **UCG 详情编辑**：`ucg_post_detail_screen.dart` 作者操作区在删除左侧增加「编辑」→ compose 编辑模式，AppBar 标题「更新」；客户端新增 `UcgRepository.updatePost`。
- **设置清理**：`settings_screen.dart` 增加「清除历史媒体缓存」——删除本地复制的媒体文件并清空 event→path 映射（**不**调用 `feedRepository.clearCache()`）。

## Capabilities

### New Capabilities

- `history-event-media`：历史编辑 Sheet 多媒体选择、横向条带展示、数量/类型限制与排序删除行为。
- `history-event-square-sync`：「同步广场」开关默认与持久化、保存时 UCG 发帖/更新/删帖分支及 wx.id 身份门禁。
- `event-media-local-cache`：同步关闭时的本地媒体复制、event→路径映射持久化及设置页定向清理。
- `history-event-media-api`：go_ai_talk 历史实体与 list/update API 返回 `postId` 与媒体字段的跨端契约。

### Modified Capabilities

- `home-history-edit-sheet`：在既有备注/时间/用量编辑之上集成多媒体条带与「同步广场」控件，扩展保存流程。
- `settings-center`：新增「清除历史媒体缓存」入口与确认流程。
- `ucg-compose-post`：新增 `updatePost` 客户端能力；详情页作者可进入 compose 编辑模式（标题「更新」）。

## Impact

- **Flutter（flutter_ai_talk）**
  - UI：`home_history_edit_sheet.dart`、`settings_screen.dart`、`ucg_post_detail_screen.dart`、`ucg_compose_screen.dart`、新建横向媒体条带组件
  - Data：`history_mapper.dart`、`models.dart`/`HistoryRecord`、`EventMediaLocalStore`（新）、`EventSquareSyncPreferenceStore`（新）
  - UCG：`ucg_repository.dart`（`updatePost`）、`ucg_compose_entry_sheet.dart`、`UcgAlbumPickerScreen`、`ucg_media_compress.dart`
  - Providers：`home_history_notifier.dart`、`RemoteFeedRepository`（历史 update 载荷扩展）
- **Backend（go_ai_talk）**
  - `internal/model/entity/history.go`：新增 `postId`、图片/视频字段
  - 历史 list/update 服务与 `api/v1/device_history_http.go` 响应/请求扩展
  - 已有 `internal/services/ucg/post.go` `UpdatePost` / `DELETE` 供客户端调用（无需新端点，需确认网关路由已暴露 `PUT /ucg/app/api/posts/{id}`）
- **跨仓库**：Flutter 与 go_ai_talk 须协调上线顺序——后端先扩展 history 字段，客户端再解析回显；UCG `updatePost` 可独立先行。
- **非目标**：不改变 `feed-history-sync` WebSocket 增量策略；不扩展 unionid 绑定门禁；不清除全量 feed 磁盘缓存。
