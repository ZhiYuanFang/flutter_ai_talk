## MODIFIED Requirements

### Requirement: 广场 SHALL provide 关注 and 推荐 tabs with paginated feeds

The 广场 tab SHALL contain two sub-tabs: 关注 and 推荐. Each SHALL load paginated **mixed** post lists (moment and debate) via v1 APIs `GET /ucg/app/api/feed/recommend` and `GET /ucg/app/api/feed/following` without `type=debate` filter by default. Layout MUST use a **single-column vertical list** (`SliverList`): both moment and debate posts render full width in feed order; debate cards use `UcgDebateFeedCard`, moment cards use `UcgMasonryFeedCard`. Debate detection on client MUST use non-empty `debateLeft` AND `debateRight`, NOT `type`. Feed responses MUST NOT include inline `comments[]` preview. Sub-tab switching MUST comply with `ucg-visual-system` immersive layout.

广场 MUST 以 v1 混排纵向列表展示 moment 与辩论帖；Feed MUST NOT 附带评论预览。

#### Scenario: 推荐 Feed 分页加载

- **WHEN** 用户在推荐 Tab 滚动至列表底部
- **THEN** App SHALL 以 v1 cursor 请求下一页并 append
- **AND** MUST NOT 传 `type=debate` 作为唯一过滤

#### Scenario: 未登录浏览推荐

- **WHEN** 用户未登录并打开推荐 Tab
- **THEN** App SHALL 允许加载并展示混排 Feed

#### Scenario: 混排纵向列表布局

- **WHEN** Feed 同时含 moment 与辩论帖
- **THEN** App SHALL 在同一 `SliverList` 中按服务端顺序纵向排列
- **AND** moment 与 debate 卡片 MUST 各占全宽一行

#### Scenario: Feed 无评论预览

- **WHEN** App 解析推荐或关注 Feed 响应
- **THEN** 帖子项 MUST NOT 依赖 `comments[]` 字段展示论点
- **AND** 辩论论点 SHALL 仅在用户投票后由评论 API 加载

### Requirement: Square feed cards SHALL use light-surface containers

Feed cards for **non-debate** posts on 广场 SHALL wrap content in a light-surface container (`UcgSurfaceCard` or equivalent): solid low-contrast fill, `surfaceRadius` (~12 logical px), padding ~10, and NO `BackdropFilter`. **Debate** full-width cards SHALL use fake-glass panel per `ucg-feed-fake-glass` instead of `UcgSurfaceCard`.

moment 卡 MUST 轻表面；辩论全宽卡 MUST 假玻璃。

#### Scenario: moment 卡轻表面

- **WHEN** 用户在广场浏览 moment 帖
- **THEN** 卡片 SHALL 展示为轻表面矩形
- **AND** SHALL NOT 使用磨砂 blur

#### Scenario: 辩论全宽卡假玻璃

- **WHEN** 用户在广场浏览辩论帖
- **THEN** 全宽卡 SHALL 使用假玻璃 panel
- **AND** SHALL NOT 使用纯色 `UcgSurfaceCard` 作为外层容器

### Requirement: Feed media SHALL support photo lightbox and inline video playback

Feed cards on **广场** (moment and debate) MUST open fullscreen photo lightbox (`showUcgPhotoLightbox`) when the user taps image thumbnails in the 3-up preview row; taps MUST NOT navigate to detail for image taps. **Moment** cards: video preview tap MAY navigate to `UcgPostDetailScreen`; non-media card areas SHALL still navigate to detail. **Debate** cards: image lightbox only; VS bar and vote remain inline; video preview tap MUST NOT navigate to detail unless product adds explicit handler. **Profile** timeline (`UcgMyPostTimelineItem`): media taps (moment or debate) SHALL navigate to detail via row `InkWell`; MUST NOT open feed lightbox. Post detail retains existing media viewer rules.

广场图片 MUST lightbox；个人中心 MUST 点图进详情。

#### Scenario: 广场 moment 图片 lightbox

- **WHEN** 用户在广场 moment 卡点击预览图
- **THEN** App SHALL 打开 `showUcgPhotoLightbox`
- **AND** MUST NOT push 详情页

#### Scenario: 广场 moment 视频进详情

- **WHEN** 用户在广场 moment 卡点击视频封面
- **THEN** App SHALL 打开 `UcgPostDetailScreen`

#### Scenario: 广场辩论图片 lightbox

- **WHEN** 用户在广场辩论卡点击预览图
- **THEN** App SHALL 打开 lightbox
- **AND** MUST NOT 因点图跳转详情

#### Scenario: 个人中心点图进详情

- **WHEN** 用户在「我的动态」或他人主页时间轴点击 moment 或辩论帖媒体
- **THEN** App SHALL 打开 `UcgPostDetailScreen`
- **AND** MUST NOT 打开 lightbox

#### Scenario: 辩论卡展示媒体在 VS 条之上

- **WHEN** 辩论帖含 `media` 且左右标签均非空
- **THEN** 全宽卡 SHALL 在话题文案下方展示媒体
- **AND** SHALL 在媒体下方展示 `UcgDebateVsBar`

### Requirement: Square feed media preview SHALL cap at three images

Feed cards on 广场 (moment and debate) MUST show at most **3** image thumbnails in a horizontal row when `maxPreviewImages` is used. When the post has more than 3 images, the third cell MUST display an overflow badge `+N` where `N = totalImages - 3`. Video posts MUST show a single 16:9 preview tile. Distance MUST NOT overlay on media; distance belongs in the feed meta line only.

Feed 预览 MUST 最多 3 图；超出标 +N；距离仅在 meta 行。

#### Scenario: 五图帖展示 +2 角标

- **WHEN** 帖子含 5 张图片并在广场 Feed 渲染
- **THEN** App SHALL 展示前 3 张缩略图
- **AND** 第 3 张 MUST 显示角标 `+2`

#### Scenario: meta 行含时间与距离

- **WHEN** 帖子含 `ipLocationDisplay` 与可展示距离
- **THEN** Feed 卡 meta 行 SHALL 展示 `MM-dd HH:mm · {属地} · {距离}`（缺省字段省略）
- **AND** MUST NOT 在图片 overlay 上重复展示距离

## ADDED Requirements

### Requirement: Debate feed cards SHALL lazy-load arguments after vote

Debate full-width cards on 广场 MUST NOT request or render comment lists until the viewer has `myVoteSide` set (after successful vote or server-returned prior vote). After vote, the card SHALL fetch v1 comments and render `UcgDebateArgumentsBlock`. Cards MUST NOT auto-fetch comments based on `commentCount` alone on initial paint.

辩论卡 MUST 投票后才拉评论并展示论点。

#### Scenario: 未投票不展示论点

- **WHEN** 用户浏览辩论卡且 `myVoteSide` 为空
- **THEN** App SHALL NOT 调用评论列表 API
- **AND** SHALL NOT 渲染论点区块

#### Scenario: 投票后加载论点

- **WHEN** 用户在广场辩论卡投票成功
- **THEN** App SHALL 请求 v1 `GET /posts/{id}/comments`
- **AND** SHALL 展示论点列表

## REMOVED Requirements

### Requirement: Square feed debate cards SHALL use inline interaction without detail navigation

**Reason**: Superseded by mixed feed: moment cards navigate to detail; debate cards remain inline for vote but coexist with moment layout and lazy comments.

**Migration**: Implement mixed feed per MODIFIED requirements above; remove debate-only single-column assumption from pivot.

### Requirement: Square feed SHALL use dual-column StaggeredGrid masonry span weights

**Reason**: Product pivot to single-column vertical feed with full-width cards and 3-image preview row.

**Migration**: Replace `StaggeredGrid` with `SliverList`; remove `flutter_staggered_grid_view` dependency from App when unused.
