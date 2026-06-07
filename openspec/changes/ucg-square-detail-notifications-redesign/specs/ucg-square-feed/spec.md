## MODIFIED Requirements

### Requirement: 广场 SHALL provide 关注 and 推荐 tabs with paginated feeds

The 广场 tab SHALL contain two sub-tabs **推荐** and **关注** placed at the **top header row** (inline segmented controls on `shellColor`, no contrasting TabBar band or tab background box). The page SHALL NOT display marketing title/subtitle above the tabs. Each sub-tab SHALL load paginated posts via `GET /feed/recommend` and `GET /feed/following`. The feed body SHALL use a **two-column masonry waterfall** layout (`MasonryGridView` or equivalent staggered grid), not a single-column WeChat Moments list.

Feed cards SHALL show: author avatar, nickname, **author bio (max 2 lines, ellipsis)**, post text, media, time/IP row, and a **bottom-right heart** for like/unlike with enlarged tap target (minimum ~44 logical pixels). Cards SHALL NOT show: inline liker avatar preview, bottom-right「···」menu, or inline comment preview block. Card tap (non-media, non-heart) SHALL navigate to `UcgPostDetailScreen`. Image tap on **广场 Feed** SHALL open photo lightbox per existing media viewer rules. Comments on feed surfaces SHALL only be reachable from the detail page.

#### Scenario: 推荐 Feed 分页加载
- **WHEN** 用户在推荐 Tab 滚动至列表底部
- **THEN** App SHALL 请求 `GET /feed/recommend` 下一页并 append 至 masonry 列表

#### Scenario: 未登录浏览推荐
- **WHEN** 用户未登录并打开推荐 Tab
- **THEN** App SHALL 允许加载并展示推荐 Feed

#### Scenario: 双列瀑布流
- **WHEN** 用户在广场查看推荐或关注 Feed
- **THEN** App SHALL 以两列不等高 masonry 卡片展示帖子

#### Scenario: 顶栏 Tab 无背景盒
- **WHEN** 用户打开广场 Tab
- **THEN** 推荐/关注切换 SHALL 为 inline segmented 样式且无独立 Tab 背景容器

#### Scenario: 卡片展示作者 bio
- **WHEN** Feed 项含非空 `authorBio`
- **THEN** 卡片昵称下方 SHALL 展示最多 2 行简介并省略超出部分

#### Scenario: 卡片点心形点赞
- **WHEN** 已登录用户点击卡片右下角心形
- **THEN** App SHALL 调用 like/unlike API 并更新 `likedByMe` 视觉态，且 SHALL NOT 打开详情页

#### Scenario: 卡片点击进详情
- **WHEN** 用户点击卡片非图片、非心形区域
- **THEN** App SHALL 打开 `UcgPostDetailScreen`

#### Scenario: 广场图片点开 lightbox
- **WHEN** 用户在广场 Feed 点击卡片内图片
- **THEN** App SHALL 打开全屏 lightbox（非仅进详情）

### Requirement: Feed media SHALL support photo lightbox and inline video playback

Feed masonry cards SHALL open fullscreen photo lightbox when the user taps a photo **on 广场 Feed**. Multi-image posts SHALL support swipe in lightbox; pinch-zoom reset rules unchanged. Video tiles on feed cards MAY use inline playback on tap or navigate to detail per product wiring; at minimum static poster until interaction. **我的动态** timeline SHALL NOT open lightbox on photo tap—it SHALL navigate to detail instead (see profile spec).

#### Scenario: Tap square feed photo opens lightbox
- **WHEN** 用户在广场双列 Feed 点击帖子图片
- **THEN** App SHALL 打开全屏 lightbox

#### Scenario: 我的动态图片进详情
- **WHEN** 用户在「我的动态」时间轴点击帖子图片
- **THEN** App SHALL 打开详情页且 SHALL NOT 打开 lightbox

## REMOVED Requirements

### Requirement: Feed engagement block SHALL show liker avatar grid on feed cards

**Reason**: 双列 Feed 卡片移除内联点赞预览，点赞者头像仅在详情页展示。

**Migration**: 点赞交互移至卡片心形与详情页点赞区；liker 列表仍通过 `GET /posts/{id}/likes` 在详情加载。

### Requirement: Inline comment preview and expand on feed cards

**Reason**: 评论仅在详情页展示，Feed 卡片不再内联评论块。

**Migration**: 用户通过点击卡片进入详情后查看/发表评论。
