## Context

### Flutter 现状

| 入口 | 文件 | 现状 |
|------|------|------|
| 我的 Tab | `ucg_shell.dart` → `UcgProfileTab` | 固定 header + `TabBar`（我的动态/我的宝藏）+ `TabBarView`；**无**折叠滚动；header 在 `SingleChildScrollView(physics: NeverScrollable)` 内 |
| 他人主页 | `ucg_profile_screens.dart` → `UcgUserProfileScreen` | 沉浸式顶栏 + 单页 `ListView` 仅展示资料卡；**无** Tab、**无**动态列表 |
| 数据 | `ucg_repository.dart` | 已有 `fetchMyPosts`；**无** `fetchUserPosts` |
| Provider | `ucg_providers.dart` | `ucgMyPostsProvider` 仅拉 page=1 |

`UcgUserProfileScreen` 已对 `mine = userId == ucgCurrentUserIdProvider` 做分支（隐藏关注/私信），但 UI 仍为无 Tab 的简化页，与「我的 Tab」不一致。

### 后端现状（go_ai_talk）

- **已有**：`GET /ucg/app/api/posts/mine`（`ListMyPosts`，含全 status）、`GET /profile/{wxId}`、Feed 列表、`GET /posts/{id}`
- **缺失**：`GET /ucg/app/api/posts/user/{wxId}` — 按作者拉取**已发布**帖子分页

### 已锁定产品决策

1. 折叠滚动：资料区随列表上收；折叠后顶栏**仅居中缩小头像**，**不得**展示昵称
2. 他人主页与我的页同款 Tab：**动态** + **宝藏**
3. 他人宝藏 Tab：与我的页相同「尚未开通」占位
4. Feed 点击**自己**头像 = 打开 `UcgUserProfileScreen`（**不得**跳「我的」Tab，**不得**特殊 self 路由）
5. 他人动态 Tab **本变更必须实现**，依赖新后端 API

## Goals / Non-Goals

**Goals:**

- 抽取 `UcgProfileShell`，统一 `UcgProfileTab` 与 `UcgUserProfileScreen` 的布局与滚动行为
- `NestedScrollView` + `SliverAppBar` 实现 avatar-only 折叠顶栏
- 主人态：inline 编辑、关注列表入口、`GET /posts/mine`（全 status）
- 访客态（含从 Feed 进入的本人）：关注 + 私信、`GET /posts/user/{wxId}`（published only）
- 动态 Tab 复用 `UcgMyPostTimelineItem`；宝藏 Tab 复用 `_MyTreasureTab`
- go_ai_talk 新增 `ListUserPosts` + gateway 白名单

**Non-Goals:**

- 宝藏 Tab 真实内容（仍占位「尚未开通」）
- 他人动态分页 UI  polish 以外的 infinite scroll 优化（首版可 page=1 + 下拉刷新，分页 load-more 为可选 follow-up）
- 修改 `GET /posts/mine` 语义（仍含草稿/审核中）
- 重构关注列表、私信、资料 API 本身

## Decisions

### 1. 共享壳层组件 `UcgProfileShell`

**选择**：新建 `ucg_profile_shell.dart`（或 `widgets/ucg_profile_shell.dart`），通过参数区分模式：

```dart
enum UcgProfileMode { ownerTab, viewerScreen }

UcgProfileShell({
  required UcgProfileMode mode,
  required UcgProfile profile,
  String? leading,           // viewer: back; owner: ucgBackLeading
  bool wxBound = true,         // owner only
  VoidCallback? onProfileUpdated,
})
```

- `UcgProfileTab`：登录门控 + `ucgMyProfileProvider` 加载后渲染 `mode: ownerTab`
- `UcgUserProfileScreen`：保留 fetch profile 逻辑，加载后渲染 `mode: viewerScreen`（**含** `userId == selfId` 的本人从 Feed 进入场景，仍走 viewer 数据路径 `fetchProfile` + `fetchUserPosts`，但 header actions 按 owner/visitor 规则：本人从 Feed 进入时隐藏关注/私信，**保留** inline 编辑若 product 要求 — **决策**：本人从 Feed 进入时使用 `viewerScreen` 布局但 `isOwnerContent = true` 启用 inline 编辑与 `posts/mine` API（见决策 4）

**备选**：两个 Screen 继续独立复制 NestedScrollView — 拒绝，违反 DRY 且 Tab 行为易漂移。

### 2. NestedScrollView + SliverAppBar 折叠

**结构**：

```
NestedScrollView
├── headerSliverBuilder
│   ├── SliverAppBar(pinned, expandedHeight ~220)
│   │   ├── flexibleSpace: 大头像 + 昵称 + bio + stats + actions（展开态）
│   │   └── title: 仅小头像 Center（折叠态，无 nickname Text）
│   ├── SliverToBoxAdapter: 绑定微信提示（owner only）
│   └── SliverPersistentHeader(pinned): TabBar（动态 / 宝藏）
└── body: TabBarView
    ├── 动态: CustomScrollView + SliverList(UcgMyPostTimelineItem...)
    └── 宝藏: _MyTreasureTab
```

**关键参数**：

- `SliverAppBar.stretch: false`；`floating: false`；`pinned: true`
- 折叠 `title`：`Center(child: UcgAvatar(radius: 18))`，**不得**设置 `Text(nickname)`
- 展开区复用现有 `_MyProfileHeaderCard` / `UcgProfileHeader` 逻辑，avatar 与 flexibleSpace 联动可用 `LayoutBuilder` + scroll offset 或 Flutter 默认 `FlexibleSpaceBar` background 仅放装饰；**简化实现**：expanded 区展示完整 header card，collapsed `title` 独立小头像（不要求 pixel-perfect 连续 morph，但视觉上头像居中缩小）

**备选**：`CustomScrollView` 手写 — 复杂度高；NestedScrollView 为 Flutter 标准 Tab + 折叠方案。

### 3. 后端 `ListUserPosts`

**路由**：`GET /ucg/app/api/posts/user/{wxId}?page=1&pageSize=20`

**实现**（`internal/services/ucg/post.go`）：

```go
func ListUserPosts(ctx context.Context, authorWxID, viewerWxID int64, page, pageSize int) (*PageResult, error) {
    model := dao.UcgPost.Ctx(ctx).
        Where(AuthorWxId, authorWxID).
        Where(Status, PostStatusPublished)
    // OrderDesc CreatedAt, postsFromResult(ctx, rows, viewerWxID) for likedByMe
}
```

- DTO 与 `ListMyPosts` 相同（`PostDTO` 列表 + total/page/pageSize）
- `viewerWxID` 来自可选 JWT；0 则 `likedByMe=false`
- Handler：`ucg_app_api.go` 新增 `ListUserPosts`；`api/v1/ucg_app_http.go` 注册 path
- Gateway：白名单前缀 `/ucg/app/api/posts/user/`（匿名可读已发布帖，与 public profile 一致）

**备选**：复用 Feed 带 author filter — 无现成 API，且 Feed 排序/推荐语义不同。

### 4. 主人 vs 访客数据路径

| 场景 | Profile 来源 | 动态 API | Header actions |
|------|-------------|----------|----------------|
| 我的 Tab | `ucgMyProfileProvider` / `GET /profile/me` | `GET /posts/mine` | inline 编辑 + 关注列表 |
| 他人主页 | `GET /profile/{wxId}` | `GET /posts/user/{wxId}` | 关注 + 私信 |
| Feed 点自己头像 | `GET /profile/{wxId}` 或 me | **`GET /posts/mine`**（全 status，与 Tab 一致） | inline 编辑（同 owner） |

**决策**：`UcgProfileShell` 接受 `postsSource: UcgProfilePostsSource { mine \| user(wxId) }`，由父组件根据入口决定，**不得**在 Shell 内 `switchTab` 到「我的」。

### 5. Riverpod

- 保留 `ucgMyPostsProvider`（owner）
- 新增 `ucgUserPostsProvider.family(userId)` 或 `FutureProvider` + invalidate on refresh
- `UcgRepository.fetchUserPosts({required String wxId, required int page})`

### 6. Feed 头像路由

- 确认 `ucg_square_tab.dart`、详情页 `_openUserProfile` **统一** push `UcgUserProfileScreen`，**删除**任何 `if (userId == selfId) switchToProfileTab` 分支（若存在）
- Spec 级约束：即使已有部分实现，本变更完成时不得残留 self 特例

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| NestedScrollView + TabBarView 嵌套滚动冲突 | 动态 Tab 使用 `PrimaryScrollController`；TabBarView `physics: NeverScrollable` 与现我的 Tab 一致 |
| 后端未部署时他人动态 Tab 空白/报错 | Flutter 显示错误态 + 重试；tasks 明确先后端再联调 |
| 本人 Feed 入口用 mine API 与 viewer profile 来源不一致 | 接受；profile 仍可用 `fetchProfile(selfId)` 保证 `isFollowing` 等字段一致 |
| SliverAppBar 双头像（展开+collapsed）视觉跳跃 | 首版接受；后续可加 `FlexibleSpaceBar` 连续动画 |
| `posts/mine` 暴露草稿给本人 Feed 入口 | 产品已接受（与我的 Tab 一致） |

## Migration Plan

1. **go_ai_talk**：实现 `ListUserPosts` + migration 无 + gateway 白名单 → 部署 test 环境
2. **Flutter 数据层**：`fetchUserPosts` + provider
3. **Flutter UI**：提取 `UcgProfileShell` → 迁移 `UcgProfileTab` → 重写 `UcgUserProfileScreen`
4. **Feed 路由审计**：移除 self 特例
5. **回滚**：Flutter 可 revert Shell；后端新路由 additive，可保留

## Open Questions

- 无阻塞项。他人动态分页 load-more 是否首版必做：建议 tasks 中 page=1 + pull-to-refresh 为 MVP，load-more 列为可选子任务。
