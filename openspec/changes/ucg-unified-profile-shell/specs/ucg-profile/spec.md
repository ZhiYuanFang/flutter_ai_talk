## MODIFIED Requirements

### Requirement: 我的页 SHALL use Xiaohongshu-style profile layout

Profile pages (owner **我的** tab and viewer `UcgUserProfileScreen`) MUST share a single `UcgProfileShell` with `NestedScrollView` + collapsing `SliverAppBar`. When scrolled, the profile header collapses upward; the pinned toolbar SHALL show **only a centered shrunk avatar** and MUST NOT show nickname in the collapsed toolbar. Both owner and viewer pages MUST expose the same two tabs: **动态** and **宝藏**. Layout and surfaces MUST follow `ucg-visual-system` minimal style.

我的页与他人主页须共用统一资料壳层；滚动折叠后顶栏仅居中头像；Tab 为「动态」「宝藏」；视觉遵循简约体系。

#### Scenario: 折叠顶栏仅头像
- **WHEN** 用户在资料页向上滚动使 header 折叠
- **THEN** 顶栏 SHALL 在居中位置展示缩小头像
- **AND** 顶栏 SHALL NOT 展示昵称文字

#### Scenario: 展开态完整资料
- **WHEN** 用户位于资料页顶部或未折叠状态
- **THEN** UI SHALL 展示头像、昵称、简介、统计与操作区（主人/访客按模式区分）

#### Scenario: 他人主页 Tab 与我的页一致
- **WHEN** 用户打开 `UcgUserProfileScreen`
- **THEN** UI SHALL 展示「动态」「宝藏」两个 Tab，布局与我的 Tab 同款

#### Scenario: 编辑资料
- **WHEN** 已登录用户在**主人态**修改昵称/头像/简介并保存
- **THEN** App SHALL 调用 `PUT /ucg/app/api/profile/me` 并展示审核中或成功状态

#### Scenario: 宝藏占位
- **WHEN** 用户进入「宝藏」Tab（主人或访客）
- **THEN** UI SHALL 显示「尚未开通」

#### Scenario: 我的动态点击进详情
- **WHEN** 用户在「动态」Tab 点击帖子行或图片
- **THEN** App SHALL 打开与广场相同的沉浸式详情页

#### Scenario: 动态 Tab 图片不进 lightbox
- **WHEN** 用户在资料页「动态」Tab 点击帖子内图片
- **THEN** App SHALL NOT 打开 lightbox

## ADDED Requirements

### Requirement: UcgProfileShell SHALL differentiate owner and viewer modes

`UcgProfileShell` MUST accept an explicit mode. **Owner** (我的 Tab): inline edit fields, follow-list entry, posts from `GET /posts/mine` (all statuses). **Viewer** (others' profile): follow + DM actions, posts from `GET /posts/user/{wxId}` (published only). When the current user opens their own profile from Feed via `UcgUserProfileScreen`, the App MUST NOT switch to the 我的 tab; it MUST use the same screen with owner post source (`posts/mine`) and owner header actions.

统一壳层必须区分主人态与访客态的数据源与操作区；Feed 点自己头像不得跳转我的 Tab。

#### Scenario: 主人态动态含全状态
- **WHEN** 用户在「我的」Tab 查看动态
- **THEN** App SHALL 调用 `GET /posts/mine` 并 MAY 展示非 published 状态帖

#### Scenario: 访客态仅已发布
- **WHEN** 用户查看他人 `UcgUserProfileScreen` 动态 Tab
- **THEN** App SHALL 调用 `GET /posts/user/{wxId}` 且列表 SHALL 仅含已发布帖

#### Scenario: Feed 点自己头像
- **WHEN** 用户在广场 Feed 点击自己的头像
- **THEN** App SHALL push `UcgUserProfileScreen(userId: selfId)`
- **AND** App SHALL NOT navigate to Shell「我的」Tab

#### Scenario: 访客关注与私信
- **WHEN** 用户查看他人资料且非本人
- **THEN** header SHALL 展示关注与私信操作
- **AND** SHALL NOT 展示 inline 编辑控件

#### Scenario: 动态 Tab 复用时间线组件
- **WHEN** 资料页「动态」Tab 渲染帖子列表
- **THEN** App SHALL 复用 `UcgMyPostTimelineItem`（或等效抽取组件）

### Requirement: Profile inline edit fields SHALL use keyboard bridge

Nickname and bio inline edit `TextField`s on owner profile header MUST use `ManagedKeyboardTextField` with `onConfirm` mapped to the existing commit/save handlers.

主人态资料页昵称与简介 inline 编辑必须接入键盘确认条。

#### Scenario: 编辑昵称键盘确认
- **WHEN** 用户在资料页进入昵称编辑并聚焦输入框
- **THEN** 键盘顶部 SHALL 显示确认条，且 SHALL NOT 顶起整个资料页布局

#### Scenario: 确定提交昵称
- **WHEN** 用户在昵称编辑场景点击确认条「确定」
- **THEN** App SHALL 回填昵称并执行保存逻辑
