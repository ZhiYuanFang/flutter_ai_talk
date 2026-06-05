## ADDED Requirements

### Requirement: Compose SHALL support text with image or video limits

The compose screen SHALL allow: (a) text + up to 9 images, OR (b) text + 1 video with max duration 15 seconds and max size 20MB. User MUST NOT submit both multi-image set and video in one post.

#### Scenario: 超过 9 张图片
- **WHEN** 用户尝试选择第 10 张图片
- **THEN** App SHALL 阻止并提示上限 9 张

#### Scenario: 视频超限
- **WHEN** 所选视频超过 15s 或 20MB
- **THEN** App SHALL 拒绝上传并提示限制

### Requirement: Compose SHALL persist and restore local drafts

The app SHALL save compose draft locally (text, selected objectKeys or local paths, media type) and restore on re-entry until publish success or explicit discard. The same compose widget SHALL be reused when editing from 我的动态.

#### Scenario: 草稿恢复
- **WHEN** 用户上次未发布退出 compose 后再次进入
- **THEN** App SHALL 恢复上次草稿内容

#### Scenario: 从我的动态编辑
- **WHEN** 用户在「我的动态」点击编辑自己的帖子
- **THEN** App SHALL 打开同一 compose 流程并预填服务端数据

### Requirement: Posting SHALL require login

Submitting a post MUST require logged-in session; unauthenticated users SHALL be redirected to login.

#### Scenario: 未登录发帖
- **WHEN** 未登录用户尝试发布
- **THEN** App SHALL 跳转登录页
