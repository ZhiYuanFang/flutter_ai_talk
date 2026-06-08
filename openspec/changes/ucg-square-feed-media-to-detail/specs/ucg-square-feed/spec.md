## MODIFIED Requirements

### Requirement: 广场 SHALL provide 关注 and 推荐 tabs with paginated feeds

The 广场 tab SHALL contain two sub-tabs **推荐** and **关注** placed at the **top header row** (inline segmented controls on `shellColor`, no contrasting TabBar band or tab background box). The page SHALL NOT display marketing title/subtitle above the tabs. Each sub-tab SHALL load paginated posts via `GET /feed/recommend` and `GET /feed/following`. The feed body SHALL use a **two-column masonry waterfall** layout (`MasonryGridView` or equivalent staggered grid), not a single-column WeChat Moments list.

Feed cards SHALL show: author avatar, nickname, **author bio (max 2 lines, ellipsis)**, post text, media, time/IP row, and a **bottom-right heart** for like/unlike with enlarged tap target (minimum ~44 logical pixels). Cards SHALL NOT show: inline liker avatar preview, bottom-right「···」menu, or inline comment preview block. Card tap (including **image and video media areas**, and non-heart non-avatar areas) SHALL navigate to `UcgPostDetailScreen`. Image tap on **广场 Feed** SHALL NOT open photo lightbox. Comments on feed surfaces SHALL only be reachable from the detail page.

#### Scenario: 卡片点击进详情

- **WHEN** 用户点击广场 Feed 卡片内图片、视频封面、文字或空白区域（非头像、非心形）
- **THEN** App SHALL 打开 `UcgPostDetailScreen`

#### Scenario: 广场图片不进 lightbox

- **WHEN** 用户在广场 Feed 点击卡片内图片（含多图 `×N` 角标区域）
- **THEN** App SHALL 打开详情页且 SHALL NOT 打开全屏 lightbox

#### Scenario: 广场视频不进内联播放

- **WHEN** 用户在广场 Feed 点击卡片内视频封面
- **THEN** App SHALL 打开详情页且 SHALL NOT 在 Feed 内启动内联视频播放

### Requirement: Feed media SHALL support photo lightbox and inline video playback

Feed masonry cards on **广场 Feed** SHALL NOT open fullscreen photo lightbox or inline video playback when the user taps media; taps SHALL navigate to `UcgPostDetailScreen` instead. **Post detail** and other surfaces (e.g. chat) MAY still open lightbox on photo tap and inline/fullscreen video per existing media viewer rules. **我的动态** timeline SHALL NOT open lightbox on photo tap—it SHALL navigate to detail instead (see profile spec).

#### Scenario: Tap square feed photo opens detail

- **WHEN** 用户在广场双列 Feed 点击帖子图片
- **THEN** App SHALL 打开 `UcgPostDetailScreen` 且 SHALL NOT 打开 lightbox

#### Scenario: Tap square feed video opens detail

- **WHEN** 用户在广场双列 Feed 点击帖子视频封面
- **THEN** App SHALL 打开 `UcgPostDetailScreen` 且 SHALL NOT 在 Feed 内联播放

#### Scenario: 我的动态图片进详情

- **WHEN** 用户在「我的动态」时间轴点击帖子图片
- **THEN** App SHALL 打开详情页且 SHALL NOT 打开 lightbox

### Requirement: Square feed masonry cards SHALL show multi-image count badge on cover

When a post on 广场 masonry Feed has more than one image, the cover thumbnail SHALL display a bottom-right badge with text `×N` where N is the total image count (`imageUrls.length`). The badge SHALL use a semi-transparent dark rounded pill background and light foreground text so it remains readable on varied image backgrounds. Single-image and video posts SHALL NOT show the badge. Tapping the cover (including the badge area) SHALL navigate to `UcgPostDetailScreen` (not lightbox).

#### Scenario: 角标区域进详情

- **WHEN** 用户点击含多图角标的封面
- **THEN** App SHALL 打开 `UcgPostDetailScreen` 且 SHALL NOT 打开 lightbox
