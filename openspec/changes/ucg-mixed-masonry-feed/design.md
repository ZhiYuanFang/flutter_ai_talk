## Context

- **v2.0.3 基线**：广场双列 Masonry（`UcgMasonryFeedCard`）、Dock「+」→ 入口 sheet → compose、v1 Feed/评论。
- **debate pivot 现状**：单列辩论 Feed、`type=debate` 过滤、v2 Feed 带 `comments[]` 预览、广场 FAB → `UcgDebateComposeScreen`、Dock compose 隐藏。
- **go 现状**：v1/v2 controller 共用 `ListRecommendFeed`（含 `enrichPostsWithCommentsPreview`）；v1 `UcgPostItem` 已有辩论票数字段；v1 `ListComments` 未映射 `debate_vote_side`；v2 评论走 Redis。
- **约束**：WebSocket/日志/Android R8 等见 `openspec/project.md`；三仓协同（App / go / 小程序）。

## Goals / Non-Goals

**Goals:**

- 恢复 v2.0.3 广场 Dock compose 主路径，混排 moment 与辩论帖（**纵向全宽列表**，非双列 Masonry）。
- 前端 isDebate = 左右标签均非空；Feed v1 无 inline 评论；投票后 lazy fetch v1 评论（含 voteSide）。
- 统一 v1 创建帖（媒体 + 可选立场）；半填立场服务端拒绝。
- 删除 UCG v2 HTTP 路由；App/小程序改调用 v1。
- 合并假玻璃 VS 条视觉；小程序仅详情引流页。

**Non-Goals:**

- 不重做投票/原力值/分享截图/OAuth 等 pivot 已完成能力。
- 不改造小程序为完整 UCG 客户端（无 Feed 列表、无发帖）。
- 不在本变更内收版归档 pivot/glass 旧 change 目录（实现完成后再 `/opsx-archive`）。
- 不新增自动化 widget 测试。

## Decisions

### 1. Feed 布局：纵向全宽列表（2026-07 修订）

- **决策**：`SliverList` 单列纵向混排；moment 与 debate 均全宽一行，按服务端顺序插入对应 widget（`UcgMasonryFeedCard` / `UcgDebateFeedCard`）。
- **媒体预览**：Feed 卡最多 3 图横排；超出在第 3 格标 `+N`；视频单 16:9 预览；距离仅在 `ucgPostFeedMetaLine` meta 行。
- **理由**：产品要求纵向阅读流与统一 meta/媒体规则；弃用双列 Masonry 权重。
- **原方案（已弃）**：2 列 `StaggeredGrid` span1/span2 —— 见 REMOVED spec。

### 2. isDebate 判定与创建推断

- **决策**：`bool get isDebate => debateLeft.trim().isNotEmpty && debateRight.trim().isNotEmpty`；创建时任一侧非空 ⇒ 两侧必填，否则 400。
- **理由**：与产品「半填即失败」一致；后端写入 `type=debate` 但客户端不读 `type`。
- **go**：`CreatePostWithParams` 在 `(left=="") != (right=="")` 时返回「请补全另一方立场」；两侧均有值时 `type=debate` 且 **允许** media；均为空 ⇒ moment。

### 3. API：删除 v2 路由，v1 扩展

- **决策**：
  - App Feed：`v2: false`，路径 `/feed/recommend|following`，不传 `type`（混排）。
  - App 评论：`v2: false`；v1 `UcgCommentItem` + `voteSide`/`voteSideLabel`。
  - App 创建：统一 `POST /posts`（v1），弃 `/v2/posts`。
  - go：移除 v2 handler 注册；`ListRecommendFeed` 去掉 `enrichPostsWithCommentsPreview`；`normalizeFeedTypeFilter("")` → 不过滤。
  - v1 `PostCommentsGet` 实现 **可** 内调 `ListCommentsFromRedis`（性能），对外 schema 仍为 v1。
- **理由**：v1 DTO 已含票数字段；v2 仅多 Feed comments 预览，与新产品方向冲突。
- **备选**：保留 v2 仅给未知旧客户端 —— 用户明确要求删除。

### 4. 懒评论 UX

- **决策**：`UcgDebateArgumentsBlock` 仅当 `post.myVoteSide != null` 时 mount；mount 后 `fetchComments(v1)`；移除 `initState` 对 `post.comments` seed 与 `commentCount>0` 自动拉取。
- **理由**：Feed 不再带 comments；减少列表 Redis/MySQL 压力。

### 5. Compose 入口

- **决策**：`UcgBottomDock.showComposeEntry: true`；`_openCompose` 草稿优先 → 否则直接 `UcgComposeScreen`；compose 页内保留媒体 grid + 新增左右立场输入；移除 `showUcgComposeEntrySheet` 于 Dock 路径。
- **理由**：对齐 v2.0.3 Dock 心智，减少一步；媒体选择移入 compose（已有 grid/add 控件）。

### 6. 辩论帖可有图

- **决策**：Feed 辩论卡：文案下方 `UcgFeedMedia`（复用 moment 媒体组件或 masonry 封面逻辑），再 VS 条。
- **go**：移除「辩论帖不得附带媒体」校验。

### 7. 小程序范围

- **决策**：`app.json` pages 仅 `pages/debate/detail`；删除 list 页与 v2 调用；分享 path 不变；底部 CTA「去胖宝 App 看更多辩论」。
- **理由**：引流工具，非平行产品。

### 8. 假玻璃视觉

- **决策**：沿用 `UcgFeedFakeGlassPanel`、`UcgDebateVisualTokens`、马卡龙 `UcgDebateVsBar`（已实现于 glass change）；moment 卡仍用 `UcgSurfaceCard`（v2.0.3 轻表面）。
- **理由**：辩论卡视觉差异化；moment 保持原 Masonry 轻量。

### 9. moment Feed 就地点赞

- **决策**：`UcgMasonryFeedCard` meta 行右侧心形单击 toggle；Feed 响应 `likedByMe` 驱动空心/实心；optimistic 更新；辩论卡无点赞 UI。
- **理由**：减少进详情路径；go 已 batch 填充 `likedByMe`（Redis SET）。

### 10. 广场 lightbox vs 个人中心进详情

- **决策**：`UcgSquareFeedMediaPreview` 图片 tap → `showUcgPhotoLightbox`；广场 moment 视频 tap → 详情；profile 时间轴媒体不 lightbox，整行 InkWell 进详情；辩论 profile 文案→3 图→VS。
- **理由**：广场快速看图；个人中心与详情路径统一。

### 11. Compose 辩论 Switch 模块

- **决策**：图文 panel 与「辩论」panel 分离；Switch 默认 OFF；ON 时双方立场必填（皆空拦截）；草稿存 Switch + 文案。
- **理由**：降低误发辩论；与 moment 发布路径清晰分离。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 删除 v2 后若有未知客户端 404 | 变更说明 BREAKING；gateway 监控 v2 UCG 调用量后再删 |
| Masonry 全宽辩论卡打断双列节奏 | **已弃双列**；改为纵向全宽，节奏一致 |
| v1 ListComments 走 MySQL 性能 | handler 内复用 Redis 读模型，响应仍 v1 schema |
| pivot/glass 旧 change 规格冲突 | 本 change supersede 明确；归档时合并 delta |
| compose 无入口 sheet 用户不知在哪加图 | compose 页保留明显「+」媒体格与 hint |

## Migration Plan

1. **go_ai_talk 先发**：v1 评论 voteSide、Feed 去 preview、混排、创建推断；部署后 App 再切 v1。
2. **App**：repository → square UI → compose → 删 FAB。
3. **wx_ai_talk**：detail + v1 API；移除 list。
4. **回滚**：恢复 v2 路由注册与 App `v2: true`（保留 git revert 路径至 deploy 前）。

## Open Questions

- （已关闭）半填立场：创建失败 ✓
- （已关闭）FAB 移除，仅 Dock + ✓
- （已关闭）评论 v1 + voteSide ✓
- gateway 是否需对 v2 UCG 路径返回 410 Gone 文案 —— 实现时可加简短 JSON message。
