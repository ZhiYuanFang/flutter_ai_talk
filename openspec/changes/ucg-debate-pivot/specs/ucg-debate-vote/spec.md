## ADDED Requirements

### Requirement: Users SHALL vote once per debate post per side

Authenticated users MUST be able to cast exactly one vote per debate post via `POST /ucg/app/api/posts/{id}/vote` with body `{ "side": "left" | "right" }`. Re-posting the same side SHALL be idempotent. Changing side SHALL update the existing vote row. Debate posts only; moment posts MUST reject vote with 400.

已登录用户对每条辩论帖 MUST 仅能投一票；换边须更新原投票；moment 帖 MUST NOT 接受投票。

#### Scenario: 首次投票

- **WHEN** 已登录用户首次对辩论帖 POST vote `{ "side": "left" }`
- **THEN** 服务端 SHALL 写入 `ucg_post_vote` 行
- **AND** 响应 SHALL 含更新后的 `leftVoteCount`、`rightVoteCount`、`myVoteSide: "left"`

#### Scenario: 重复同边投票

- **WHEN** 用户已对某帖投 left 再次 POST `{ "side": "left" }`
- **THEN** 服务端 SHALL 返回 200 且不新增重复行

#### Scenario: 换边投票

- **WHEN** 用户已投 left 后 POST `{ "side": "right" }`
- **THEN** 服务端 SHALL UPDATE 该用户投票为 right
- **AND** 左右计数 MUST 相应增减

#### Scenario: moment 帖拒绝投票

- **WHEN** 用户对 `type=moment` 帖子调用 vote API
- **THEN** 服务端 SHALL 返回 400

### Requirement: Author vote SHALL increment force value by one

When a vote is successfully recorded and `voter_wx_id` equals the post author's `wx_id`, the system MUST increment `wx.force_value` by 1 for that author. Comment actions MUST NOT increment force value.

当投票者即帖子作者且投票成功时，系统 MUST 将该作者 `force_value` +1；评论 MUST NOT 触发原力变更。

#### Scenario: 作者给自己帖投票

- **WHEN** 帖子作者对自己的辩论帖成功投票
- **THEN** `wx.force_value` SHALL 增加 1

#### Scenario: 他人投票不加作者原力

- **WHEN** 非作者用户对辩论帖投票
- **THEN** 帖子作者 `force_value` MUST NOT 变化

#### Scenario: 评论不加原力

- **WHEN** 任意用户对辩论帖发表评论
- **THEN** 作者 `force_value` MUST NOT 因评论增加
