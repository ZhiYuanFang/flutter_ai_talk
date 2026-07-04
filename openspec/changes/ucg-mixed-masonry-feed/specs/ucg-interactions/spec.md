## MODIFIED Requirements

### Requirement: Debate posts SHALL disable like interactions

Debate posts (both labels non-empty) MUST NOT expose like button or call like API on 广场 debate cards and detail. Moment cards on 广场 MUST NOT show like controls on debate posts.

辩论帖 MUST 禁用点赞；moment 帖在广场可就地点赞。

#### Scenario: 辩论卡无点赞

- **WHEN** 用户浏览广场辩论全宽卡
- **THEN** UI MUST NOT 展示可点的点赞控件

#### Scenario: moment 卡 meta 行就地 toggle 点赞

- **WHEN** 用户在广场 moment 卡 meta 行点击心形
- **THEN** App SHALL 调用 `POST/DELETE /posts/{id}/like` 并 optimistic 更新 `likedByMe` 与 `likeCount`
- **AND** MUST NOT 导航详情页
- **AND** 0 赞时 MUST 仍展示空心 ♡；已赞 MUST 展示实心 ♥
- **AND** `likeCount > 0` 时 MUST 在心形左侧展示数字；MUST NOT 展示「0」

#### Scenario: moment 卡其他区域进详情

- **WHEN** 用户点击 moment 卡正文、媒体或 meta 行左侧（非心形热区）
- **THEN** App SHALL 打开 `UcgPostDetailScreen`

### Requirement: Square debate cards SHALL vote inline

Debate full-width cards on 广场 MUST allow vote via `UcgDebateVsBar` without navigating to detail. Moment cards MUST navigate to detail on card tap per masonry rules.

辩论卡 MUST 就地投票；moment 卡 MUST 进详情。

#### Scenario: 辩论卡点击 VS 不跳详情

- **WHEN** 用户在辩论卡点击 VS 色带
- **THEN** App SHALL 提交投票
- **AND** MUST NOT push 详情页

#### Scenario: moment 卡点击进详情

- **WHEN** 用户点击 moment masonry 卡空白或媒体
- **THEN** App SHALL 打开 `UcgPostDetailScreen`

## REMOVED Requirements

### Requirement: Feed masonry cards SHALL display read-only like state without API calls

**Reason**: Product pivot — moment cards on 广场 now support inline toggle like on meta row; supersedes v2.0.3「Feed 卡片只读点赞展示」.

**Migration**: Implement meta-row like per MODIFIED requirements above; detail page like remains available.
