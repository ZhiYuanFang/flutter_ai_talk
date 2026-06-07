## Why

UCG 列表场景（广场 Feed、头像、聊天图片）当前仍加载全分辨率 CDN 原图，且 Flutter 客户端在 `unify-ucg-wxid-api-alignment` §40 中自行拼接 OSS `image/resize,w_400`，与团队「OSS 处理串由服务端统一持有」的决策冲突。图片缩略图应由 `go_ai_talk` ucg-service 在 DTO 中返回；视频封面则无需服务端定义——客户端本地取首帧即可，避免服务端 snapshot URL 与额外存储。

## What Changes

- **服务端（go_ai_talk）**：新增集中 CDN 辅助函数 `BuildCdnURL` 与 `BuildImageThumbnailURL`（固定 OSS 处理串 `image/auto-orient,1/resize,m_lfit,w_200/quality,q_90/format,jpg`）；在 Feed 帖子 **图片** media、公开/本人 profile、聊天 **图片** 消息等 DTO 中填充缩略图 URL 字段；**不得**为 video media 生成 `thumbnailUrl` 或 `BuildVideoPosterURL`。
- **Flutter UCG**：列表/grid 加载 API 返回的图片缩略图 URL；lightbox/全屏/内联播放仍用 `cdnUrl` 全分辨率；**废弃** `UcgMediaUrl.ossProcessUrl` 及客户端 OSS 猜测逻辑。
- **Flutter 视频封面**：Feed、帖子详情及**聊天视频气泡**等列表场景由客户端本地提取视频首帧作为 poster（如 `VideoPlayerController` 懒加载至 t=0 取帧，或项目内已有等价模式）；点击播放仍用完整 `cdnUrl`。
- **Flutter 头像路由**：**仅** profile 主页/头部大图使用全分辨率 `avatarUrl`；所有列表类 surface（Feed 作者头像、点赞网格、关注列表、消息 Tab、聊天 AppBar/气泡、会话列表等）**必须**使用 `avatarThumbnailUrl`。
- **部署顺序（强制）**：先部署 `go_ai_talk`（ucg-service）并上线 thumb 字段，**再**发布消费这些字段且移除 `ossProcessUrl` fallback 的 Flutter 版本。
- **规格修正**：撤销/替换 `unify-ucg-wxid-api-alignment` 中「客户端 OSS fallback」与「CDN `video/snapshot,t_0`」相关需求，改为服务端图片 thumb + 客户端视频首帧。
- **关联修复**：聊天 HTTP 历史若仍剥离 media 字段，须一并恢复以便缩略图字段可达客户端（见 tasks）。

## Capabilities

### New Capabilities

（无——本变更通过修改既有 UCG 能力 delta 落地，不新增独立 capability 目录。）

### Modified Capabilities

- `ucg-api-contract`：DTO 新增/规范 `thumbnailUrl`（帖子图片 media）、`avatarThumbnailUrl`（profile 及列表 enrichment）、`mediaThumbnailUrl`（聊天图片）；明确视频 media **不含**服务端 `thumbnailUrl`；列表 surface 消费 `avatarThumbnailUrl`。
- `ucg-square-feed`：Feed 图片 grid 必须仅用 API 缩略图；视频列表封面改为客户端首帧；Feed 作者头像与点赞网格使用 `avatarThumbnailUrl`。
- `ucg-chat-ui`：聊天气泡列表图片使用 `mediaThumbnailUrl`；**聊天视频气泡必须**展示客户端首帧封面（与 Feed 视频 tile 同方案）。
- `ucg-profile`：**仅** profile 主页/头部展示全分辨率 `avatarUrl`；所有列表类头像使用 `avatarThumbnailUrl`。

## Impact

- **后端**：`d:\work\go_ai_talk` ucg-service（Feed/profile/chat DTO 映射、CDN helper）；可能涉及 gateway 响应序列化，无新 HTTP 路径。**须先于 Flutter 部署上线。**
- **Flutter**：`d:\work\flutter_ai_talk\app\lib\ucg\`（`ucg_media_url.dart`、`ucg_models.dart`、Feed/聊天/Profile 组件、视频 poster 组件）。**须在 ucg-service thumb 字段可用后发布。**
- **OpenSpec**：本变更 `openspec/changes/ucg-server-image-thumbs-client-video-poster/specs/**` delta；与已归档/进行中的 `unify-ucg-wxid-api-alignment` §40 客户端 OSS 实现存在 supersede 关系。
- **非目标**：服务端 video snapshot URL、客户端继续猜测图片 OSS 参数、为视频持久化独立 poster objectKey。
