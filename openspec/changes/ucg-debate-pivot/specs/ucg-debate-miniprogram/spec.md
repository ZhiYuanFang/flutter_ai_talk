## ADDED Requirements

### Requirement: Mini program SHALL support debate vote and arguments

The `wx_ai_talk` mini program MUST display debate posts with topic, left/right labels, `UcgDebateVsBar` equivalent (percentages only, same minDisplayRatio and zero-vote rules), vote taps, and flat comments as arguments. Comment compose MUST support `@mention` reply consistent with App wire format.

小程序 MUST 支持辩论展示、投票与论点评论，VS 条规则与 App 一致。

#### Scenario: 小程序投票

- **WHEN** 已登录用户在小程序点击 VS 条左侧
- **THEN** 小程序 SHALL `POST /ucg/app/api/posts/{id}/vote` with `side: left`

#### Scenario: 小程序发论点

- **WHEN** 用户提交评论
- **THEN** 小程序 SHALL `POST /posts/{id}/comments` 且 body 含 `content`

### Requirement: Mini program login SHALL use jscode2session platform miniprogram

The mini program MUST call `wx.login`, then `POST /device/app/api/login` with `{ "platform": "miniprogram", "code": "<jscode>" }`. The backend MUST implement jscode2session for `wx_ai_talk` credentials and issue JWT bound to the same unionid as App fluwx login.

小程序 MUST 经 `platform=miniprogram` 登录，与 App fluwx 共享 unionid 账号体系。

#### Scenario: 首次小程序登录

- **WHEN** 用户打开小程序且本地无有效 JWT
- **THEN** 小程序 SHALL `wx.login` 并 POST device login
- **AND** 返回 JWT MUST 与同一微信 unionid 的 App 账号一致

### Requirement: Mini program SHALL CTA to Pangbao App for publishing debates

The mini program MUST NOT implement debate compose. A persistent bottom CTA MUST deep-link or guide users to install/open Pangbao App to publish debates.

小程序 MUST NOT 提供发帖；底部 CTA MUST 引导至胖宝 App 发布辩论。

#### Scenario: 发布 CTA 展示

- **WHEN** 用户浏览小程序辩论详情或列表
- **THEN** UI SHALL 展示「去胖宝 App 发起辩论」或同等语义 CTA
