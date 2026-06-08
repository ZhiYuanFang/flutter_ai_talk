## Why

当前 UCG「我的」Tab 与他人主页（`UcgUserProfileScreen`）为两套独立实现：我的页有 TabBar（我的动态/我的宝藏）但无折叠顶栏，他人主页仅有静态头部、无动态列表 Tab，且缺少按作者拉取已发布帖子的后端 API。用户在广场点击自己头像与他人头像应进入同一套资料壳层体验；滚动时头像应收缩至顶栏居中，昵称不进入折叠工具栏。需统一壳层并补齐后端契约，才能一致展示动态与宝藏 Tab。

## What Changes

### 统一资料壳层（Flutter）

- 抽取共享组件 `UcgProfileShell`，供 `UcgProfileTab`（我的 Tab）与 `UcgUserProfileScreen`（他人/自己从 Feed 进入）复用。
- 使用 `NestedScrollView` + `SliverAppBar`：资料区随滚动上收；折叠后顶栏**仅居中显示缩小头像**，**不得**在折叠工具栏展示昵称。
- Tab 结构统一为「动态」+「宝藏」（他人页与我的页同款 Tab 文案与布局）。
- 动态 Tab：复用 `UcgMyPostTimelineItem` 时间线组件；我的页继续 `GET /posts/mine`（含全部状态）；他人页使用新 API `GET /posts/user/{wxId}`（仅已发布）。
- 宝藏 Tab：他人页与我的页共用 `_MyTreasureTab` 占位「尚未开通」（无数据时一致）。
- 主人态：inline 编辑昵称/简介/头像、关注列表入口等行为保留在壳层 header 区域。
- 访客态：关注 + 私信入口；无 inline 编辑。

### 广场 Feed 路由（**BREAKING** 行为）

- 用户在 Feed 点击**自己**头像时，**不得**跳转「我的」Tab 或走特殊 self 分支；**必须**打开与点击他人头像相同的 `UcgUserProfileScreen`（传入当前用户 wxId）。

### 后端 go_ai_talk（**不得跳过**）

- 新增 `GET /ucg/app/api/posts/user/{wxId}?page=&pageSize=`：返回指定作者**已发布**（status=2）帖子分页，DTO 与 `GET /posts/mine` 一致；可选登录态 enrichment `likedByMe`。
- gateway-app：匿名白名单前缀 `/ucg/app/api/posts/user/`（与公开 profile 读取策略一致）。
- 参考实现模式：`ListMyPosts`、`ListFollowingFeed`（`internal/services/ucg/`）。

### Flutter 数据层

- `UcgRepository` / `UcgApiClient` 新增 `fetchUserPosts(wxId, page)`；Riverpod provider 支持他人动态分页（当前 `ucgMyPostsProvider` 仅 page-1）。

## Capabilities

### New Capabilities

（无全新能力域；本变更在既有能力上扩展需求。）

### Modified Capabilities

- `ucg-api-contract`：新增 `GET /posts/user/{wxId}` 分页契约、gateway 白名单、DTO 与 `posts/mine` 对齐及 `likedByMe` 可选 enrichment。
- `ucg-profile`：统一 `UcgProfileShell`、折叠顶栏（仅头像）、他人页动态/宝藏 Tab、主人/访客差异、宝藏占位一致。
- `ucg-square-feed`：Feed 头像点击（含本人）统一进入 `UcgUserProfileScreen`，取消跳转「我的」Tab 的 self 特例。

## Impact

- **Flutter**：`app/lib/ucg/ui/ucg_shell.dart`（`UcgProfileTab` 重构）、`ucg_profile_screens.dart`（`UcgUserProfileScreen` 改用壳层）、新增/提取 `ucg_profile_shell.dart`（或等效路径）；`ucg_square_tab.dart` 及 Feed 卡片头像 tap 路由；`ucg_repository.dart`、`ucg_providers.dart`；复用 `ucg_feed_moments_widgets.dart` 中 `UcgMyPostTimelineItem` 与 `_MyTreasureTab`。
- **后端**（`d:\work\go_ai_talk`）：ucg-service posts handler + service 层 `ListUserPosts`；gateway 白名单；与现有 `GET /profile/{wxId}`、`GET /posts/mine` 并存。
- **OpenSpec**：本变更 delta 覆盖/扩展 `ucg-minimal-visual-system` 与 `ucg-keyboard-input-enhancements` 中「我的页」布局相关条款；折叠行为与 Tab 统一以本变更为准。
- **部署顺序**：先后端 API + gateway 白名单，再 Flutter 他人动态 Tab；我的页壳层重构可与后端并行，但他人 Tab 依赖新 API。
