## ADDED Requirements

### Requirement: Compose media SHALL preview locally and upload in background

The compose screen MUST display selected media using local thumbnails (`Image.file` or equivalent) immediately after selection. The app MUST start OSS upload for each new local slot in the background without blocking further editing. The app MUST NOT show full-screen upload overlays, grid add-tile spinners, or inline「上传中…」copy for background upload progress.

发布页须在选入媒体后立即以本地缩略图展示；每条新媒体须在后台静默上传 OSS；不得用全屏遮罩、九宫格「+」转圈或「上传中…」文案提示后台进度。

#### Scenario: 选图后立即本地展示
- **WHEN** 用户从相册或拍摄选入图片
- **THEN** compose 九宫格 SHALL 在 1 秒内展示本地缩略图
- **AND** 用户 SHALL 可继续编辑正文或追加图片

#### Scenario: 后台上传不阻塞发表按钮
- **WHEN** 后台仍有媒体上传进行中
- **THEN** 「发表」按钮 SHALL 保持可点击（除非正在发表或润笔）
- **AND** App SHALL NOT 因后台上传禁用正文编辑

#### Scenario: 发表前等待未完成上传
- **WHEN** 用户点击「发表」且存在未完成上传的本地媒体
- **THEN** 「发表」按钮内 SHALL 显示 `CircularProgressIndicator`
- **AND** App SHALL await 全部媒体上传完成后调用 `createPost` 或 `updatePost`

#### Scenario: 上传失败阻止发表
- **WHEN** 发表前等待上传时某条媒体上传失败且重试仍失败
- **THEN** App SHALL 停止发表按钮 loading
- **AND** App SHALL 展示可读错误提示且不得调用发帖 API

### Requirement: Save draft SHALL await media upload before persisting keys

When the user chooses「保存草稿」from the compose exit dialog, the app MUST show an in-button loading indicator on the save-draft action, await all pending uploads, then persist draft `imageKeys`/`videoKey` to SharedPreferences. The app MUST NOT persist draft with missing objectKeys for local-only slots.

用户选择「保存草稿」时，保存按钮内须转圈并等待全部媒体上传完成，再将 objectKeys 写入草稿；不得写入未上传完成的本地槽位。

#### Scenario: 保存草稿等待上传
- **WHEN** 用户在有本地未上传完成的媒体时选择「保存草稿」
- **THEN** 「保存草稿」按钮内 SHALL 显示 loading
- **AND** 草稿 SHALL 在所有上传成功后写入 objectKeys

#### Scenario: 保存草稿失败
- **WHEN** 等待上传时发生失败
- **THEN** App SHALL 保持 compose 打开
- **AND** App SHALL NOT 写入不完整草稿

### Requirement: New post publish success SHALL signal shell to open profile tab

On successful `createPost` (not edit mode), compose MUST `Navigator.pop` with a result indicating new post published. `UcgShell` MUST switch bottom navigation to「我的」and rely on `ucgPostsChangedProvider` to refresh the owner's post list.

新帖 `createPost` 成功后须向 shell 返回「已发表新帖」结果；shell 须切换至「我的」并刷新动态列表。

#### Scenario: 新帖发表跳转我的
- **WHEN** 用户从底栏「+」发表新帖成功
- **THEN** App SHALL 关闭 compose
- **AND** 底栏 SHALL 选中「我的」
- **AND** 我的动态列表 SHALL 包含新帖（首屏刷新）

#### Scenario: 编辑帖发表不切换 Tab
- **WHEN** 用户从帖子详情进入编辑模式并 `updatePost` 成功
- **THEN** App SHALL pop 回详情或原页面
- **AND** App MUST NOT 切换底栏至「我的」

## MODIFIED Requirements

### Requirement: Compose SHALL support text with image or video limits

The compose screen SHALL allow: (a) text + up to 9 images, OR (b) text + 1 video with max duration 15 seconds and max size 20MB. User MUST NOT submit both multi-image set and video in one post. Media MUST be displayed in a 3×3 grid on the compose page using local preview for pending slots and network preview for remote-only slots. Images MUST support drag reorder; dragging to the bottom delete zone MUST remove the image and trigger orphan OSS delete when upload completed. User MAY add more images from the compose page when in image mode. User MUST NOT replace or newly select video from the compose page.

发布页须支持正文+最多9图或正文+单视频；九宫格须本地预览待上传媒体；图片可拖拽排序与删除；compose 内可追加图片但不可换视频。

#### Scenario: 超过 9 张图片
- **WHEN** 用户尝试选择或添加第 10 张图片
- **THEN** App SHALL 阻止并提示上限 9 张

#### Scenario: 视频超限
- **WHEN** 所选视频超过 15s 或超出客户端/服务端大小限制
- **THEN** App SHALL 拒绝入列并提示限制

#### Scenario: 9 宫格拖拽排序
- **WHEN** 用户在 compose 页长按图片并拖至另一格
- **THEN** App SHALL 更新 slot 顺序
- **AND** 发帖请求中的 imageKeys 顺序 SHALL 与 UI 一致

#### Scenario: 拖至删除区移除图片
- **WHEN** 用户将图片拖至 compose 底部删除区
- **THEN** App SHALL 从网格移除该 slot
- **AND** 若该 slot 已上传完成 App SHALL 调用 media delete API

#### Scenario: compose 页继续添加图片
- **WHEN** 用户处于图片模式且图片数小于 9
- **THEN** App SHALL 允许从相册追加图片且不得阻塞选图 UI 上传转圈
