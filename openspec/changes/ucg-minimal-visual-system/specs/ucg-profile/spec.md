## MODIFIED Requirements

### Requirement: 我的页 SHALL use Xiaohongshu-style profile layout

The 我的 tab SHALL show profile header (avatar, nickname, bio), editable for owner, follow list entry, 我的动态 list, and 我的宝藏 placeholder「尚未开通」. Layout and surfaces MUST follow `ucg-visual-system` **minimal** style (shell background, light-surface cards where needed, theme primary accents, lightweight selection, no separated AppBar, no glass morphism).

我的页须采用小红书式布局，并遵循 UCG 简约视觉体系（轻表面、无玻璃拟态、沉浸式顶栏）。

#### Scenario: 编辑资料
- **WHEN** 已登录用户修改昵称/头像/简介并保存
- **THEN** App SHALL 调用 `PUT /ucg/app/api/profile/me` 并展示审核中或成功状态

#### Scenario: 我的宝藏占位
- **WHEN** 用户进入「我的宝藏」
- **THEN** UI SHALL 显示「尚未开通」

## ADDED Requirements

### Requirement: Profile inline edit fields SHALL use keyboard bridge

Nickname and bio inline edit `TextField`s on 我的页 MUST use `ManagedKeyboardTextField` with `onConfirm` mapped to the existing commit/save handlers.

我的页昵称与简介 inline 编辑输入必须接入键盘确认条，`onConfirm` 映射至现有保存逻辑。

#### Scenario: 编辑昵称键盘确认
- **WHEN** 用户在我的页进入昵称编辑并聚焦输入框
- **THEN** 键盘顶部 SHALL 显示确认条，且 SHALL NOT 顶起整个我的页布局

#### Scenario: 确定提交昵称
- **WHEN** 用户在昵称编辑场景点击确认条「确定」
- **THEN** App SHALL 回填昵称并执行 `_commitNickname` 或等效保存逻辑
