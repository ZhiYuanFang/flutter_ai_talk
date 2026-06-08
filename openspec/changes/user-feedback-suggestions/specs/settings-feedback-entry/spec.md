## ADDED Requirements

### Requirement: Settings center SHALL expose feedback entry for logged-in users only

The settings screen MUST show a「反馈建议」entry using the same glass tile pattern as other settings items (`_SettingsGlassPanel` + `_buildGlassTile` style). The entry MUST appear only when `sessionProvider.isLoggedIn` is true, consistent with「账号管理」login gating. Tapping the entry MUST navigate to `/settings/feedback`.

设置中心须在已登录状态下展示「反馈建议」玻璃 tile，点击跳转反馈列表页。

#### Scenario: 已登录显示入口
- **WHEN** 用户已登录并打开设置中心
- **THEN** 页面 SHALL 展示「反馈建议」玻璃列表项
- **AND** 视觉样式 SHALL 与相邻设置项（如「账号管理」）一致

#### Scenario: 未登录不显示入口
- **WHEN** 用户未登录并打开设置中心
- **THEN** 页面 SHALL NOT 展示「反馈建议」入口
- **AND** SHALL NOT 允许未登录直达反馈列表（路由层亦须门禁）

#### Scenario: 点击跳转
- **WHEN** 已登录用户点击「反馈建议」
- **THEN** App SHALL 导航至 `/settings/feedback`

### Requirement: Feedback route SHALL enforce login gate

The `/settings/feedback` route MUST verify login before rendering feedback content. If the user is not logged in, the app MUST redirect to login or block access equivalent to account management flows.

反馈路由须登录门禁，未登录不得查看或提交反馈。

#### Scenario: 未登录直达路由
- **WHEN** 未登录用户通过深链或手动导航访问 `/settings/feedback`
- **THEN** App SHALL 引导至登录或返回，不得展示反馈数据或提交控件
