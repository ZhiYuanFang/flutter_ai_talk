## MODIFIED Requirements

### Requirement: Feed media SHALL support photo lightbox and inline video playback

Feed image grids (`UcgMomentsMediaGrid` / `UcgPostMediaSection`) and post detail SHALL open a fullscreen photo lightbox when the user taps a photo. The lightbox MUST use `UcgNetworkImage` (Web CORS-safe) and support pinch-zoom via `InteractiveViewer`. Pinch-zoom SHALL reset to identity scale (1.0) when the user releases the gesture — zoom MUST NOT persist after release. Multi-image posts SHALL allow swiping between images in the lightbox. The lightbox SHALL support pull-down-to-dismiss: vertical drag moves content with the finger (translate with optional fade/scale); release past threshold pops the route, otherwise springs back. Vertical dismiss MUST NOT conflict with horizontal gallery swipes (vertical-primary axis detection; disable page scroll while dismissing).

Video tiles (`UcgMomentsVideoTile`) SHALL start inline playback when tapped (not remain a static thumbnail). The inline player MUST expose play/pause, seek, and a **fullscreen expand** control. Fullscreen playback SHALL use a dedicated fullscreen route; on mobile, immersive system UI MAY be applied. Fullscreen video SHALL support pull-down-to-dismiss from **any** touch point on the screen (including letterbox regions and during two-finger pinch when vertical movement dominates). Pinch-zoom SHALL reset to identity scale (1.0) on release. Single-tap play/pause MUST remain distinguishable from drag gestures via a movement threshold; video fullscreen MUST use a unified scale gesture handler (1-finger tap/dismiss, 2-finger pinch) to avoid gesture-arena conflicts between dismiss and pinch layers. Client SHOULD document Web limitations: browser codec support and CDN cross-origin video fetch (unlike images, HTML `<img>` CORS workarounds do not apply to `video_player`).

Feed list image grids and timelines MUST load server-provided `thumbnailUrl` for image media only; Client MUST NOT fall back to client-side OSS `image/resize`. Feed video posters before playback MUST be obtained by the Flutter client extracting the first video frame locally (e.g. lazy `VideoPlayerController` initialized to t=0, muted and paused); Server MUST NOT supply video `thumbnailUrl` and Client MUST NOT use OSS `video/snapshot`. Feed author avatars and liker-grid avatars MUST use `avatarThumbnailUrl`, not full `avatarUrl`.

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

#### Scenario: Feed image grid uses server thumbnails
- **WHEN** 广场 Feed、我的动态时间轴或帖子详情展示图片九宫格
- **THEN** 列表/grid SHALL 加载 API 返回的 `thumbnailUrl`（服务端 OSS w_200）
- **AND** Client MUST NOT 自行拼接 `x-oss-process=image/resize`
- **AND** 用户点击图片打开 lightbox 时 SHALL 加载全分辨率 `cdnUrl`

#### Scenario: Feed video shows client first-frame poster
- **WHEN** 广场 Feed 展示含视频的帖子且用户尚未点击播放
- **THEN** App SHALL 在客户端本地提取视频首帧作为静态封面（可见 tile 懒加载、滚出视口释放）
- **AND** Server MUST NOT 返回视频 `thumbnailUrl`；Client MUST NOT 使用 OSS `video/snapshot`
- **AND** 用户点击后 SHALL 用完整 `cdnUrl` 初始化播放器并开始有声播放
- **AND** 首帧提取失败时 SHALL 回退渐变占位与播放按钮

#### Scenario: Feed author avatar uses thumbnail
- **WHEN** 广场 Feed 卡片或帖子详情展示作者头像
- **THEN** App SHALL 加载 `avatarThumbnailUrl`
- **AND** Client MUST NOT 在列表 surface 加载全分辨率 `avatarUrl`
