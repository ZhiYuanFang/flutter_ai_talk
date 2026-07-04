## 1. go_ai_talk — Feed 与创建 [go]

- [x] 1.1 `normalizeFeedTypeFilter("")` 改为不过滤；确认 `filterPostIDsByTypeFromSnapshots` 混排行为
- [x] 1.2 `ListRecommendFeed` / `ListFollowingFeed` 移除 `enrichPostsWithCommentsPreview` 调用
- [x] 1.3 `CreatePostWithParams`：半填立场拒绝；双填推断 debate；移除辩论禁媒体校验
- [x] 1.4 新增 `hasDebateLabels` helper；vote/comment 门禁与创建推断共用
- [x] 1.5 v1 `UcgCommentItem` 增加 `voteSide`/`voteSideLabel` 字段定义
- [x] 1.6 `ListComments` 映射 `debate_vote_side`；`commentDTOToItem` 输出 voteSide（可选内调 Redis 读模型）
- [x] 1.7 删除 v2 UCG 路由注册：`/v2/feed/recommend|following`、`/v2/posts`、`/v2/posts/{id}/comments`；清理 controller 死代码
- [x] 1.8 更新 gateway usagestats skip 规则（移除 v2 comments 匹配若不再需要）
- [ ] 1.9 本地验证：混排 feed 无 comments[]；v1 评论含 voteSide；半填创建 4xx

## 2. flutter_ai_talk — 模型与 Repository

- [x] 2.1 `UcgPost.isDebate` 改为左右标签均非空判定
- [x] 2.2 `fetchRecommendedFeed` / `fetchFollowingFeed`：`v2: false`，移除 `type=debate`
- [x] 2.3 `fetchComments` / `addComment`：`v2: false`
- [x] 2.4 `createPost` 统一 v1 `POST /posts`；合并 `createDebatePost` 逻辑；支持 debateLeft/Right + media
- [x] 2.5 客户端半填立场提交前校验（与服务端错误文案一致）

## 3. flutter_ai_talk — 广场纵向混排 Feed

- [x] 3.1 `ucg_square_tab.dart`：`SliverList` 纵向全宽混排；moment → `UcgMasonryFeedCard`；debate → `UcgDebateFeedCard`（弃用 `StaggeredGrid`）
- [x] 3.2 移除广场 `FloatingActionButton` 与 `UcgDebateComposeScreen` 导航
- [x] 3.3 `UcgDebateFeedCard`：文案 → 媒体（若有）→ VS 条；假玻璃 panel
- [x] 3.4 投票成功后更新本地 `myVoteSide` 并触发 lazy comments
- [x] 3.5 `UcgDebateArgumentsBlock`：仅 `myVoteSide != null` 时 mount；移除 feed comments seed 与自动拉取
- [x] 3.6 `UcgPostMediaSection` / `UcgSquareFeedMediaPreview`：Feed 最多 3 图横排；超出第 3 格角标 `+N`；视频 16:9 单预览
- [x] 3.7 moment / debate 卡 meta 行：`ucgPostFeedMetaLine`（`MM-dd HH:mm · 属地 · 距离`，距离不在媒体 overlay）
- [x] 3.8 移除 `flutter_staggered_grid_view` 依赖（广场不再使用）
- [x] 3.9 moment 卡 meta 行就地 toggle 点赞：0 赞空心 ♡、已赞实心；`likeCount>0` 显示数字；辩论卡无点赞
- [x] 3.10 广场 Feed 图片点击 lightbox；moment 视频点击进详情；`UcgSquareFeedMediaPreview` 支持 `openLightboxOnTap`
- [x] 5.4 `UcgMyPostTimelineItem`：辩论帖展示媒体（3 图 +N，文案→媒体→VS）；点媒体进详情不 lightbox

## 4. flutter_ai_talk — Compose 与 Shell

- [x] 4.1 `ucg_shell.dart`：`showComposeEntry: true`；`_openCompose` 草稿优先后直达 `UcgComposeScreen`（跳过 entry sheet）
- [x] 4.2 `UcgComposeScreen`：增加左右立场输入（各 ≤5 字）；发布走统一 create API
- [x] 4.3 compose 内保留媒体 grid 添加（拍摄/相册从 compose 触发）
- [x] 4.4  deprecate / 移除 `UcgDebateComposeScreen` 路由引用（文件可删或保留未引用）
- [x] 4.5 compose 辩论独立 panel + Switch（默认 OFF；ON 时展示立场；ON 且双方空拦截发布）
- [x] 4.6 `UcgComposeDraft` 持久化 `debateEnabled` / `debateLeft` / `debateRight` 并恢复
- [x] 4.7 compose 辩论区 keyboard lift：`ScrollController` + 动态 bottom padding + inset 二次顶起；锚点整 panel

## 5. flutter_ai_talk — 详情与视觉

- [x] 5.1 `ucg_post_detail_screen.dart`：isDebate 新判定；未投票不展示论点；投票后拉 v1 评论
- [x] 5.2 确认 `UcgDebateVsBar` 马卡龙/emoji/无 blur/左右热区；label-aware floor 完整展示立场文案
- [x] 5.3 确认 `UcgFeedFakeGlassPanel` 与分享离屏布局一致（`ucg_debate_share.dart`）

## 6. wx_ai_talk — 小程序引流 [wx]

- [x] 6.1 `app.json`：移除 `pages/debate/list`；仅保留 detail 为入口
- [x] 6.2 删除或停用 `pages/debate/list.*`
- [x] 6.3 `utils/ucg.js`：评论/Feed 改 v1 路径；移除 `fetchRecommendFeed` v2 与 list 依赖
- [x] 6.4 `pages/debate/detail`：确认 v1 评论 voteSide 展示；底部 App 引流 CTA

## 7. 手工验收

- [ ] 7.1 App Chrome/Web：混排纵向 Feed、moment 进详情、辩论全宽就地投票、投票后论点；3 图 +N 与 meta 行；moment meta 行就地点赞；广场图片 lightbox；个人中心辩论有媒体
- [ ] 7.2 App：Dock + 直达 compose；半填立场失败；双填+图片辩论发布成功；辩论 Switch OFF/ON 与草稿恢复
- [ ] 7.3 App：确认无 v2 Feed/评论 HTTP 请求（DevTools / ApiHttpLog）
- [ ] 7.4 小程序：分享链接仅进详情；投票+评论 v1；无列表页
- [ ] 7.5 go：v2 UCG 路径 404；v1 feed 混排且无 comments 预览

## 8. 文档与收尾

- [ ] 8.1 标记 `ucg-debate-pivot` / `ucg-debate-feed-glass` 中已被 supersede 的 task（可选注释于 PR）
- [ ] 8.2 实现完成后运行 `/opsx-archive` 收版（含 `--remove-changes`）
