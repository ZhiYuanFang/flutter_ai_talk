## ADDED Requirements

### Requirement: 客户端 MUST 支持 updatePost

`UcgRepository` SHALL implement `updatePost` calling `PUT /ucg/app/api/posts/{id}` with the same canonical body shape as `createPost` (`content`, `mediaType`, `media`, `submit`).

`UcgRepository` MUST 实现 `updatePost`，调用 `PUT /ucg/app/api/posts/{id}`，请求体字段与 `createPost` 一致（`content`、`mediaType`、`media`、`submit`）。

#### Scenario: 更新帖子正文与媒体

- **WHEN** 调用方传入 `postId`、新 `text` 与上传后的 `imageKeys`/`videoKey`
- **THEN** `updatePost` MUST 发送 PUT 请求并返回解析后的 `UcgPost`

#### Scenario: 更新失败错误透传

- **WHEN** 网关返回 4xx/5xx
- **THEN** `updatePost` MUST 抛出可展示错误，且 MUST NOT 静默成功

### Requirement: 帖子详情 MUST 提供作者编辑入口

For posts authored by the current user, the post detail screen SHALL show an Edit action to the left of Delete in `UcgMomentsActionMenu`, opening compose in edit mode with AppBar title「更新」.

作者查看自己的帖子详情时，操作区 MUST 在删除左侧提供「编辑」入口，打开 compose **编辑模式**，顶栏标题 MUST 为「更新」。

#### Scenario: 作者看到编辑按钮

- **WHEN** 当前用户为帖子作者且打开 `ucg_post_detail_screen`
- **THEN** `UcgMomentsActionMenu` MUST 展示「编辑」与「删除」，且编辑 MUST 位于删除左侧

#### Scenario: 编辑保存更新

- **WHEN** 作者在编辑模式修改正文或媒体并点击「更新」
- **THEN** App MUST 调用 `updatePost` 并在成功后返回详情或列表且 MUST 刷新帖子数据

#### Scenario: 非作者无编辑

- **WHEN** 当前用户非帖子作者
- **THEN** 详情页 MUST NOT 展示「编辑」入口
