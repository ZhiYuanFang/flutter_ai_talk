## ADDED Requirements

### Requirement: Web 事件 logo CDN 跨域展示

On Web, `EventLogo` SHALL load remote `logoUrl` with `WebHtmlElementStrategy.prefer` (or equivalent HTML `<img>` strategy) so CDN images display without `Access-Control-Allow-Origin`.

#### Scenario: Web 展示 CDN logo

- **WHEN** 运行在 Web 且事件 `logoUrl` 为 `https://resorce.cuplay.top/...`
- **THEN** `EventLogo` MUST 展示远程图片，MUST NOT 仅因 fetch/CORS 失败而长期显示占位图

### Requirement: 游客事件目录加载与空态

After home is shown, the client SHALL fetch event catalog for guest and logged-in users with retry; while refresh is in-flight or not yet attempted, the home button grid MUST NOT show「暂无可用事件按钮」.

#### Scenario: 游客首次进 Home

- **WHEN** 未登录用户首次进入 `/home` 且内存 catalog 为空
- **THEN** 系统 MUST 在后台请求 `event/options`（可重试）；加载中 MUST 显示 loading；成功后 MUST 展示事件按钮网格

#### Scenario: 远端尝试结束仍无数据

- **WHEN** catalog refresh 已结束且列表仍为空
- **THEN** 系统 MAY 显示「暂无可用事件按钮」
