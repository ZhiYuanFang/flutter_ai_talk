## MODIFIED Requirements

### Requirement: 广场 SHALL provide 关注 and 推荐 tabs with paginated feeds

The 广场 tab SHALL contain two sub-tabs: 关注 and 推荐. Each SHALL load paginated post lists using query parameters `page` and `pageSize` consistent with existing app APIs. 推荐 SHALL call `GET /ucg/app/api/feed/recommend`; 关注 SHALL call `GET /ucg/app/api/feed/following`. Cards SHALL use WeChat-moments style layout (avatar, nickname, text, media grid/video, time, interaction bar). Media grid SHALL follow Moments rules: 1 image at 3/5 card width; 2 images at 2/3 total width side-by-side; 3 images full-width row; 4–9 images in a 3-column square grid with small gaps. Video SHALL use 3/5 width when portrait (height > width) and full width when landscape. Interaction bar SHALL use a compact bottom-right「···」control (approximately half the prior touch height) that, when tapped, reveals a detached floating pill to its left with an 8 logical pixel gap containing like and comment actions; tapping outside anywhere SHALL dismiss the floating pill. Likes and comments preview SHALL appear inline below the post in a compact block with expand when truncated. Sub-tab switching MUST comply with `ucg-visual-system` immersive layout: inline segmented pills on `shellColor`, NOT a separated Material `TabBar` / contrasting header band.

#### Scenario: 推荐 Feed 分页加载
- **WHEN** 用户在推荐 Tab 滚动至列表底部
- **THEN** App SHALL 请求 `GET /feed/recommend` 下一页并 append 至列表

#### Scenario: 未登录浏览推荐
- **WHEN** 用户未登录并打开推荐 Tab
- **THEN** App SHALL 允许加载并展示推荐 Feed

### Requirement: Feed SHALL hide non-published posts from non-authors

Client SHALL only render posts with published status for other users' content. Author's own pending/rejected posts SHALL appear only in 我的动态, not in public feeds. Status MUST be parsed from ucg-service integer enum (e.g. `2` = published) per `ucg-api-contract`.

#### Scenario: 他人审核中帖子不可见
- **WHEN** 推荐 Feed 返回的数据不含他人 pending 帖
- **THEN** UI SHALL NOT 展示他人审核中内容

#### Scenario: 整型 status 已发布
- **WHEN** Feed 项 `status` 为整型 `2`
- **THEN** Client SHALL 视为已发布并在推荐/关注流展示（作者本人除外 pending/rejected 规则不变）

#### Scenario: 单图非全宽展示
- **WHEN** 帖子仅含 1 张图片
- **THEN** 图片区域宽度 SHALL 为卡片内容区宽度的 3/5，正方形缩略图

#### Scenario: 互动菜单展开
- **WHEN** 用户点击帖子右下角「···」
- **THEN** App SHALL 在「···」左侧以 detached 浮层 pill 展示点赞与评论按钮（与「···」按钮视觉分离、间距 8px）
- **AND** 用户点击浮层外任意区域 SHALL 收起该浮层

#### Scenario: 点赞头像网格
- **WHEN** 帖子 `likeCount > 0`
- **THEN** 灰底互动块 SHALL 懒加载 `GET /posts/{id}/likes` 并以头像网格展示点赞用户（圆角 5 方头像、约 19 逻辑像素边长即原 28px 的 2/3、间距 2px、超出宽度换行）
- **AND** 点击头像 SHALL 打开对应用户主页

#### Scenario: 评论块自适应高度
- **WHEN** 帖子评论数 ≤ 5
- **THEN** 灰底评论区 SHALL 按实际条数自适应高度，不预留五行空白

#### Scenario: 评论超过五条展开折叠
- **WHEN** 帖子评论数 > 5
- **THEN** 灰底块 SHALL 默认展示前 5 条并提供「展开」/「折叠」切换

#### Scenario: 点赞心形与首行头像垂直居中
- **WHEN** 点赞头像网格换行多行展示
- **THEN** 心形图标 SHALL 与首行点赞头像垂直居中对齐，而非相对整块网格垂直居中

### Requirement: Feed cards SHALL display post IP location snapshot

`UcgPostItem` and feed DTOs SHALL expose `ipLocation` (server snapshot at post creation). `UcgFeedCard` SHALL render IP location adjacent to post time (e.g. `MM-dd HH:mm · 广东 深圳`); when absent, time alone is sufficient. Client MUST NOT use device GPS or send `ipLocation` in requests.

#### Scenario: 帖子展示发帖属地
- **WHEN** Feed 项含非空 `ipLocation`
- **THEN** 卡片时间行 SHALL 在日期旁展示属地文案

### Requirement: UCG CDN images SHALL use CORS-safe Web loading

All remote images from UCG CDN (`https://resorce.cuplay.top/...`) SHALL load via `UcgNetworkImage` or `UcgAvatar` (which applies `WebHtmlElementStrategy.prefer` on Web). Feed media, liker avatar grids, and profile/chat/message avatars MUST NOT use `CircleAvatar` with `backgroundImage: NetworkImage` or raw `Image.network` without the Web HTML-element strategy. Client-side fix is preferred when CDN omits CORS headers; gateway/CDN `Access-Control-Allow-Origin` remains an optional server enhancement.

#### Scenario: Web avatar display without CDN CORS headers
- **WHEN** 用户在 Chrome Web 浏览含 CDN 头像的广场、资料、消息或点赞网格
- **THEN** App SHALL 通过 `UcgAvatar`/`UcgNetworkImage` 正常展示头像，不因 Same-Origin Policy 抛出图片解码错误

### Requirement: Feed media SHALL support photo lightbox and inline video playback

Feed image grids (`UcgMomentsMediaGrid` / `UcgPostMediaSection`) and post detail SHALL open a fullscreen photo lightbox when the user taps a photo. The lightbox MUST use `UcgNetworkImage` (Web CORS-safe) and support pinch-zoom via `InteractiveViewer`. Pinch-zoom SHALL reset to identity scale (1.0) when the user releases the gesture — zoom MUST NOT persist after release. Multi-image posts SHALL allow swiping between images in the lightbox. The lightbox SHALL support pull-down-to-dismiss: vertical drag moves content with the finger (translate with optional fade/scale); release past threshold pops the route, otherwise springs back. Vertical dismiss MUST NOT conflict with horizontal gallery swipes (vertical-primary axis detection; disable page scroll while dismissing).

Video tiles (`UcgMomentsVideoTile`) SHALL start inline playback when tapped (not remain a static thumbnail). The inline player MUST expose play/pause, seek, and a **fullscreen expand** control. Fullscreen playback SHALL use a dedicated fullscreen route; on mobile, immersive system UI MAY be applied. Fullscreen video SHALL support pull-down-to-dismiss from **any** touch point on the screen (including letterbox regions and during two-finger pinch when vertical movement dominates). Pinch-zoom SHALL reset to identity scale (1.0) on release. Single-tap play/pause MUST remain distinguishable from drag gestures via a movement threshold; video fullscreen MUST use a unified scale gesture handler (1-finger tap/dismiss, 2-finger pinch) to avoid gesture-arena conflicts between dismiss and pinch layers. Client SHOULD document Web limitations: browser codec support and CDN cross-origin video fetch (unlike images, HTML `<img>` CORS workarounds do not apply to `video_player`).

#### Scenario: Tap feed photo opens lightbox
- **WHEN** 用户在广场 Feed 或帖子详情点击九宫格中的图片
- **THEN** App SHALL 打开全屏 lightbox 展示该图，支持双指缩放；多图时可左右滑动切换
- **AND** 双指缩放松手后 SHALL 动画回弹至原始大小（1.0）

#### Scenario: Fullscreen photo pull-down dismiss
- **WHEN** 用户在全屏 lightbox 向下拖动图片（垂直位移主导于水平位移）
- **THEN** 图片 SHALL 跟随手指下移并淡出/微缩；释放超过阈值则关闭 lightbox，否则弹性回弹

#### Scenario: Fullscreen video pull-down dismiss
- **WHEN** 用户在全屏视频页自屏幕任意位置向下拖动（含黑边区域；双指捏合时若垂直位移主导于水平/缩放）
- **THEN** 视频画面 SHALL 跟随手指下移并淡出/微缩；释放超过阈值则退出全屏，否则弹性回弹

#### Scenario: Fullscreen video pinch zoom reset
- **WHEN** 用户在全屏视频页双指捏合缩放后松手
- **THEN** 画面 SHALL 动画回弹至原始大小（1.0），且单击画面仍可切换播放/暂停

#### Scenario: Tap feed video starts playback
- **WHEN** 用户点击帖子视频缩略区域
- **THEN** App SHALL 在同一卡片区域内开始内联播放，并展示播放控件

#### Scenario: Video fullscreen expand
- **WHEN** 用户在内联视频播放器点击全屏图标
- **THEN** App SHALL 进入全屏播放页；用户可通过退出全屏或系统返回关闭

#### Scenario: Fullscreen video tap toggles playback
- **WHEN** 用户在全屏视频页点击视频画面区域（非仅底部控件栏）
- **THEN** App SHALL 切换暂停/播放，并 MAY 短暂展示 play/pause 图标反馈

#### Scenario: Feed image grid uses thumbnails
- **WHEN** 广场 Feed、我的动态时间轴或帖子详情展示图片九宫格
- **THEN** 列表/grid SHALL 加载缩略图 URL（API `thumbnailUrl`/`thumbKey` 或 CDN OSS `image/resize,w_400`）
- **AND** 用户点击图片打开 lightbox 时 SHALL 加载全分辨率原图 URL

#### Scenario: Feed video shows static poster cover
- **WHEN** 广场 Feed 展示含视频的帖子且用户尚未点击播放
- **THEN** App SHALL 展示静态封面（优先 API `thumbnailUrl`/`thumbKey`，否则 CDN OSS `video/snapshot,t_0`）；MUST NOT 在列表内预加载 `VideoPlayerController`
- **AND** 用户点击后 SHALL 才初始化播放器并开始有声播放
- **AND** 封面加载失败时 SHALL 回退渐变占位与播放按钮
