## ADDED Requirements

### Requirement: 小智音箱页须说明硬件自购前提

The Xiaozhi speaker management screen SHALL show a short capability note that the user must purchase a Xiaozhi speaker themselves before using binding, and that the App provides unlock/binding only (not hardware). The note MUST include a help control (e.g. `?`) that navigates to the purchase howto surface. 小智音箱管理页 **必须** 展示「须自行采购音箱」类能力说明，并提供进入购买说明的帮助入口。

#### Scenario: 进页可见说明与帮助

- **WHEN** 已登录用户打开小智音箱管理页
- **THEN** 页面 MUST 展示自行采购硬件相关说明
- **AND** MUST 提供可进入「如何购买」说明的帮助控件

#### Scenario: 点击帮助进入购买说明

- **WHEN** 用户点击该帮助控件
- **THEN** 客户端 MUST 导航至购买说明页（如 `/settings/xiaozhi-speaker/howto-buy`）

### Requirement: 购买说明页短文与群二维码

The purchase howto page SHALL explain self-purchase of compatible Xiaozhi speakers and that users may join the official WeChat group to ask about buying. When feature catalog `inviteGroupQrUrl` is non-empty after load, the page MUST show the group QR image (resolved like invite howto). When the URL is empty/absent, the page MUST still show the text guidance and MUST NOT show a broken QR placeholder. When the QR image fails to load, the client MUST hide the entire QR block including its caption. 购买说明页 **必须** 含自购与进群咨询说明；有非空群 URL 时展示二维码；URL 空或加载失败时 **不得** 展示破损占位。

#### Scenario: 有群 URL 展示二维码

- **WHEN** catalog 已加载且 `inviteGroupQrUrl` 非空
- **THEN** 购买说明页 MUST 展示可扫码的群二维码（或等价全屏预览入口）
- **AND** 文案 MUST 引导用户进群咨询购买相关问题

#### Scenario: 无群 URL 仅文字

- **WHEN** catalog 无 `inviteGroupQrUrl` 或为空
- **THEN** 购买说明页 MUST 仍展示自购/咨询相关文字
- **AND** MUST NOT 展示无效二维码框

#### Scenario: 图片加载失败隐藏整块

- **WHEN** 群二维码图片加载失败
- **THEN** 客户端 MUST 隐藏该二维码区块（含其标题/说明），不得只留空图框

### Requirement: 购买说明与字段帮助分离

The purchase howto MUST NOT be merged into the MAC or MCP token field-help screens; those screens MUST remain focused on console copy-paste guidance. 购买说明 **不得** 与 MAC/MCP 字段帮助页合并。

#### Scenario: 字段帮助不含购买主路径

- **WHEN** 用户从添加表单打开 MAC 或 MCP 接入点帮助
- **THEN** 该帮助页 MUST NOT 以购买硬件/群购为主内容（购买入口保留在管理页能力说明）

### Requirement: 购买说明路由须登录门禁

Access to the purchase howto route MUST require login consistently with the Xiaozhi speaker management routes. 购买说明路由 **必须** 与小智音箱管理页同样要求登录。

#### Scenario: 未登录不可直达

- **WHEN** 未登录用户试图打开购买说明路由
- **THEN** 客户端 MUST 按既有登录门禁拦截或引导登录
