## Context

- **现状**：`go_ai_talk` ucg-service 在 Feed、profile、chat DTO 中主要返回 `cdnUrl`/`avatarUrl` 全分辨率地址；列表场景带宽与解码成本高。Flutter `app/lib/ucg/data/ucg_media_url.dart` 在 API 无 thumb 时对 CDN 自行追加 `image/resize,w_400` 或 `video/snapshot,t_0`（`unify-ucg-wxid-api-alignment` §40），与「OSS 处理串服务端持有」冲突。
- **团队决策**：图片缩略图由服务端统一 OSS 处理串生成；视频封面**不需要**服务端定义，Flutter 列表自取首帧；**仅** profile 主页/头部使用全分辨率头像，其余列表 surface 一律 `avatarThumbnailUrl`；**聊天视频气泡必须**展示客户端首帧封面。
- **基线**：UCG 能力规格见 `openspec/changes/unify-ucg-wxid-api-alignment/specs/**`（尚未并入 `openspec/specs/` 独立 capability 目录）；本变更 supersede 其中客户端 OSS fallback 与 CDN video snapshot 相关条款。
- **范围**：`d:\work\go_ai_talk` ucg-service + `d:\work\flutter_ai_talk\app\lib\ucg\`。

## Goals / Non-Goals

**Goals:**

- 服务端集中 `BuildCdnURL` + `BuildImageThumbnailURL`，固定处理串：`image/auto-orient,1/resize,m_lfit,w_200/quality,q_90/format,jpg`。
- API DTO 为**图片**场景返回缩略图 URL：`thumbnailUrl`（帖子 image media）、`avatarThumbnailUrl`（profile 及列表 enrichment）、`mediaThumbnailUrl`（聊天 image 消息）。
- Flutter 列表/grid/头像气泡使用 API 缩略图；lightbox、内联/全屏播放使用全分辨率 `cdnUrl`。
- Flutter 视频列表封面（含 Feed tile 与**聊天视频气泡**）：客户端本地提取首帧（可见时懒加载 `VideoPlayerController`，初始化后 seek/pause 于 t=0，滚出视口 dispose；可复用 `UcgInlineVideoPlayer` / Feed tile 既有模式）。
- **头像路由**：profile 主页/头部（`ucg_profile_header.dart`）使用全分辨率 `avatarUrl`；所有列表 surface 使用 `avatarThumbnailUrl`（见 §2 路由表）。
- 移除 `UcgMediaUrl.ossProcessUrl` 及客户端 OSS 猜测逻辑。

**Non-Goals:**

- 服务端 `BuildVideoPosterURL`、视频 media 的 `thumbnailUrl`/`thumbKey`。
- OSS `video/snapshot,t_0` 作为客户端或服务端 fallback。
- 为视频持久化独立 poster objectKey 或上传封面图。
- 修改 presign/上传流程（仍只传原 media objectKey）。

## Decisions

### 1. 服务端 CDN helper（仅图片 thumb）

在 `go_ai_talk` ucg-service（建议 `internal/services/ucg/cdn.go` 或现有 config 包旁）新增：

```go
const imageThumbProcess = "image/auto-orient,1/resize,m_lfit,w_200/quality,q_90/format,jpg"

func BuildCdnURL(objectKey string) string
func BuildImageThumbnailURL(objectKey string) string // BuildCdnURL + ?x-oss-process=
```

- **rationale**：单点持有 OSS 参数，便于日后调整宽度/质量而不发版 Flutter。
- **替代方案**：Flutter 继续 append OSS —— 已拒绝（§40 回滚方向）。

### 2. DTO 字段映射与头像路由

| 场景 | 全分辨率 | 缩略图（新增/规范） | Flutter 展示 |
|------|----------|---------------------|--------------|
| Feed `media[]` image | `cdnUrl` | `thumbnailUrl` | grid 用 thumb；lightbox 用 `cdnUrl` |
| Feed `media[]` video | `cdnUrl` | — | 客户端首帧 poster |
| Profile API | `avatarUrl` | `avatarThumbnailUrl` | **仅** profile 主页/头部用 `avatarUrl` |
| Feed 作者头像 / liker grid / follow list | — | `avatarThumbnailUrl` | 列表 surface 一律 thumb |
| 消息 Tab / 会话列表 / 聊天 AppBar / 气泡头像 | — | `avatarThumbnailUrl` / `peerAvatarThumbnailUrl` | 列表 surface 一律 thumb |
| Chat message image | `mediaCdnUrl` | `mediaThumbnailUrl` | 气泡预览用 thumb |
| Chat message video | `mediaCdnUrl` | — | **必须**客户端首帧 poster |

JSON 仍兼容解析 `thumbUrl`/`thumbnailKey` 别名，但服务端 canonical 输出 `thumbnailUrl` 系列。

**已决**：Profile 主页/头部大图使用 `avatarUrl` 全分辨率；Profile 大图预览（若有点头像 lightbox）同样使用 `avatarUrl`。所有列表类 surface **不得**加载全分辨率头像。

### 3. Flutter 图片 URL 解析

- `UcgMediaUrl.thumbnailUrl(...)`：**仅**接受 API 字段；缺失时列表场景回退 `fullUrl`（或占位），**不得**调用 `ossProcessUrl`。
- 删除或 `@Deprecated` `ossProcessUrl`；`defaultThumbWidth = 400` 移除或改为文档常量（服务端 w_200）。
- `UcgPost` / chat message / profile model 映射新字段。

### 4. Flutter 视频 poster（客户端首帧）

- Feed `UcgMomentsVideoTile` / `UcgInlineVideoPlayer`：未播放前展示本地首帧（懒加载 controller → initialize → mute → pause at start → `VideoPlayer` 首帧或 `VideoPlayerController` texture）；**不**读取 API `thumbnailUrl`（video media 无此字段）。
- **聊天视频气泡**（`ucg_chat_screen.dart`）：与 Feed tile **相同方案**，**必须**展示客户端首帧 poster；不得仅显示「[视频]」文案占位或依赖服务端 thumb。
- 滚出视口 / dispose 时释放 controller，避免列表内大量并发 init（可保留现有 `_UcgVideoInitLimiter`）。
- Web：首帧提取仍受 codec/CORS 约束；失败时渐变+播放图标（与现 spec 一致）。
- **替代方案**：OSS snapshot —— 明确排除。

### 5. 聊天 HTTP 历史 media 字段

若 `GET /conversations/{id}/messages` 响应层仍剥离 `imageKey`/`videoKey`/`mediaCdnUrl`/`mediaThumbnailUrl`，须在后端 DTO→JSON 链路恢复，否则客户端无法展示缩略图（与 `unify-ucg-wxid-api-alignment` tasks §33 同类问题）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 视频首帧懒加载增加列表滚动时 CPU/网络 | 视口内才 init；init 限流；滚出 dispose |
| Flutter 先于后端发布导致无 thumb 字段 | **强制**后端先部署；Flutter 移除 `ossProcessUrl` 后仅可回退 `fullUrl`（非 OSS 拼接） |
| Web 视频首帧/CORS 失败 | 保留 gradient 占位；文档化 CDN `Access-Control-Allow-Origin` 需求 |
| §40 已实现客户端 OSS，与 spec 冲突 | 本变更 tasks 明确删除 `ossProcessUrl` 路径 |

## Migration Plan

1. **后端（必须先完成）**：合并 CDN helper + DTO 字段；**部署 ucg-service 至生产**，确认 Feed/profile/chat 响应含 thumb 字段。
2. **Flutter（后端上线后）**：解析新字段 → UI 切 thumb URL → 删除 OSS 客户端拼接 → Feed 与聊天视频 poster 切首帧模式 → 头像按路由表分流 `avatarUrl` / `avatarThumbnailUrl`。
3. **验证**：Feed 图片 grid、profile 头部全图 vs 列表 thumb 头像、聊天图片气泡、Feed 与聊天视频封面（未点击前首帧、点击后全 URL 播放）。
4. **回滚**：Flutter 可临时回退 fullUrl（非 OSS）；后端 helper 为 additive，可停止填充 thumb 字段。**禁止**在未部署后端时发布移除 `ossProcessUrl` 的 Flutter 版本。
