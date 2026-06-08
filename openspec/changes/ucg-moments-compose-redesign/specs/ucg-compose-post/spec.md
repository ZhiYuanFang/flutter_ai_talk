## MODIFIED Requirements

### Requirement: Compose SHALL support text with image or video limits

The compose screen SHALL allow: (a) text + up to 9 images, OR (b) text + 1 video with max duration 15 seconds and max size 20MB. User MUST NOT submit both multi-image set and video in one post. Media MUST be displayed in a 3×3 grid on the compose page. Images MUST support drag reorder; dragging to the bottom delete zone MUST remove the image and trigger orphan OSS delete. User MAY add more images from the compose page when in image mode (not video mode). User MUST NOT replace or newly select video from the compose page; changing video MUST require exiting without saving draft and re-entering via the shell entry sheet.

发布页必须支持：正文 + 最多 9 张图，或正文 + 1 条视频（≤15s、目标 20MB）；图片与视频互斥。媒体以 9 宫格展示；图片可拖拽排序，拖至底部删除区移除并删除 OSS。compose 页可继续添加图片，不得替换或新选视频。

#### Scenario: 超过 9 张图片
- **WHEN** 用户尝试选择或添加第 10 张图片
- **THEN** App SHALL 阻止并提示上限 9 张

#### Scenario: 视频超限
- **WHEN** 所选视频超过 15s 或超出客户端/服务端大小限制
- **THEN** App SHALL 拒绝上传并提示限制

#### Scenario: 9 宫格拖拽排序
- **WHEN** 用户在 compose 页长按图片并拖至另一格
- **THEN** App SHALL 更新图片顺序
- **AND** 发布请求中的 imageKeys 顺序 SHALL 与 UI 一致

#### Scenario: 拖至删除区移除图片
- **WHEN** 用户将图片拖至 compose 底部删除区
- **THEN** App SHALL 从网格移除该图
- **AND** App SHALL 调用 `POST /ucg/app/api/media/delete` 删除对应 objectKey（若服务端允许）

#### Scenario: compose 页不可换视频
- **WHEN** 用户已在 compose 页选定视频
- **THEN** App SHALL NOT 提供替换或新选视频的入口
- **AND** 用户 MUST 通过关闭且不保存草稿后从入口 sheet 重新选择视频

#### Scenario: compose 页继续添加图片
- **WHEN** 用户处于图片模式且图片数小于 9
- **THEN** App SHALL 允许从相册追加图片
- **AND** App SHALL NOT 同时提供视频选择

### Requirement: Compose SHALL persist and restore local drafts

The app SHALL save compose draft locally (text, selected objectKeys, media type) to SharedPreferences only via explicit user actions: exit dialog「保存草稿」、keyboard confirm bar「确定」on compose body, or successful publish clearing draft. The app MUST NOT auto-save draft in `dispose()`. On re-entry with existing draft, short-tap「+」SHALL skip the entry bottom sheet and open compose in full edit mode with draft restored. Long-press「+」SHALL open text-only compose mode (hide new media picker UI; existing draft media MAY display read-only with remove allowed).

客户端必须将草稿（正文、objectKeys、媒体类型）写入 SharedPreferences，且仅通过显式「保存草稿」、正文确认条「确定」或发布成功清除；不得在 `dispose()` 自动保存。有草稿时短按「+」须跳过入口 sheet 并恢复草稿；长按「+」须进入纯文字模式。

#### Scenario: 显式保存草稿
- **WHEN** 用户在有内容的 compose 页点击关闭且选择「保存草稿」
- **THEN** App SHALL 将当前正文与 media keys 写入 SharedPreferences
- **AND** OSS objectKey SHALL 保留

#### Scenario: 放弃草稿
- **WHEN** 用户在有内容的 compose 页选择「放弃」
- **THEN** App SHALL 清除 SharedPreferences 草稿
- **AND** App SHALL 调用 media delete API 清理本会话孤儿 OSS（服务端跳过已发帖引用）

#### Scenario: 空内容直接退出
- **WHEN** 用户关闭 compose 且 trim 后正文为空且无图片且无视频
- **THEN** App SHALL 直接退出，不展示对话框

#### Scenario: 有草稿短按加号
- **WHEN** 本地存在非空 compose 草稿且用户短按底部「+」
- **THEN** App SHALL 直接进入 compose 并恢复草稿
- **AND** App SHALL NOT 展示媒体来源 bottom sheet

#### Scenario: 长按纯文字模式
- **WHEN** 用户长按底部「+」
- **THEN** App SHALL 打开 compose 且隐藏新媒体选择 UI
- **AND** 若存在草稿则 SHALL 恢复正文；草稿内已有媒体可只读展示或移除，但不得新增媒体

#### Scenario: dispose 不自动保存
- **WHEN** compose 页面 widget 被 dispose（含系统杀进程前正常 dispose 路径）
- **THEN** App MUST NOT 写入 SharedPreferences 草稿

#### Scenario: 键盘确认条确定仍保存
- **WHEN** 用户在 `ucg.compose.body` 场景点击确认条「确定」
- **THEN** App SHALL 执行本地草稿持久化（与 `ucg-keyboard-input-enhancements` 一致）

#### Scenario: 失焦未确定不写本地草稿
- **WHEN** 用户在发布页编辑正文但未点「确定」即失焦
- **THEN** App SHALL soft-sync 至 controller
- **AND** App MUST NOT 触发 SharedPreferences 草稿持久化

### Requirement: Posting SHALL require login

Submitting a post MUST require logged-in session; unauthenticated users SHALL be redirected to login.

未登录用户发布帖子必须跳转登录。

#### Scenario: 未登录发帖
- **WHEN** 未登录用户尝试发布
- **THEN** App SHALL 跳转登录页

## ADDED Requirements

### Requirement: Compose page SHALL have body-only input without title field

The compose screen MUST provide a single editable body text field. The compose screen MUST NOT include a separate title field.

发布页仅提供可编辑正文，不得包含独立标题字段。

#### Scenario: 无标题字段
- **WHEN** 用户打开发布页
- **THEN** UI SHALL 仅展示正文输入区，无标题输入框

### Requirement: Compose exit dialog SHALL offer three explicit actions when content exists

When the user attempts to close compose with non-empty content, the app MUST show a dialog with exactly three actions: save draft (保存草稿), discard (放弃), and cancel (取消). Cancel MUST keep the user on compose.

有内容时关闭发布页必须展示「保存草稿 / 放弃 / 取消」三选项；取消须留在当前页。

#### Scenario: 取消关闭
- **WHEN** 用户在有内容时选择「取消」
- **THEN** App SHALL 关闭对话框且保持 compose 页打开

### Requirement: Compose SHALL expose AI polish when images are selected

The compose screen MUST show an「AI润笔」action only when at least one image is selected and no video-only mode applies. The action MUST NOT appear for text-only or video-only compose.

仅在有图片选中时显示「AI润笔」按钮；纯文字或纯视频模式不得显示。

#### Scenario: 有图显示润笔
- **WHEN** compose 页至少有一张已选图片且无视频
- **THEN** App SHALL 显示「AI润笔」按钮

#### Scenario: 无图隐藏润笔
- **WHEN** compose 页无图片或仅为视频
- **THEN** App SHALL NOT 显示「AI润笔」按钮

#### Scenario: 润笔更新正文
- **WHEN** 用户点击「AI润笔」且 API 成功
- **THEN** App SHALL 用返回的 polishedText 更新正文 controller
