## ADDED Requirements

### Requirement: Square feed masonry cards SHALL show multi-image count badge on cover

When a post on 广场 masonry Feed has more than one image, the cover thumbnail SHALL display a bottom-right badge with text `×N` where N is the total image count (`imageUrls.length`). The badge SHALL use a semi-transparent dark rounded pill background and light foreground text so it remains readable on varied image backgrounds. Single-image and video posts SHALL NOT show the badge. Tapping the cover (including the badge area) SHALL still open the photo lightbox unchanged.

广场双列 Feed 多图帖封面右下角 SHALL 展示 `×N` 角标（N 为图片总张数）；角标 SHALL 带半透明深色圆角底以保证可读性。

#### Scenario: 多图帖展示角标
- **WHEN** 用户在广场 Feed 浏览含 2 张及以上图片的帖子
- **THEN** 卡片封面右下角 SHALL 显示 `×N`（N 等于图片总张数）

#### Scenario: 单图帖不展示角标
- **WHEN** 帖子仅含 1 张图片
- **THEN** 封面 SHALL NOT 显示多图角标

#### Scenario: 角标不影响 lightbox
- **WHEN** 用户点击含多图角标的封面
- **THEN** App SHALL 打开全屏 lightbox 且支持多图滑动，行为与角标添加前一致
