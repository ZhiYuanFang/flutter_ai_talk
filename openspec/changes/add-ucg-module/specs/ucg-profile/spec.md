## ADDED Requirements

### Requirement: 我的页 SHALL use Xiaohongshu-style profile layout

The 我的 tab SHALL show profile header (avatar, nickname, bio), editable for owner, follow list entry, 我的动态 list, and 我的宝藏 placeholder「尚未开通」. Layout and surfaces MUST follow `ucg-visual-system` (shell background, glass/surface cards, theme primary accents, no separated AppBar).

#### Scenario: 编辑资料
- **WHEN** 已登录用户修改昵称/头像/简介并保存
- **THEN** App SHALL 调用 `PUT /ucg/app/api/profile/me` 并展示审核中或成功状态

#### Scenario: 我的宝藏占位
- **WHEN** 用户进入「我的宝藏」
- **THEN** UI SHALL 显示「尚未开通」

### Requirement: Profile viewing SHALL gate edits to owner

Only the profile owner SHALL see edit controls. Other users' profiles MAY be viewed read-only when API allows.

#### Scenario: 查看他人主页
- **WHEN** 用户从 Feed 点击他人头像
- **THEN** App SHALL 打开只读 profile 页，且 SHALL NOT 显示编辑按钮
