## MODIFIED Requirements

### Requirement: Pro ideas non-empty state SHALL show copy cards likes and more-ideas CTA

When the ideas list is non-empty, the Pro card MUST show：title「可能扩展包含以下能力」；small line「热度越高越可能被收纳进Pro功能中」；then idea rows ordered as returned by the server (newest-first). The client MUST NOT show the former adoption-incentive line「被采纳的意见提供者后续可联系管理者，获取免费开通Pro版1个月的资格」. Each row MUST be a single compact list row：a list bullet marker, then the idea `text`, with a fire-style like control and `likeCount` on the trailing side, vertically centered with the text block. The client MUST NOT show author label「{babyName}的家长」and MUST NOT use the former indented rectangular body chrome as the primary row layout. Tapping like MUST toggle like/unlike. Below the list the client MUST show button「我有更多想法」and the same付费意愿小字. 有想法时 **必须** 紧凑 bullet 行 + 火赞；**不得** 展示采纳资格文案与家长昵称。

#### Scenario: Header without adoption incentive

- **WHEN** list 含至少一条
- **THEN** UI MUST 展示标题与「热度越高…」小字
- **AND** MUST NOT 展示「被采纳…1个月的资格」文案

#### Scenario: Compact bullet row anatomy

- **WHEN** list 含至少一条
- **THEN** 每条 MUST 为列表 bullet + 想法正文 + 右侧火标热度（与正文块纵向居中）
- **AND** MUST NOT 展示「{宝宝名}的家长」
- **AND** MUST NOT 以缩进矩形正文作为主布局

#### Scenario: Like toggle

- **WHEN** 用户点某条火标
- **THEN** 客户端 MUST 调用 like 或 unlike 并更新该条热度/已赞态

### Requirement: Client SHALL highlight the current user’s own ideas

When `isMine` is true, the idea row MUST use a distinct **full-row** accent/highlight color treatment（bullet and idea text at minimum; like affordance MAY share accent）so the user can locate their own ideas at a glance. When `isMine` is false, the row MUST use the default non-highlight treatment. 本人想法 **必须** 整行 accent 高亮。

#### Scenario: Own idea full-row accent

- **WHEN** 某条 `isMine==true`
- **THEN** 该条 UI MUST 以整行 accent 高亮呈现（相对其他条目可分辨）
- **AND** MUST NOT 仅依赖已删除的家长昵称行来表达本人身份
