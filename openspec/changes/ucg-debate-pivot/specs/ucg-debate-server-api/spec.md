## ADDED Requirements

### Requirement: go_ai_talk SHALL migrate schema for debate and votes

`go_ai_talk` ucg-service MUST add migrations: `ucg_post.type` (`debate`|`moment`, default `moment`), `debate_left_label` / `debate_right_label` VARCHAR(5), table `ucg_post_vote` with unique `(post_id, voter_wx_id)`, and `wx.force_value INT DEFAULT 0`.

go_ai_talk MUST 提供 debate 字段、投票表、原力值列的数据库迁移。

#### Scenario: 迁移兼容存量

- **WHEN** 部署 migration 后查询历史帖子
- **THEN** 未设置 type 的行 MUST 表现为 `moment`

### Requirement: Feed APIs SHALL filter by type query parameter

`GET /feed/recommend` and `GET /feed/following` MUST accept optional `type` query (`debate`|`moment`). When App sends `type=debate`, responses MUST only include matching posts. Vote counts and `myVoteSide` MUST be included per debate item when viewer is authenticated.

Feed API MUST 支持 `type` 过滤；辩论项 MUST 返回投票计数与 `myVoteSide`。

#### Scenario: 推荐流 debate 过滤

- **WHEN** `GET /feed/recommend?type=debate&page=1`
- **THEN** 每项 `type` MUST 为 `debate`
- **AND** 每项 SHALL 含 `leftVoteCount`、`rightVoteCount`

### Requirement: device-service SHALL add miniprogram jscode2session login path

`go_ai_talk` device-service MUST accept `platform=miniprogram` on `POST /device/app/api/login`, exchange `code` via WeChat `jscode2session`, upsert wx user by unionid, and return the same token shape as App OAuth login.

device-service MUST 实现小程序 jscode2session 登录路径。

#### Scenario: 小程序 code 换 token

- **WHEN** 合法 `platform=miniprogram` 与有效 `code`
- **THEN** 响应 SHALL 含 access token 且 unionid MUST 与微信开放平台一致

### Requirement: NotifyOnVote SHALL write debate_vote notifications

When a user votes on a debate post and the voter is not the author, ucg-service MUST insert `ucg_notification` with `type=debate_vote`, snapshot post topic for thumb fields per notifications capability, and recipient = post author.

非作者投票时 MUST 向帖主写入 `debate_vote` 通知。

#### Scenario: 他人投票通知帖主

- **WHEN** 用户 B 对用户 A 的辩论帖投票
- **THEN** 系统 SHALL 为用户 A 插入 `debate_vote` 通知行
