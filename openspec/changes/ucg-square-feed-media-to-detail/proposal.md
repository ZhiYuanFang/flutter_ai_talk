# Proposal: 广场 Feed 媒体点击进详情

## Why

广场双列 masonry 卡片中，点击图片会打开全屏 lightbox、点击视频会内联播放，与「我的动态」及小红书式「点封面进笔记」不一致；用户期望在 Feed 点媒体直接进入帖子详情，在详情页再查看大图/播放视频。

## What Changes

- 广场 Feed 卡片内**图片**（含多图 `×N` 角标区域）点击 → `UcgPostDetailScreen`，**不再**打开 lightbox
- 广场 Feed 卡片内**视频**封面点击 → 详情页，**不再**在 Feed 内联播放
- Feed 视频封面使用轻量静态封面 + 播放图标（不在列表 init `VideoPlayerController`）
- 详情页内媒体仍保留 lightbox / 内联播放（行为不变）
- **BREAKING**（产品交互）：撤销 `ucg-square-detail-notifications-redesign` 中「广场图片 tap → lightbox」条款

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `ucg-square-feed`：广场 masonry 卡片媒体点击路由由 lightbox/内联播放改为进详情

## Impact

- `app/lib/ucg/ui/widgets/ucg_masonry_feed_card.dart`（主改动）
- 可选：`ucg_feed_moments_widgets.dart` 抽取轻量 video cover
- 规格 delta：`ucg-square-feed`；与 `ucg-feed-multi-image-badge` 角标点击场景对齐
