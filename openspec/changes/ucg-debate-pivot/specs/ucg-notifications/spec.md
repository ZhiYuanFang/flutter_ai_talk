## ADDED Requirements

### Requirement: Interaction inbox SHALL support debate_vote notification type

The existing UCG interaction notification inbox (方案 A) MUST accept `type=debate_vote` rows. List UI MUST render copy indicating who voted and which side label was chosen. Tapping MUST navigate to the debate post detail.

互动收件箱 MUST 支持 `debate_vote` 类型并跳转辩论详情。

#### Scenario: 展示投票通知

- **WHEN** 收件箱含 `debate_vote` 且投票者昵称为「小红」、side 为 left、标签为「母乳」

- **THEN** 文案 SHALL 表明「小红」支持了「母乳」或同等语义

#### Scenario: 点击投票通知

- **WHEN** 用户点击 `debate_vote` 通知行

- **THEN** App SHALL 打开对应 `UcgPostDetailScreen`

## MODIFIED Requirements

### Requirement: Notification insert SHALL snapshot post cover thumb at write time

Each notification row written by `NotifyOnComment` (for `comment_on_post` and `mention_in_comment`) and `NotifyOnVote` (for `debate_vote`) SHALL include denormalized post cover fields: `post_thumb_url` VARCHAR(512) and `post_media_kind` TINYINT where `0=none`, `1=image`, `2=video`, `3=debate_topic` (text snapshot or rendered thumb URL). For debate posts without media, ucg-service SHALL set `post_media_kind=3` and `post_thumb_url` to a topic-derived snapshot URL or designated debate placeholder CDN path.

通知写入须快照封面；辩论帖无媒体时使用 `post_media_kind=3` 与话题衍生缩略图。

#### Scenario: 图片帖通知封面

- **WHEN** 被评论 moment 帖首条媒体为图片（`media_kind=1`）

- **THEN** 写入的 `post_thumb_url` SHALL 等于 `BuildImageThumbnailURL(objectKey)` 且 `post_media_kind=1`

#### Scenario: 辩论帖投票通知缩略

- **WHEN** 写入 `debate_vote` 通知且帖为 `type=debate` 无媒体

- **THEN** `post_media_kind` SHALL 为 `3`
- **AND** `post_thumb_url` SHALL 非空（话题摘要图或统一辩论占位图）

#### Scenario: 无媒体 moment 帖

- **WHEN** moment 帖子无 `ucg_post_media` 行

- **THEN** `post_thumb_url` SHALL 为空串且 `post_media_kind=0`
