# Tasks: ucg-unified-profile-shell

## 1. 后端 go_ai_talk（ucg-api-contract）

- [x] 1.1 `internal/services/ucg/post.go` 新增 `ListUserPosts(ctx, authorWxID, viewerWxID, page, pageSize)`：`Where(authorWxId)` + `Where(status=Published)`，复用 `postsFromResult` enrichment `likedByMe`
- [x] 1.2 `internal/controller/ucg_app_api.go` 新增 handler：解析 path `{wxId}`、query `page`/`pageSize`、可选 JWT viewer
- [x] 1.3 `api/v1/ucg_app_http.go` 注册 `GET /ucg/app/api/posts/user/{wxId}`（summary: 用户已发布动态）
- [x] 1.4 gateway-app UCG 匿名白名单增加前缀 `/ucg/app/api/posts/user/`
- [x] 1.5 test 环境验证：匿名与已登录请求返回仅 published 帖、分页字段与 `posts/mine` DTO 一致

## 2. Flutter 数据层

- [x] 2.1 `UcgApiClient` / `UcgRepository` 新增 `fetchUserPosts({required String wxId, required int page})` → `GET /ucg/app/api/posts/user/{wxId}`
- [x] 2.2 `ucg_providers.dart` 新增 `ucgUserPostsProvider`（`family(userId)` 或等效），page=1 + invalidate 刷新
- [x] 2.3 确认 `UcgPost` / `UcgPagedPosts` 解析复用 `fetchMyPosts` 路径，无重复映射

## 3. 抽取 UcgProfileShell（ucg-profile）

- [x] 3.1 新建 `ucg_profile_shell.dart`（或 `widgets/` 下）：`UcgProfileMode`、`UcgProfilePostsSource`（mine | user）
- [x] 3.2 实现 `NestedScrollView` + `SliverAppBar(pinned)`：展开区完整 header；折叠 `title` 仅居中小头像，**无昵称**
- [x] 3.3 `SliverPersistentHeader` 固定 `TabBar`：Tab 文案「动态」「宝藏」
- [x] 3.4 动态 Tab：`CustomScrollView` + 复用 `UcgMyPostTimelineItem`；按 `postsSource` 绑定 mine/user provider
- [x] 3.5 宝藏 Tab：复用 `_MyTreasureTab`（从 `ucg_shell.dart` 提取为可 import 的 widget 若尚未独立）
- [x] 3.6 主人态：迁入 `_MyProfileHeaderCard` inline 编辑、绑定微信提示、关注列表入口；保留 `ManagedKeyboardTextField`
- [x] 3.7 访客态：迁入 `UcgProfileHeader` + 关注/私信 `UcgProfileActionRow`；隐藏 inline 编辑

## 4. 接入入口 Screen

- [x] 4.1 重构 `UcgProfileTab`（`ucg_shell.dart`）：登录门控 + `ucgMyProfileProvider` 后渲染 `UcgProfileShell(mode: owner, postsSource: mine)`
- [x] 4.2 重构 `UcgUserProfileScreen`（`ucg_profile_screens.dart`）：加载 profile 后渲染 `UcgProfileShell(mode: viewerScreen, leading: back)`
- [x] 4.3 Feed 点自己头像场景：`userId == selfId` 时 `postsSource: mine` + owner header actions，**仍停留在** `UcgUserProfileScreen`，不 switch Shell Tab
- [x] 4.4 删除 `UcgProfileTab` / `UcgUserProfileScreen` 中重复的 Column+TabBar 旧布局代码

## 5. Feed 路由审计（ucg-square-feed）

- [x] 5.1 审计 `ucg_square_tab.dart`、`ucg_post_detail_screen.dart`、`ucg_masonry_feed_card.dart`：确认头像 tap 统一 `UcgUserProfileScreen`
- [x] 5.2 移除任何 `if (userId == selfId) switchToProfileTab` 或跳转「我的」Tab 分支（若存在）
- [x] 5.3 详情页头像 tap 与 Feed 行为一致（已有则仅确认）

## 6. 验证

- [x] 6.1 我的 Tab：折叠滚动仅顶栏头像；动态/宝藏 Tab 正常；编辑资料键盘确认条
- [x] 6.2 他人主页：动态 Tab 展示已发布帖；宝藏「尚未开通」；关注/私信可用
- [x] 6.3 Feed 点自己头像：进入 `UcgUserProfileScreen`（含 Tab + 折叠），不跳「我的」Tab
- [x] 6.4 后端未就绪时：他人动态 Tab 错误态 + 重试可接受
