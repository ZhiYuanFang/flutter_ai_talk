## ADDED Requirements

### Requirement: Square feed debate cards SHALL use inline interaction without detail navigation

Debate cards on 广场 MUST render topic text, `UcgDebateVsBar` (`interactive=true`), inline arguments (comments), and argument composer entry WITHOUT navigating to `UcgPostDetailScreen` when the user taps the card body, VS bar, or argument area. Avatar tap MUST still open `UcgUserProfileScreen`. Debate cards MUST NOT render media grids or like controls.

广场辩论卡 MUST 就地投票与论点互动，整卡 MUST NOT 跳详情；MUST NOT 展示媒体与点赞。

#### Scenario: 点击卡片正文不跳详情

- **WHEN** 用户在广场辩论卡点击话题正文或 VS 条

- **THEN** App MUST NOT push `UcgPostDetailScreen`

#### Scenario: 广场内联论点超过五条可展开

- **WHEN** 辩论帖评论数大于 5

- **THEN** 卡片 SHALL 默认展示前 5 条论点
- **AND** SHALL 提供「展开 N 条论点」就地展开剩余评论

## MODIFIED Requirements

### Requirement: 广场 SHALL provide 关注 and 推荐 tabs with paginated feeds

The 广场 tab SHALL contain two sub-tabs: 关注 and 推荐. Each SHALL load paginated **debate** post lists using query parameters `page`, `pageSize`, and `type=debate`. Cards SHALL use debate layout (avatar, nickname, force tier icon, topic text, `UcgDebateVsBar`, time, inline arguments). Sub-tab switching MUST comply with `ucg-visual-system` immersive layout: inline segmented pills on `shellColor`, NOT a separated Material `TabBar` / contrasting header band.

广场关注/推荐 Tab MUST 分页加载 `type=debate` 列表；卡片为辩论布局而非朋友圈媒体布局。

#### Scenario: 推荐 Feed 分页加载

- **WHEN** 用户在推荐 Tab 滚动至列表底部

- **THEN** App SHALL 请求下一页 `type=debate` 并 append 至列表

#### Scenario: 未登录浏览推荐

- **WHEN** 用户未登录并打开推荐 Tab

- **THEN** App SHALL 允许加载并展示推荐辩论 Feed

### Requirement: Feed media SHALL support photo lightbox and inline video playback

Feed masonry cards on **广场 Feed** SHALL NOT open fullscreen photo lightbox or inline video playback for **debate** posts (debate posts have no media). For **moment** posts shown only on profile timelines, taps on media MAY navigate to detail per profile rules. **Post detail** and chat surfaces MAY retain existing media viewer rules for moment posts.

广场辩论帖无媒体；moment 仅在非广场面展示媒体规则。

#### Scenario: 广场辩论卡无媒体点击

- **WHEN** 用户在广场浏览 `type=debate` 卡片

- **THEN** App MUST NOT 展示图片或视频区域
- **AND** MUST NOT 打开 lightbox 或内联播放

#### Scenario: Tap square feed video opens detail

- **WHEN** 用户在**非广场**面（如历史 moment 详情入口）点击 moment 视频封面

- **THEN** App MAY 打开 `UcgPostDetailScreen` 按 moment 规则处理

### Requirement: Square feed masonry cards SHALL use light-surface containers

Masonry feed cards on 广场 SHALL wrap **debate** content in a light-surface container (`UcgSurfaceCard` or equivalent): solid low-contrast fill from `AppVisualTokens`, `surfaceRadius` (~12 logical px), padding ~10, and NO `BackdropFilter`, NO gradient glass, NO panel shadow. Cards SHALL contain topic + VS bar + optional inline arguments instead of media cover.

广场双列卡片 MUST 轻表面容器包裹辩论内容（话题+VS 条+论点）。

#### Scenario: 双列卡片轻表面

- **WHEN** 用户在广场推荐或关注 Feed 浏览辩论帖

- **THEN** 每张 masonry 卡片 SHALL 展示为轻表面矩形（可读边界），且 SHALL NOT 使用磨砂 blur 或渐变描边阴影

#### Scenario: 卡片交互为就地投票

- **WHEN** 用户与广场辩论卡 VS 条交互

- **THEN** 行为 SHALL 触发 vote API 且 MUST NOT 导航至详情
