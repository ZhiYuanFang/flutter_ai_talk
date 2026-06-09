## MODIFIED Requirements

### Requirement: Feed and detail SHALL display author bio from API

Public feed cards SHALL show truncated author bio (2 lines). Detail page SHALL show author bio as a **single line** under the nickname in the **header row** (same Column as nickname, vertically centered with avatar). Detail SHALL NOT repeat bio in the scrollable body. Bio text SHALL come from `authorBio` / `author.bio` on post DTO.

#### Scenario: 详情顶栏单行简介
- **WHEN** 用户打开含非空 `authorBio` 的帖子详情
- **THEN** 顶栏昵称下方 SHALL 展示一行小字简介（ellipsis）
- **AND** 昵称与简介 Column SHALL 与头像纵向居中对齐

#### Scenario: 详情无简介
- **WHEN** `authorBio` 为空
- **THEN** 顶栏 SHALL 仅展示昵称且不预留空行

#### Scenario: Feed 卡片仍为两行
- **WHEN** 用户在广场 Feed 查看卡片
- **THEN** authorBio SHALL 仍为最多 2 行 ellipsis（不变）
