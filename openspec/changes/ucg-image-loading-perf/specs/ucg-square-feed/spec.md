## MODIFIED Requirements

### Requirement: 瀑布流 Masonry 卡片 MUST 展示客户端视频首帧封面

Masonry layout feed cards (`UcgMasonryFeedCard` and equivalent dual-column square feeds) SHALL display video post covers using the API-provided `media[].thumbnailUrl` (OSS `video/snapshot` still image) with a play icon overlay when the user has not started inline playback. The masonry card MUST NOT initialize `VideoPlayerController` solely to render a list-surface poster. When `thumbnailUrl` is missing, the client SHALL show a gradient placeholder with play icon and MUST NOT download the mp4 for poster extraction.

瀑布流双列 Feed 卡片在展示视频帖且用户尚未点击播放时，必须使用 API 返回的 `thumbnailUrl`（OSS 视频截帧静态图）作为封面，并叠加播放图标；不得仅为封面而初始化 `VideoPlayerController` 或拉取 mp4。无 `thumbnailUrl` 时展示渐变占位与播放图标。

#### Scenario: 瀑布流展示视频帖 snapshot 封面

- **WHEN** 用户在广场推荐瀑布流浏览含视频的帖子且尚未点击播放
- **THEN** 视频区域 SHALL 通过 `UcgNetworkImage`（或等价缓存组件）加载 `thumbnailUrl`
- **AND** MUST NOT 为封面调用 `VideoPlayerController.networkUrl` / `initialize()`
- **AND** 封面区域 SHALL 展示播放图标叠层

#### Scenario: 瀑布流视频点击不进内联播放

- **WHEN** 用户点击瀑布流视频帖卡片
- **THEN** App SHALL 导航至帖子详情（或既定详情路由）
- **AND** 瀑布流卡片内 MUST NOT 开始内联有声播放

#### Scenario: 瀑布流视频封面缺失时降级

- **WHEN** 视频帖 API 未提供 `thumbnailUrl`
- **THEN** 瀑布流 SHALL 展示渐变占位与播放图标
- **AND** MUST NOT 回退为拉取 mp4 提取首帧

#### Scenario: 瀑布流视频与朋友圈式 Feed 封面策略一致

- **WHEN** 同一视频帖在瀑布流与朋友圈式时间轴 Feed 中仅作封面展示（未播放）
- **THEN** 两者 MUST 使用相同的 API `thumbnailUrl` 静态封面策略
- **AND** MUST NOT 在列表表面单独保留 VideoPlayer 首帧 poster 路径
