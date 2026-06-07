## ADDED Requirements

### Requirement: createPost and presign SHALL use ucg-service canonical request fields

Posting flow MUST call `POST /ucg/app/api/media/presign` with field names expected by ucg-service, then `POST /ucg/app/api/posts` with body field `content` for text (plus `imageKeys` / `videoKey` as applicable). Response post `status` MUST be parsed as integer or string per `ucg-api-contract`.

#### Scenario: presign 后发帖
- **WHEN** 用户选择图片并完成 presign 上传
- **THEN** `POST /posts` body SHALL 含 `content` 与 `imageKeys`，且 SHALL NOT 仅发送非 canonical 字段名导致 4xx

#### Scenario: 超大媒体自动压缩
- **WHEN** 用户选择的图片或视频超过客户端目标大小（图片 10MB / 视频 20MB）
- **THEN** App SHALL 在后台压缩至服务端可接受范围（硬上限 25MB）后再上传，且 SHALL NOT 因原始文件过大直接失败（Web 视频除外：无压缩能力时提示用户选择更小文件）

#### Scenario: 审核中状态展示
- **WHEN** 发帖成功且 API 返回 `status: 1`（pending）
- **THEN** 我的动态 SHALL 展示审核中状态文案

#### Scenario: 审核状态水平角标
- **WHEN** 作者在「我的动态」查看 pending 或 rejected 帖子
- **THEN** 时间轴右列顶部 SHALL 展示 **水平** 半透明角标（pending / rejected 分态底色与描边），文案分别为「审核中」「已下架」
- **AND** SHALL NOT 使用对角线/旋转角旗叠于卡片左上角

#### Scenario: 我的动态朋友圈式时间轴
- **WHEN** 作者在「我的动态」Tab 浏览已发帖子列表
- **THEN** 每条帖子 SHALL 以双列行展示：左列中文月份与大号日期（**不**展示 IP 属地）；右列正文与媒体（九宫格/视频/单图复用广场组件）
- **AND** 同一自然日内仅列表中该日**首条**帖子左列展示月/日，同日后续帖子左列 SHALL 留空（不重复日期）
- **AND** 每条帖子正文/媒体下方 SHALL 展示当日时刻（`HH:mm` 24 小时制）
- **AND** SHALL NOT 展示头像行、per-post 玻璃 Feed 卡片样式或 per-post 背景色
- **AND** 相邻帖子间 SHALL 以 1px 极低对比度灰色（opacity 约 0.18）分割线分隔，且分割线仅覆盖右列内容区（不跨越左列日期列）

#### Scenario: 我的动态详情页
- **WHEN** 作者点击「我的动态」时间轴某条帖子
- **THEN** App SHALL 打开详情页（AppBar 标题「详情」），正文区复用 `UcgFeedCard` 完整样式（头像、正文、媒体、点赞、评论）
- **AND** pending/rejected 帖子 SHALL 在详情页展示水平审核角标
- **WHEN** 用户在详情页点击右上角删除并确认
- **THEN** App SHALL 调用 `DELETE /posts/{id}`、返回列表并刷新

#### Scenario: 我的动态下拉刷新
- **WHEN** 作者在「我的动态」Tab 下拉列表（含内容不足一屏、Web 与移动端）
- **THEN** App SHALL 通过 `RefreshIndicator` 包裹 `CustomScrollView`（`AlwaysScrollableScrollPhysics`）可靠触发下拉手势
- **AND** `TabBarView` SHALL 使用 `NeverScrollableScrollPhysics` 避免横向滑动手势抢占纵向下拉
- **AND** 刷新 SHALL 调用 `ref.refresh(ucgMyPostsProvider.future)` 并保留已有列表直至新数据返回（`skipLoadingOnReload`）

#### Scenario: 违规下架原因
- **WHEN** rejected 帖子含 `rejectReason`
- **THEN** 角标 SHALL 展示「已下架」，原因文案 SHALL 展示于头像行下方正文区

## MODIFIED Requirements

### Requirement: Posting SHALL require login

Submitting a post MUST require logged-in session with non-zero wxId per `ucg-wxid-identity`; device-only `sub=0` SHALL show bind-wechat message. Unauthenticated users SHALL be redirected to login.

#### Scenario: 未登录发帖
- **WHEN** 未登录用户尝试发布
- **THEN** App SHALL 跳转登录页

#### Scenario: 设备态 wxId 为零发帖
- **WHEN** 已设备登录但 `sub=0` 用户尝试发布
- **THEN** App SHALL 展示绑定微信提示，且 SHALL NOT 调用发帖 API

### Requirement: Authors SHALL delete own posts from 我的动态

`DELETE /ucg/app/api/posts/{id}` SHALL remove the author's post. 我的动态 list SHALL NOT offer inline swipe delete; delete SHALL be available from post detail screen with confirmation; success SHALL refresh the list.

#### Scenario: 删除我的动态
- **WHEN** 作者在「我的动态」详情页点击右上角删除并确认
- **THEN** App SHALL 调用 `DELETE /posts/{id}`、返回列表并刷新

### Requirement: CreatePost SHALL snapshot ip_location server-side

`POST /posts` SHALL NOT accept client `ipLocation`. ucg-service SHALL resolve `X-Internal-Client-IP` at create time and persist `ucg_post.ip_location` as an immutable snapshot for feed display.

#### Scenario: 发帖属地服务端快照
- **WHEN** 用户发帖且网关注入有效客户端 IP
- **THEN** 新帖 `ipLocation` SHALL 由服务端写入，请求 body SHALL NOT 含 `ipLocation`
