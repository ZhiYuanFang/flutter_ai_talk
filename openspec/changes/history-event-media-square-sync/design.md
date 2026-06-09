## Context

历史编辑 Sheet（`home_history_edit_sheet.dart`）当前支持按 `eventNumber` 编辑时间、用量与备注，无多媒体能力。UCG 模块已具备相册选择（`showUcgComposeEntrySheet` → `UcgAlbumPickerScreen`）、媒体压缩（`ucg_media_compress.dart`）、presign/upload 与 `UcgRepository.createPost` / `deletePost`；**缺少** `updatePost` 与从帖子详情进入编辑的入口。

后端 `entity.History` 仅有文本字段，list API 不返回 `postId` 或媒体元数据。go_ai_talk 侧 UCG `UpdatePost` 与 `PUT /ucg/app/api/posts/{id}` 已实现，可直接供客户端调用。

本地偏好模式可复用 `EventRemarkMemoryStore`（SharedPreferences + per-key JSON）。用户已确认：门禁仅 JWT `sub≠0`（wx.id），**不**以 unionid / `isWxBound` 拦截；曾同步后关闭「同步广场」须 `deletePost`。

## Goals / Non-Goals

**Goals:**

- 全部历史事件类型在编辑 Sheet 内支持最多 9 图或 1 视频，横向条带 UI，删除与拖拽排序。
- 「同步广场」开关（默认 OFF、仅在有媒体时可开启、按 history id 本地持久化）与保存时三分支：同步发帖/更新、仅本地缓存、曾同步后关同步删帖。
- 后端 history list/update 返回 `postId` 与媒体摘要，供跨设备回显与 re-edit。
- UCG 详情页作者「编辑」→ compose 更新模式；`UcgRepository.updatePost`。
- 设置页「清除历史媒体缓存」仅清理本地复制文件与映射。

**Non-Goals:**

- 不改变 `feed-history-sync` WS 增量策略或重连后 list 行为。
- 不实现 unionid 绑定拦截或后端 wx 绑定新门禁。
- 不调用 `feedRepository.clearCache()` 全量清缓存。
- 不在历史列表行内嵌媒体预览（首版仅编辑 Sheet 内展示）。
- 自动化测试文件。

## Decisions

### 1. 媒体条带 vs 九宫格

历史编辑 Sheet 使用**横向 `ListView`**（固定高度缩略图 cell），而非 compose 九宫格。

**理由**：Sheet 纵向空间有限；条带更符合「备注附件」心智。拖拽排序复用 `UcgComposeImageGrid` 的 `ReorderableListView` / 长按拖拽逻辑，抽取为 `HistoryEventMediaStrip` 共享排序控制器。

### 2. 媒体条目内存模型

```dart
sealed class HistoryEditMediaItem {
  // LocalFile(path) | RemoteImage(objectKey, thumbUrl) | RemoteVideo(objectKey, posterUrl)
}
```

编辑态维护 `List<HistoryEditMediaItem> _media`；打开 Sheet 时合并三路来源：

| 来源 | 条件 |
|------|------|
| API `rawPayload` 远程字段 | list 返回 `postId` + `imageKeys`/`videoKey` |
| `EventMediaLocalStore` | 无 `postId` 或同步 OFF 且本地有映射 |
| 用户本次新增 | picker 返回的 `XFile` / `AssetEntity` |

### 3. 「同步广场」持久化 — `EventSquareSyncPreferenceStore`

- Key：`event_square_sync_v1_{historyId}`
- 默认：`false`（无记录时）
- 门禁：无选中媒体时开关禁用且强制 OFF；移除全部媒体时自动 OFF；保存路径对「开但无媒体」按 OFF 处理
- 与 remark 缓存不同：按 **history 记录 id** 而非 eventId，因同一事件类型多条记录开关状态独立。

### 4. 保存流程状态机

```
用户点击保存
  ├─ 校验（时间/用量/媒体互斥：图≤9 或 视频=1）
  ├─ history update API（remark + 可选后端媒体字段占位，见 API 决策）
  └─ 并行媒体副作用：
       ├─ sync ON + sub≠0:
       │    ├─ 压缩 → presign/upload（dedup via contentHash）
       │    ├─ postId 为空 → createPost(remark, keys)
       │    └─ postId 非空 → updatePost(remark, keys)
       ├─ sync ON + sub=0:
       │    └─ Toast 绑定微信提示，中止 UCG 副作用（历史字段仍可按产品决定是否允许仅本地保存——本设计：仍允许保存历史文本/时间，跳过 UCG）
       ├─ sync OFF + 曾有 postId:
       │    └─ deletePost → 清除 postId 关联
       └─ sync OFF:
            └─ 复制新媒体至 documents/history_media/{historyId}/，更新 EventMediaLocalStore
```

**顺序**：先确保 history update 成功，再执行 UCG/本地媒体副作用；UCG 失败时 Toast 提示但**不**回滚已提交的历史字段（与现网 remark 保存一致，媒体副作用可重试）。

### 5. 本地存储 — `EventMediaLocalStore`

```json
// SharedPreferences key: event_media_local_v1_{historyId}
{
  "items": [
    {"kind": "image", "relativePath": "history_media/123/a.jpg", "sort": 0},
    {"kind": "video", "relativePath": "history_media/123/v.mp4", "sort": 0}
  ],
  "updatedAt": "ISO8601"
}
```

- 根目录：`getApplicationDocumentsDirectory()/history_media/{historyId}/`
- 编辑替换时删除被移除文件的磁盘副本
- 设置页清理：遍历所有 `event_media_local_v1_*` 键，删目录 + remove 键

### 6. 后端 API 契约（go_ai_talk）

**`entity.History` 扩展字段**（JSON 驼峰）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `postId` | `uint64` / `0` | 关联 UCG 帖子；0 表示无 |
| `mediaType` | `int` | `0` 无 / `1` 图 / `2` 视频 |
| `imageKeys` | `[]string` | 有序 objectKey（最多 9） |
| `videoKey` | `string` | 单视频 objectKey |

- list / latest / WS push payload **SHALL** 包含上述字段（空值省略或零值）。
- `event/update` 请求 **MAY** 携带 `postId` 回写（服务端在 UCG 同步成功后可由客户端二次 update，或首版仅客户端本地 `rawPayload` 合并——**推荐**：update 接受可选 `postId` 字段供网关持久化）。

**迁移**：DB `ALTER TABLE history ADD COLUMN post_id BIGINT DEFAULT 0` 等；旧记录默认空媒体。

### 7. wx 身份门禁

复用 `ucg-compose-post` 既有 `sub=0` 提示文案；**不得**新增 unionid 检查。后端 UCG 控制器已用 `wxID` from JWT sub，无需改动 unionid 拦截。

### 8. UCG 更新与详情编辑

- `UcgRepository.updatePost` 镜像 `createPost` body，调用 `PUT /posts/{id}`（gateway 已映射 `UcgAppCtrl.PostUpdate`）。
- `UcgComposeScreen` 增加 `editPostId` + `initialMedia` 参数；发表按钮文案「更新」。
- `UcgMomentsActionMenu` 增加可选 `onEditTap`；详情页作者行：`[编辑] [删除]`。

### 9. 分阶段实施

| 阶段 | 范围 |
|------|------|
| P1 | Flutter 本地媒体 + 条带 UI + sync OFF 路径 + 设置清理 |
| P2 | go_ai_talk history 字段 + 客户端 mapper 解析 |
| P3 | sync ON → createPost/updatePost/deletePost |
| P4 | UCG 详情编辑入口 + `updatePost` |

P1 可独立验收；P3 依赖 P2 的 `postId` 回显。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| UCG 上传成功但 history `postId` 写回失败 | 客户端 save 后 `replaceRecord` 合并 postId；失败 Toast 提示用户重开编辑 |
| 本地媒体占磁盘 | 设置页清理；替换时删旧文件 |
| 大图/视频压缩耗时阻塞保存 | 保存按钮 loading；压缩在 isolate/后台 |
| 跨设备 sync OFF 媒体不可见 | 文档明确仅本机；sync ON 走 UCG CDN |
| 曾同步删帖与广场缓存不一致 | deletePost 成功后清 postId + 刷新我的动态 provider |

## Migration Plan

1. **go_ai_talk**：迁移 DB → 部署 history list 新字段（向后兼容，旧客户端忽略新字段）。
2. **Flutter**：发版含 P1–P4；旧版无媒体 UI，忽略新 JSON 字段无害。
3. **回滚**：后端新列可保留；客户端回退版本不展示媒体。

## Open Questions

- history `event/update` 是否由**服务端**在 UCG 回调后写 `postId`（当前设计为客户端 update 携带）——首版采用客户端写回，减少后端编排。
- WS `update` 推送是否携带完整 `imageKeys`（建议 yes，与 list 一致）。
