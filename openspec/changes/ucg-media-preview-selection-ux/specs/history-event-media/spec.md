## MODIFIED Requirements

### Requirement: History edit media strip SHALL support tap-to-preview

`HistoryEventMediaStrip` MUST open fullscreen preview when the user taps the thumbnail center: images via pinch lightbox, videos via fullscreen player. Long-press drag reorder and top-right remove MUST remain unchanged.

历史编辑媒体条带点击缩略图中间须放大预览（图片 lightbox、视频全屏），长按排序与右上角删除行为不变。

#### Scenario: 点击图片放大
- **WHEN** 用户在历史编辑 sheet 点击图片缩略图中间
- **THEN** App SHALL 打开全屏图片 lightbox

#### Scenario: 点击视频全屏
- **WHEN** 用户点击本地或远程视频缩略图中间
- **THEN** App SHALL 打开全屏视频播放器
