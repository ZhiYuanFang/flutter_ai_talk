## MODIFIED Requirements

### Requirement: 我的页 SHALL use Xiaohongshu-style profile layout

Profile pages (owner **我的** tab and viewer `UcgUserProfileScreen`) MUST share a single `UcgProfileShell` with `NestedScrollView` + collapsing `SliverAppBar`. When scrolled, the profile header collapses upward; the pinned toolbar SHALL show **only a centered shrunk avatar** and MUST NOT show nickname in the collapsed toolbar. When `kUcgTreasureEnabled` is `true`, both owner and viewer pages MUST expose tabs **动态** and **宝藏**. When `kUcgTreasureEnabled` is `false`, pages MUST show only the posts list (**动态** content) without a `TabBar`, for both owner and viewer. Layout and surfaces MUST follow `ucg-visual-system` minimal style.

资料壳层在宝藏开关开启时为「动态」「宝藏」双 Tab；关闭时仅展示动态列表（主人与访客一致）。

#### Scenario: 折叠顶栏仅头像
- **WHEN** 用户在资料页向上滚动使 header 折叠
- **THEN** 顶栏 SHALL 在居中位置展示缩小头像
- **AND** 顶栏 SHALL NOT 展示昵称文字

#### Scenario: 展开态完整资料
- **WHEN** 用户位于资料页顶部或未折叠状态
- **THEN** UI SHALL 展示头像、昵称、简介、统计与操作区（主人/访客按模式区分）

#### Scenario: 他人主页与我的页一致（宝藏关闭）
- **WHEN** `kUcgTreasureEnabled` 为 `false` 且用户打开我的 Tab 或 `UcgUserProfileScreen`
- **THEN** UI SHALL 仅展示动态帖子列表
- **AND** UI SHALL NOT 展示「宝藏」Tab

#### Scenario: 宝藏关闭时资料头与动态列表无额外间距
- **WHEN** `kUcgTreasureEnabled` 为 `false` 且用户位于资料页顶部
- **THEN** 资料卡片与动态列表之间 SHALL NOT 为原 TabBar 预留额外空白高度
- **AND** `NestedScrollView.body` SHALL 直接挂载动态列表（非单 Tab `TabBarView`）
- **AND** `NestedScrollView.floatHeaderSlivers` SHALL 为 `false`
- **AND** 动态列表 SHALL NOT 遮挡资料卡操作区（关注/私信等）

#### Scenario: 他人主页关注按钮可点击
- **WHEN** 用户打开他人 `UcgUserProfileScreen` 且 `kUcgTreasureEnabled` 为 `false`
- **THEN** 展开态关注与私信按钮 SHALL 不被动态列表遮挡
- **AND** 资料头 `expandedHeight` SHALL 容纳含操作行的资料卡（含简介时增高）

#### Scenario: 编辑资料
- **WHEN** 已登录用户在**主人态**修改昵称/头像/简介并保存
- **THEN** App SHALL 调用 `PUT /ucg/app/api/profile/me` 并展示审核中或成功状态

#### Scenario: 我的动态点击进详情
- **WHEN** 用户在动态列表点击帖子行或图片
- **THEN** App SHALL 打开与广场相同的沉浸式详情页

## REMOVED Requirements

### Requirement: 宝藏占位 Tab on profile

**Reason**: 与底部导航一致，首版临时隐藏宝藏入口。

**Migration**: `kUcgTreasureEnabled = true` 后恢复双 Tab 与 `UcgProfileTreasureTab` 占位。

#### Scenario: 宝藏占位
- **WHEN** 用户进入「宝藏」Tab（主人或访客）
- **THEN** （本 change 期间不适用）
