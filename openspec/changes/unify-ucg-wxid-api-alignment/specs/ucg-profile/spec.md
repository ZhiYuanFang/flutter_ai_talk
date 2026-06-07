## MODIFIED Requirements

### Requirement: 我的页 SHALL use Xiaohongshu-style profile layout

The 我的 tab SHALL show profile header (avatar, nickname, bio), editable for owner, follow list entry, 我的动态 list, and 我的宝藏 placeholder「尚未开通」. Layout and surfaces MUST follow `ucg-visual-system` (shell background, glass/surface cards, theme primary accents, no separated AppBar). Profile identity fields MUST use `wxId` from JWT `sub` per `ucg-wxid-identity`; API calls use `GET/PUT /ucg/app/api/profile/me` and `GET /ucg/app/api/profile/{wxId}` for others.

#### Scenario: 编辑资料
- **WHEN** 已登录用户（wxId 非零）修改昵称/头像/简介并保存
- **THEN** App SHALL 调用 `PUT /ucg/app/api/profile/me`（HTTP PUT）并展示审核中或成功状态

#### Scenario: 我的宝藏占位
- **WHEN** 用户进入「我的宝藏」
- **THEN** UI SHALL 显示「尚未开通」

### Requirement: Profile viewing SHALL gate edits to owner

Only the profile owner SHALL see edit controls. Other users' profiles MAY be viewed read-only via `GET /profile/{wxId}` when API allows (including anonymous when gateway whitelist enabled).

#### Scenario: 查看他人主页
- **WHEN** 用户从 Feed 点击他人头像（`authorWxId`）
- **THEN** App SHALL 打开只读 profile 页（`GET /profile/{wxId}`），且 SHALL NOT 显示编辑按钮

### Requirement: Profile API SHALL expose social stats and avatar update

`GET /profile/me` and `GET /profile/{wxId}` responses SHALL include `followingCount`, `followerCount`, and `postCount` when computed server-side. Authenticated requests to `GET /profile/{wxId}` SHALL include `isFollowing` for the viewer relative to the profile owner. Avatar change on 我的页 SHALL use single-image picker (`pickImage`) and `PUT /profile/me` with `avatarKey`.

#### Scenario: 我的页关注数展示
- **WHEN** 已登录用户打开「我的」且已关注他人
- **THEN** 关注 stat chip SHALL 显示服务端 `followingCount`（非零），关注/取关后 SHALL 刷新

#### Scenario: 点头像换头像
- **WHEN** 已绑定微信用户在「我的」页点击头像并选择图片
- **THEN** App SHALL 打开系统选图器、上传并调用 `PUT /profile/me` 更新头像

#### Scenario: 他人主页取关
- **WHEN** 已登录用户打开已关注用户的主页
- **THEN**「关注」按钮 SHALL 展示「已关注」且为浅色底；点击后 SHALL 调用 `DELETE /follow/{wxId}` 并更新为实心「关注」

### Requirement: 我的 Tab profile header SHALL omit marketing title and use left-aligned identity layout

The 我的 tab SHALL NOT display the page title「我的」or subtitle「记录与分享你的育儿故事」. Profile header SHALL show avatar left-aligned, nickname to the upper-right of the avatar, a following-count pill chip below nickname (tapping opens follow list per §11.10), and IP location below the chip. Owner SHALL see「编辑资料」instead of follow/DM actions; other users' profiles SHALL show compact「关注」+「私信」action row per interaction rules.

#### Scenario: 我的 Tab 无顶栏营销文案
- **WHEN** 用户打开「我的」Tab
- **THEN** 顶栏 SHALL NOT 展示「我的」标题与「记录与分享你的育儿故事」副标题

#### Scenario: 资料头图布局
- **WHEN** 已登录用户查看「我的」或他人主页
- **THEN** 头像左对齐、昵称在头像右上、关注数 pill 可点击（本人）或只读展示（他人）、IP 属地展示 API 字段或「IP属地：未知」

#### Scenario: 他人主页关注与私信
- **WHEN** 已登录用户打开他人主页且未关注
- **THEN**「关注」按钮 SHALL 实心主色、「私信」浅色透明底；已关注时两按钮均为浅色透明底

### Requirement: UCG UI SHALL use theme tokens instead of hardcoded colors

All widgets under `app/lib/ucg/` SHALL derive foreground, surface, border, scrim, and on-primary colors from `Theme.of(context).colorScheme` and `AppVisualTokens` via `ucg_theme.dart` helpers; hardcoded `Colors.*` and fixed hex values are prohibited except fully transparent sentinels.

#### Scenario: 主题切换下 UCG 可读
- **WHEN** 用户切换喂养主题 preset / 深浅 shell
- **THEN** UCG 卡片、chip、按钮、Feed 灰块与聊天气泡 SHALL 随主题色更新且无硬编码色残留

#### Scenario: 非 classicLight preset 主色与 shell 一致
- **WHEN** 用户选择 softBlue / softGreen 等 swatch preset 或自定义背景色（非 classicLight）
- **THEN** `ColorScheme.primary` SHALL 从当前 bundle 种子推导，且 SHALL NOT 仍固定为性别主色（如女宝红色）

#### Scenario: 昵称编辑图标对齐
- **WHEN** 已绑定用户在「我的」查看资料头
- **THEN** 昵称旁编辑图标 SHALL 紧贴昵称且与昵称文字垂直居中

### Requirement: 我的 Tab SHALL use inline profile editing without separate edit screen

Owner profile SHALL edit nickname via small icon at nickname top-right and bio via tap below avatar row (placeholder「点击编辑个人简介」when empty). App SHALL NOT show「编辑资料」button or `UcgProfileEditScreen`. `PUT /profile/me` body SHALL NOT include `ipLocation`.

#### Scenario: 内联编辑昵称
- **WHEN** 已绑定用户点击昵称旁编辑图标并保存
- **THEN** App SHALL 调用 `PUT /profile/me` 仅含 `nickname`（及可选 `avatarKey`/`bio`），无独立编辑页

#### Scenario: 内联编辑简介
- **WHEN** 用户点击简介占位或现有简介
- **THEN** App SHALL 展示内联输入并保存至 `PUT /profile/me`

### Requirement: 我的 Tab SHALL omit postCount stat chip

The 我的 tab profile header SHALL NOT display a separate `postCount` stat chip; post list in「我的动态」tab is the canonical count surface.

#### Scenario: 无动态数 chip
- **WHEN** 用户打开「我的」Tab
- **THEN** UI SHALL NOT 展示独立的「动态」计数卡片

#### Scenario: 我的动态时间轴布局
- **WHEN** 用户切换到「我的动态」Tab 且存在帖子
- **THEN** 列表 SHALL 采用 WeChat「我的朋友圈」式双列时间轴（日期左、内容右），左列不展示 IP 属地，无 per-post 背景色
- **AND** 同日仅首条左列展示日期；每条右列底部展示 `HH:mm`；帖子间极低对比度分割线（opacity 约 0.18）仅覆盖右列；点击行打开详情页（详情页右上角删除）；下拉刷新在短列表与 Web 上须可靠触发

### Requirement: Profile IP location SHALL come from gateway resolution

`GET /profile/me` SHALL resolve client IP via `X-Internal-Client-IP`, throttle-update `wx.ip_location` via device internal API, and return `ipLocation`. `GET /profile/{wxId}` SHALL read `ipLocation` from device batch. Following count SHALL use smaller plain text without pill background.

#### Scenario: 我的页 IP 属地
- **WHEN** 已登录用户打开「我的」
- **THEN** 资料头 SHALL 展示 API `ipLocation` 或「IP属地：未知」
