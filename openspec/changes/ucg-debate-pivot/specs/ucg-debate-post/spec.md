## ADDED Requirements

### Requirement: Post type SHALL distinguish debate from moment

The system MUST persist `type` on each UCG post as `debate` or `moment`. `moment` SHALL retain existing media-post behavior. `debate` SHALL require topic text in `content`, `debateLeft` and `debateRight` labels (each max 5 Unicode characters), and MUST NOT attach `ucg_post_media` rows. Public square and following feeds MUST request only `debate` posts.

系统 MUST 为每条 UCG 帖子持久化 `type`（`debate`|`moment`）。`debate` 须含话题正文与左右立场标签且不得有媒体；广场与关注 Feed MUST 仅拉取 `debate`。

#### Scenario: 创建辩论帖

- **WHEN** 已登录用户提交辩论 compose 且左右标签均 ≤5 字、正文非空
- **THEN** `POST /posts` body SHALL 含 `type: "debate"`、`content`、`debateLeft`、`debateRight`
- **AND** 服务端 MUST NOT 创建 `ucg_post_media` 行

#### Scenario: 辩论帖拒绝媒体

- **WHEN** 客户端尝试为 `type=debate` 的帖子附带 presign 媒体 keys
- **THEN** 服务端 SHALL 返回 400 且 MUST NOT 发布该帖

#### Scenario: 广场 Feed 仅 debate

- **WHEN** App 请求推荐或关注 Feed
- **THEN** Client SHALL 传 query `type=debate`
- **AND** 响应列表 MUST NOT 含 `type=moment` 项

#### Scenario: 个人时间线含全部类型

- **WHEN** 客户端请求 `GET /profile/{wxId}/posts`
- **THEN** 服务端 SHALL 返回作者的 debate 与 moment 帖子（按时间排序）
