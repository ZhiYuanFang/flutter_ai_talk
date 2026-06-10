## ADDED Requirements

### Requirement: Compose video preview SHALL prefer local first frame over CDN URL

When a compose video slot has a non-empty `localPath`, the client MUST render the preview using local first-frame thumbnail (`UcgLocalVideoThumb` / `UcgComposeLocalPreview`) regardless of whether `objectKey` is already populated from background upload. The client MUST NOT switch the preview widget to `UcgNetworkImage` using the video CDN URL when `localPath` is still available.

当 compose 视频槽存在 `localPath` 时，预览必须始终使用本地首帧，不得因后台上传完成而改用视频 CDN URL 的 `UcgNetworkImage`（避免闪烁与首帧丢失）。

#### Scenario: 后台上传完成后仍显示本地首帧
- **WHEN** 用户在 compose 或编辑帖模式选入本地视频且后台上传写入 `objectKey`
- **THEN** 视频卡片预览 SHALL 仍展示本地首帧缩略图
- **AND** UI SHALL NOT 因 objectKey 就绪而闪切网络图

#### Scenario: 仅远程视频槽
- **WHEN** 编辑帖加载的 video slot 仅有 `objectKey`、无 `localPath`
- **THEN** App SHALL 使用可渲染的远程预览（网络 poster 或占位 + 播放图标）
- **AND** SHALL NOT 假设视频 CDN URL 可直接作为 `Image.network` 源

## MODIFIED Requirements

### Requirement: Compose SHALL support text with image or video limits

The compose screen SHALL allow: (a) text + up to 9 images, OR (b) text + 1 video with max duration 15 seconds and max size 20MB. User MUST NOT submit both multi-image set and video in one post. Media MUST be displayed in a 3×3 grid on the compose page using local preview for pending slots and network preview for remote-only slots. Video MUST use a wide card (~16:9) with local first-frame preview and tap-to-fullscreen. Images MUST support drag reorder; dragging to the bottom delete zone MUST remove the image and trigger orphan OSS delete when upload completed. User MAY add more images from the compose page when in image mode. User MUST NOT replace or newly select video from the compose page. The compose screen MUST NOT display helper copy such as「更换视频请关闭并重新从发布入口选择」below the video card.

发布页须支持正文+最多9图或正文+单视频；九宫格须本地预览待上传媒体；视频为宽卡片本地首帧可点全屏；图片可拖拽排序与删除；compose 内可追加图片但不可换视频；**不得**展示「更换视频请关闭…」类提示文案。

#### Scenario: 超过 9 张图片
- **WHEN** 用户尝试选择或添加第 10 张图片
- **THEN** App SHALL 阻止并提示上限 9 张

#### Scenario: 视频超限
- **WHEN** 所选视频超过 15s 或超出客户端/服务端大小限制
- **THEN** App SHALL 拒绝入列并提示限制

#### Scenario: 9 宫格拖拽排序
- **WHEN** 用户在 compose 页长按图片并拖至另一格
- **THEN** App SHALL 更新 slot 顺序

#### Scenario: 视频卡片无更换提示
- **WHEN** 用户在 compose 页已选入视频
- **THEN** 视频卡片下方 SHALL NOT 展示「更换视频请关闭并重新从发布入口选择」或等价文案

#### Scenario: 编辑帖追加媒体
- **WHEN** 用户从详情进入编辑 compose 并追加本地图片或视频
- **THEN** 新媒体 SHALL 立即本地预览且后台上传
- **AND** 视频预览 SHALL 遵循本地首帧优先条款
