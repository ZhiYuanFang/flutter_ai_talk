## MODIFIED Requirements

### Requirement: Mini program SHALL be share landing detail only

The `wx_ai_talk` mini program MUST expose only the debate **detail** page as a registered route for user-facing navigation. List/feed pages MUST NOT be registered in `app.json` as entry pages. Share links MUST land on `pages/debate/detail?id={postId}`. The mini program is a **traffic funnel** to Pangbao App, not a full UCG client.

小程序 MUST 仅详情页引流；MUST NOT 提供 Feed 列表主页。

#### Scenario: app.json 仅详情

- **WHEN** 小程序启动配置加载
- **THEN** 首个页面 MUST 为 `pages/debate/detail` 或等价单页配置
- **AND** MUST NOT 注册 `pages/debate/list` 为首页

#### Scenario: 分享路径进详情

- **WHEN** 用户打开分享卡片
- **THEN** 小程序 SHALL 打开对应帖子详情

### Requirement: Mini program SHALL use v1 UCG comment API

Mini program MUST call `GET|POST /ucg/app/api/posts/{id}/comments` (v1). MUST NOT call `/ucg/app/api/v2/posts/{id}/comments`. Comment rows MUST display `voteSideLabel` when present.

小程序评论 MUST 走 v1 路径。

#### Scenario: 详情拉评论 v1

- **WHEN** 详情页加载论点
- **THEN** `utils/ucg.js` MUST 请求 v1 comments 路径

### Requirement: Mini program SHALL CTA to Pangbao App for publishing debates

A persistent bottom CTA on detail MUST guide users to install/open Pangbao App to publish or browse more debates. Mini program MUST NOT implement compose.

详情 MUST 展示去 App CTA；MUST NOT 发帖。

#### Scenario: 详情底部 CTA

- **WHEN** 用户浏览分享落地详情
- **THEN** UI SHALL 展示「去胖宝 App 参与更多辩论」或同等语义 CTA

## REMOVED Requirements

### Requirement: Mini program SHALL provide debate feed list

**Reason**: Product scope reduced to share landing only.

**Migration**: Remove `pages/debate/list` from routes and delete v2 feed fetch from `utils/ucg.js`.
