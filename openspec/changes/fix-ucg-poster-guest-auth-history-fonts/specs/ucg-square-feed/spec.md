## ADDED Requirements

### Requirement: 瀑布流 Masonry 卡片 MUST 展示客户端视频首帧封面

Masonry layout feed cards (`UcgMasonryFeedCard` and equivalent dual-column square feeds) SHALL display client-extracted first-frame video posters for video posts, consistent with `UcgMomentsVideoTile` / `UcgInlineVideoPlayer` poster behavior. The masonry card MUST NOT use a static placeholder-only video cover. 瀑布流双列 Feed 卡片在展示视频帖且用户尚未进入详情播放时，MUST 在客户端本地提取视频首帧作为封面；不得使用仅灰底加播放图标的静态 `_MasonryVideoCover` 占位；Server MUST NOT 提供视频 `thumbnailUrl`；Client MUST NOT 使用 OSS `video/snapshot`。

#### Scenario: 瀑布流展示视频帖首帧

- **WHEN** 用户在广场推荐瀑布流浏览含视频的帖子且尚未点击播放
- **THEN** 视频区域 SHALL 懒加载 `VideoPlayerController` 并展示 t=0 首帧
- **AND** 滚出视口时 MUST 释放 controller
- **AND** 首帧提取失败时 SHALL 回退渐变占位与播放图标

#### Scenario: 瀑布流视频点击不进内联播放

- **WHEN** 用户点击瀑布流视频帖卡片
- **THEN** App SHALL 导航至帖子详情（或既定详情路由）
- **AND** 瀑布流卡片内 MUST NOT 开始内联有声播放

#### Scenario: 瀑布流视频与朋友圈式 Feed 方案一致

- **WHEN** 同一视频帖在瀑布流与朋友圈式时间轴 Feed 中展示
- **THEN** 两者 MUST 使用相同的客户端首帧 poster 实现（共享 `UcgInlineVideoPlayer` 或等价组件）
- **AND** MUST NOT 在瀑布流单独保留静态封面组件
