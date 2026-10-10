## ADDED Requirements

### Requirement: Settings SHALL expose Xiaozhi speaker entry when logged in

When the user is logged in, the settings center MUST show a glass list tile labeled「小智音箱」（or equivalent product copy with that meaning）that navigates to the Xiaozhi speaker management route (e.g. `/settings/xiaozhi-speaker`). The entry MUST use the same glass tile pattern as adjacent settings items and MUST be hidden when logged out. Route access MUST require login consistently with other settings subpages. 已登录时设置中心 **必须** 展示「小智音箱」入口并进入管理页；未登录 **不得** 展示；路由须登录门禁。

#### Scenario: 已登录显示入口

- **WHEN** 用户已登录并打开设置中心
- **THEN** 页面 MUST 展示「小智音箱」玻璃列表项
- **AND** 点击 MUST 进入小智音箱管理页

#### Scenario: 未登录不显示入口

- **WHEN** 用户未登录并打开设置中心
- **THEN** 页面 MUST NOT 展示「小智音箱」入口

#### Scenario: 未登录不可直达

- **WHEN** 未登录用户试图打开小智音箱管理路由
- **THEN** 客户端 MUST 按既有登录门禁拦截或引导登录，MUST NOT 在无会话下展示可写绑定管理
