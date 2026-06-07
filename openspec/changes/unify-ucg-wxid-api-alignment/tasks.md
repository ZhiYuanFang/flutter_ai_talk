## 1. ApiClient 与 UcgApiClient 基础能力

- [x] 1.1 在 `ApiClient` 新增 `putJsonEnvelope`（`http.put`）与 `deleteEnvelope`（`http.delete`），复用 `_send` 401 刷新与信封解析（`ucg-api-contract`）
- [x] 1.2 修改 `UcgApiClient.put` / `delete` 委托真实 HTTP 方法，移除 POST 冒充（`ucg-api-contract`）
- [x] 1.3 对照 `go_ai_talk` ucg-service 路由表，整理 Flutter 与后端路径/方法对照清单（供联调验收）

## 2. Phase 1 — 推荐流与个人资料

- [x] 2.1 `fetchRecommendedFeed` 路径改为 `GET /feed/recommend`（`ucg-square-feed`）
- [x] 2.2 更新 `UcgPost.fromJson` / `UcgProfile.fromJson`：`wxId`/`userId`、`authorWxId`/`authorId`、`content`/`text` 双字段兼容（`ucg-api-contract`）
- [x] 2.3 `UcgPostStatus.fromApi` 支持整型 status 映射（对照 ucg-service 常量）（`ucg-square-feed`）
- [x] 2.4 `fetchProfile(wxId)` 支持 `withAuthorization: false` 用于他人主页匿名访问（`ucg-wxid-identity`）
- [ ] 2.5 手工验证：未登录推荐流可加载；已登录 `GET/PUT /profile/me` 正常（后端已修：`GetOrCreateMyProfile` 复用 `ValidateWx` 返回的 `babyName`，去掉冗余 `baby-name` 内调；`mergeProfileForAuthor` Redis 失败降级；device client 配置/鉴权错误信息可读）

## 3. Phase 2 — 发帖与媒体 presign

- [x] 3.1 对照 ucg-service 校正 `UcgPresignRequest` / `UcgPresignResult` 字段名（`ucg-compose-post`）
- [x] 3.2 `createPost` 请求体发送 `content` 字段（保留解析层 `text` 属性）（`ucg-compose-post`）
- [x] 3.3 我的动态列表展示整型 pending/rejected 状态文案（`ucg-compose-post`）
- [x] 3.4 手工验证：选图 → presign/网关上传 → 发帖端到端成功（展示 URL 使用 CDN `https://resorce.cuplay.top/...`；客户端优先 API `cdnUrl`，缺失时 `objectKeyToCdn` 回退；Web 预览/广场图用 `UcgNetworkImage` + `WebHtmlElementStrategy.prefer` 规避 CDN 无 CORS 时的 statusCode 0）
- [x] 3.5 发帖成功后广场与「我的动态」自动刷新（`ucgPostsChangedProvider`；pending 帖仅出现在「我的」，已发布帖出现在推荐流）（`ucg-square-feed` / `ucg-compose-post`）

## 4. Phase 3 — 互动、关注与会话 HTTP

- [x] 4.1 点赞 `POST`、取消赞 `DELETE`；关注 `POST`、取关 `DELETE`（`ucg-interactions`）
- [x] 4.2 评论请求体使用 `content`；删评路径改为 `DELETE /comments/{id}`（`ucg-interactions`）
- [x] 4.3 会话置顶改为 `PUT /conversations/{id}/pin`；删会话 `DELETE`（`ucg-chat-ui`）
- [x] 4.4 实现 `createConversation(peerWxId)` → `POST /conversations`（`ucg-chat-ui`）
- [ ] 4.5 手工验证：点赞/评论/关注/会话列表 CRUD

## 5. Phase 4 — WebSocket 帧与 gateway 代理

- [x] 5.1 对照 `go_ai_talk` gateway WS 代理与 ucg-service handler，确定 auth 首帧与 `send_message` canonical 字段
- [x] 5.2 更新 `UcgRepository.connectChatWs` / `sendChatWs` / `_onWsMessage` 使用 canonical 格式，保留入站别名宽容（`ucg-api-contract`）
- [ ] 5.3 联调 task 8.5：dev 环境验证 `wss://{apiBaseUrl host}/ucg/app/ws/chat` 端到端（auth → 收消息）
- [ ] 5.4 手工验证：两用户私信文本往返

## 6. Phase 5 — JWT sub→wxId 与 wxId=0 门控

- [x] 6.1 在 `token_expiry.dart` 新增 `readJwtWxId`，解析 JWT `sub`
- [x] 6.2 `ucg_providers.dart`：监听 `sessionProvider`，同步 `ucgCurrentUserIdProvider`；登出清空；「我的」已登录即用 `/profile/me` 或喂养宝宝昵称兜底，不再误展示「去登录」
- [x] 6.3 新增 `requireUcgWxAccount`（或扩展 `requireUcgLogin`）：`sub=0` 时展示「请先绑定微信账号后再使用社区功能」
- [x] 6.4 在发帖、互动、消息、关注入口应用 wxId 非零门控（`ucg-wxid-identity`）
- [ ] 6.5 手工验证：设备态 `sub=0` 可看推荐但不可发帖；绑微信后可发帖

## 7. 后端联调与部署（go_ai_talk，非 Flutter 必改项）

- [x] 7.1 确认 `UCG_SERVICE_BASE_URL` 与 gateway UCG 代理配置正确
- [x] 7.2 确认 JWT secret 跨 gateway / ucg-service 一致
- [x] 7.3 gateway 将 `GET /ucg/app/api/profile/{wxId}` 加入匿名白名单（若尚未配置）
- [x] 7.4 回归确认：喂养 `/device/app/api/*` 与 history WS 无影响
- [x] 7.5 gateway UCG 反代不得转发 OPTIONS：`/ucg/app/api/*` 预检由 `gateway_app_cors` 204 短路（修复 Web multipart 上传 CORS 预检 405）
- [x] 7.6 **昵称来源**：拒绝客户端本地把 API 返回的「家长」补成 `{babyName}的家长`；`ucg-service` 在 `GetOrCreateMyProfile` / `GetPublicProfile` 读 profile 时，若库内昵称为空或「家长」，经 `ValidateWx` 取 `babyName` 回写后再返回 DTO（评论作者 profile 经 `GetPublicProfile` 自动受益）。Flutter 已删除 `ucg_display_nickname.dart` 及评论/我的资料 enrich 逻辑。

## 8. 喂养安全区回归

- [x] 8.1 确认未修改 `RemoteFeedRepository`、`gateway_app_history_ws.go`、`device_no_notifier` 业务逻辑
- [ ] 8.2 手工回归：喂养首页历史同步、事件记录、WS 重连、登录刷新流程正常

## 10. 广场朋友圈式 Feed UI

- [x] 10.1 `UcgFeedCard` 图片九宫格：1 张 3/5 宽、2 张 2/3 宽、3 张满行、4–9 张三列方格（`ucg-square-feed`）
- [x] 10.2 视频竖屏 3/5 宽 / 横屏全宽；解析 `media.width/height`（`ucg-square-feed`）
- [x] 10.3 右下角「···」横向展开点赞/评论；灰底点赞摘要 + 评论预览与「展开」（`ucg-square-feed` / `ucg-interactions`）
- [x] 10.4 点赞名单：`GET /posts/{id}/likes` + 灰底块展示完整昵称（顿号分隔，`你` 表示当前用户）（`ucg-interactions` / `ucg-square-feed`）

## 9. 聊天多媒体与自动压缩

- [x] 9.1 新增 `ucg_media_limits.dart` / `ucg_media_compress.dart`：图片目标 10MB、视频 20MB、服务端硬上限 25MB（对齐 `MaxMediaUploadBytes`）
- [x] 9.2 发帖选图/选视频：`ucg_media_picker.dart` 上传前自动压缩（Web 视频不压缩，超限提示）
- [x] 9.3 聊天页附件：选图/视频 → presign/网关上传 → WS `message` 帧携带 `imageKey`/`videoKey`
- [x] 9.4 后端 ucg-service：`ChatMessage` 与 WS handler 支持 `imageKey`/`videoKey`/`mediaCdnUrl`（Green 审核可选）
- [ ] 9.5 手工验证：聊天图片/视频往返；超大图片自动压缩后发帖/私信成功

## 11. UCG UX 打磨（广场 / 我的 / 消息）

- [x] 11.1 评论弹层仅保留输入框发布评论，不展示历史评论列表（`ucg-square-feed` / `ucg-interactions`）
- [x] 11.2 点击 Feed 灰底评论 → 打开评论输入并预填 `@昵称 `；发布内容含 @ 标记（文本前缀，无 `replyToWxId` API）（`ucg-interactions`）
- [x] 11.3 点赞摘要展示完整点赞名单（`GET /posts/{id}/likes` 分页拉全；Wrap 展示无截断）（`ucg-square-feed`）
- [x] 11.4 点赞名单与评论作者昵称可点击 → `UcgUserProfileScreen(userId)`（`ucg-wxid-identity`）
- [x] 11.5 已点赞时再次点心形取消赞（`_toggleLike` + `UcgMomentsActionMenu` 复用同一回调）（`ucg-interactions`）
- [x] 11.6 我的页点头像 → 选图上传 → `PUT /profile/me` 更新 `avatarKey`（`ucg-profile`）
- [x] 11.7 我的页「我的动态 / 我的宝藏」顶部 TabBar 切换（`ucg-profile`）
- [x] 11.8 消息列表展示对方昵称（后端 `ConversationDTO.peerNickname`；客户端空昵称兜底）（`ucg-chat-ui`）
- [x] 11.9 关注用户后 `followingCount` 刷新（`ref.invalidate(ucgMyProfileProvider)`；后端 `ProfileDTO.followingCount`）（`ucg-profile`）
- [x] 11.10 移除独立「关注列表」行；点击关注数 stat chip → `UcgFollowListScreen`（`ucg-profile`）
- [x] 11.11 修复我的页 `postCount` 恒为 0（后端 `ProfileDTO.postCount`；客户端 `fetchMyPosts.total` 兜底）（`ucg-profile`）

## 12. UCG UX 回归修复（联调后）

- [x] 12.1 我的页点头像无反应：改用 `pickImage` 单图选择 + `InkWell` 点击反馈；失败 SnackBar（`ucg-profile`）
- [x] 12.2 `followingCount` 恒为 0：`UcgProfileRes` / `profileDTOToRes` 透出统计字段；客户端 `fetchFollowingList` 兜底（`ucg-profile`）
- [x] 12.3 他人主页已关注时展示「取消关注」：`GET /profile/{wxId}` 返回 `isFollowing`；取关 `DELETE /follow/{wxId}`（`ucg-interactions` / `ucg-profile`）
- [x] 12.4 评论灰底块自适应高度：1–5 条不预留空行；超过 5 条才展示展开/折叠（`ucg-square-feed`）
- [x] 12.5 点赞心形与昵称首行顶对齐：`Row`/`Wrap` 顶对齐 + 图标微调（`ucg-square-feed`）

## 13. 聊天窗口头像与标题

- [x] 13.1 聊天页消息气泡旁展示发送者头像（对方左、自己右；WeChat 风格）（`ucg-chat-ui`）
- [x] 13.2 聊天页 AppBar 标题展示对方昵称（`peerNickname` + profile 兜底，非 wxId 裸显）（`ucg-chat-ui`）
- [x] 13.3 会话缺头像/昵称时 `GET /profile/{peerWxId}` 补全（`ucg-chat-ui` / `ucg-profile`）

## 14. 聊天窗口顶栏布局（WeChat 风格）

- [x] 14.1 顶栏标题为对方头像 + 昵称左对齐（`titleWidget` Row：CircleAvatar + Expanded Text）（`ucg-chat-ui`）
- [x] 14.2 昵称超出可用宽度时尾部省略（`TextOverflow.ellipsis`）（`ucg-chat-ui`）
- [x] 14.3 头像与昵称尺寸与返回按钮行高一致（32dp 头像、17sp 标题字重）（`ucg-chat-ui`）
- [x] 14.4 移除副标题「一起聊聊育儿日常」，聊天顶栏不展示该文案（`ucg-chat-ui`）

## 15. 聊天窗口顶栏关注按钮

- [x] 15.1 聊天页顶栏右侧展示关注按钮：未关注「关注」、已关注「已关注」；点击切换 `POST/DELETE /follow/{wxId}`（`ucg-chat-ui` / `ucg-interactions`）
- [x] 15.2 进入聊天时经 `_ensurePeerProfile` 或会话 peer profile 读取 `isFollowing`（`GET /profile/{wxId}`）（`ucg-chat-ui`）
- [x] 15.3 关注/取关成功后刷新按钮态并 `ref.invalidate(ucgMyProfileProvider)` 更新「我的」`followingCount`（`ucg-profile`）
- [x] 15.4 `sub=0` 点击关注走 `requireUcgWxAccount` 门控；与自己会话不展示按钮（`ucg-wxid-identity`）

## 16. 我的主页优化（资料头图 + 主题色）

- [x] 16.1 「我的」Tab 顶栏移除标题「我的」与副标题「记录与分享你的育儿故事」（`ucg-profile`）
- [x] 16.2 资料头图左对齐头像；昵称在头像右上；下方关注数 pill chip（点击打开关注列表 §11.10）；再下方 IP 属地（`UcgProfile.ipLocation` / API `ipLocation`|`location`|`region`，缺失时展示「IP属地：未知`）（`ucg-profile`）
- [x] 16.3 他人主页 `UcgUserProfileScreen`：头像下方操作行「关注」+「私信」紧凑按钮（垂直 padding 3px）；未关注时关注实心主色、私信浅色 0.9；已关注时两按钮均为浅色 0.9（`ucg-profile` / `ucg-interactions`）
- [x] 16.4 我的 Tab（本人）：不展示关注/私信（§17.8 起改为内联编辑，移除「编辑资料」）（`ucg-profile`）
- [x] 16.5 UCG 模块消除硬编码色：新增 `ucg_theme.dart`，`ColorScheme` + `AppVisualTokens` 语义色替换 `Colors.*` / 固定 hex（`ucg-visual-system`）

## 17. IP 属地（网关解析）与资料/Feed UX

> **部署前 SQL（device DB `wx` + ucg DB `ucg_post`）：**
> ```sql
> ALTER TABLE wx ADD COLUMN ip_location VARCHAR(64) NULL COMMENT 'IP属地（网关解析）' AFTER platform;
> ALTER TABLE ucg_post ADD COLUMN ip_location VARCHAR(64) NULL COMMENT '发帖IP属地快照' AFTER content;
> ```
> 可选：配置 `IP2REGION_XDB_PATH` 或 `ucg.ip2regionXdbPath` 指向 ip2region `.xdb` 离线库。

- [x] 17.1 gateway-app：`gatewayapp.ClientIP` + `StripSpoofedInternalHeaders` + `InjectClientIPHeader`（`HookBeforeServe`）（`ucg-api-contract`）
- [x] 17.2 ucg-service：ip2region 离线解析 + `ResolveIPLocation`；`GET /profile/me` 节流更新 wx IP 属地（`ucg-profile`）
- [x] 17.3 device-service：`wx.ip_location` + `PUT /device/internal/api/ucg/wx/{wxId}/ip-location`；batch 透出 `ipLocation`（`ucg-api-contract`）
- [x] 17.4 ucg-service：`ucg_post.ip_location`；`CreatePost` 服务端快照；Feed/Post DTO 暴露 `ipLocation`（`ucg-square-feed` / `ucg-compose-post`）
- [x] 17.5 Flutter：`UcgPost.ipLocation` + `UcgFeedCard` 日期旁展示；profile 仅展示、不写 body（`ucg-square-feed` / `ucg-profile`）
- [x] 17.6 Flutter：`UcgRepository.deletePost` → `DELETE /posts/{id}`；我的动态列表删除 UI（`ucg-compose-post`）
- [x] 17.7 Flutter：移除「我的」`postCount` stat chip（`ucg-profile`）
- [x] 17.8 Flutter：昵称右上角内联编辑；移除「编辑资料」与 `UcgProfileEditScreen`（`ucg-profile`）
- [x] 17.9 Flutter：简介在头像行下方；空态「点击编辑个人简介」内联编辑（`ucg-profile`）
- [x] 17.10 Flutter：关注 chip 小字、无 pill 背景（`ucg-profile`）

## 18. 资料/Feed UX 微调（昵称编辑、审核角标、主题色）

- [x] 18.1 Flutter：昵称旁编辑图标紧贴昵称、与文字垂直居中（`ucg-profile` / `ucg_profile_header.dart`）
- [x] 18.2 Flutter：我的动态删除按钮与头像同行 Y 轴对齐；审核角标 35° 旋转叠于卡片左上角、半透明分态底色（`ucg-compose-post` / `ucg-square-feed`）
- [x] 18.3 Flutter：`buildAppTheme` 非 classicLight preset / 自定义背景时 primary 从 bundle 种子推导，修复 UCG 模块 accent 仍随性别粉色残留（`ucg-visual-system` / `app_theme_scope.dart`）

## 19. 我的动态刷新与审核角标微调

- [x] 19.1 Flutter：「我的动态」Tab 下拉刷新（`RefreshIndicator` + `ref.invalidate(ucgMyPostsProvider)`）（`ucg-compose-post` / `ucg-profile`）
- [x] 19.2 Flutter：审核角标改为 **-40°** 旋转、角带长度贴齐卡片顶边与左边（半透明 pending/rejected 分态底色保留）（`ucg-compose-post` / `ucg-square-feed`）

## 20. 审核角标位置修正（卡片级角旗）

- [x] 20.1 Flutter：审核角标移至 **卡片外层 Stack**（`Positioned` 对齐 `UcgShellGlassCard` 左上角）；**-40°** 角带以 `FractionalTranslation(-0.5,-0.5)` 中心对齐角点，呈电商角旗样式；保留 §18 半透明 pending/rejected 分态色（`ucg-compose-post` / `ucg-square-feed`）
- [x] 20.2 Flutter：角带 **贴齐卡片顶边与左边**（`Positioned(top:0,left:0)` + `Transform.rotate` 锚点 `Alignment.topLeft`）；移除外溢用的 `FractionalTranslation` 与内缩 inset；`UcgFeedCard` 外层 `ClipRRect` + `Stack(clipBehavior: hardEdge)` 按卡片圆角裁切角旗（`ucg-compose-post` / `ucg-square-feed`）

## 21. 审核角标与删除交互重做

- [x] 21.1 Flutter：移除对角线角旗 `UcgPostAuditBadgeOverlay`；pending/rejected 改为头像行右侧 **水平** 半透明角标（`UcgPostAuditBadge` + `showAuditBadge`）（`ucg-compose-post` / `ucg-square-feed`）
- [x] 21.2 Flutter：「我的动态」移除头像行删除按钮；每条帖子 `Dismissible` 左滑删除 + 确认对话框（`ucg-compose-post`）

## 22. 我的动态左滑删除区域收窄

- [x] 22.1 Flutter：「我的动态」左滑删除背景展示宽度上限为 **60** 逻辑像素（`UcgLimitedSlideAction` 替代全宽 `Dismissible.secondaryBackground`）（`ucg-compose-post`）

## 23. 我的动态左滑删除视觉与交互修正

- [x] 23.1 Flutter：左滑删除区域置于 `UcgShellGlassCard` 圆角裁切内，删除背景与卡片圆角对齐、无中间缝隙（`UcgLimitedSlideAction` + `_MyPostsSection`）（`ucg-compose-post`）
- [x] 23.2 Flutter：左滑仅展开 60px 删除按钮；须 **点击** 删除图标才弹出确认并调用 `DELETE /posts/{id}`，手势结束不触发删除（`UcgLimitedSlideAction.onDelete`）（`ucg-compose-post`）

## 24. 我的动态朋友圈式时间轴 UI

- [x] 24.1 Flutter：「我的动态」改为双列时间轴行（左：中文月/大号日/属地；右：正文 + 复用 `UcgPostMediaSection`）；无头像行、无 per-post 玻璃卡片（`ucg-profile` / `ucg-compose-post`）
- [x] 24.2 Flutter：帖子间细分割线；审核角标置于右列顶部；保留左滑 60px 点击删除与下拉刷新（`ucg-compose-post`）
- [x] 24.3 Flutter：抽取 `UcgPostMediaSection` 供 `UcgFeedCard` 与时间轴复用；主题色经 `ucg_theme.dart`（`ucg-square-feed` / `ucg-visual-system`）

## 25. Feed 点赞头像、我的动态样式与详情页

- [x] 25.1 Flutter：灰底互动块点赞名单改为头像网格（圆角 5、间距 2px、Wrap 换行）；点击头像跳转用户主页；`UcgLiker` 解析 `avatarKey`/`avatarUrl`（`ucg-square-feed` / `ucg-interactions`）
- [x] 25.2 Flutter：「我的动态」移除 per-post 背景色；分割线 1px 灰 0.7 仅右列；左列隐藏 IP 属地（`ucg-profile` / `ucg-compose-post`）
- [x] 25.3 Flutter：时间轴行点击打开 `UcgPostDetailScreen`（AppBar「详情」、复用 `UcgFeedCard`、右上角删除）；删除后 pop 并刷新列表（`ucg-compose-post` / `ucg-square-feed`）

## 26. 后端点赞名单头像字段

- [x] 26.1 ucg-service：`LikerDTO` 增加 `avatarKey`/`avatarUrl`；`ListPostLikes` 经 `GetPublicProfile` 填充（对齐帖子作者 enrichment）（`ucg-interactions`）
- [x] 26.2 ucg-service：`UcgLikerItem` 与 `likesPageToRes` 映射透出头像字段（`ucg-api-contract`）

## 27. 我的动态时间轴微调（去左滑、同日去重、时刻、分割线）

- [x] 27.1 Flutter：「我的动态」列表移除 `UcgLimitedSlideAction` 左滑删除；删除保留于详情页右上角（`ucg-compose-post`）
- [x] 27.2 Flutter：同日帖子左列日期去重——仅当日首条展示中文月/大号日，同日后续左列留空（`ucg-compose-post`）
- [x] 27.3 Flutter：每条动态正文/媒体下方展示 `HH:mm` 时刻（`ucg-compose-post`）
- [x] 27.4 Flutter：帖子间右列分割线降低对比度（opacity 约 0.35）（`ucg-compose-post`）

## 28. 我的动态分割线对比度与下拉刷新修复

- [x] 28.1 Flutter：帖子间右列分割线进一步降低对比度（opacity 约 0.18）（`ucg-compose-post` / `ucg_my_post_timeline_item.dart`）
- [x] 28.2 Flutter：「我的动态」下拉刷新可靠触发——`TabBarView` 禁用横向滑动手势、`CustomScrollView` + `AlwaysScrollableScrollPhysics` + `skipLoadingOnReload` + `ref.refresh(ucgMyPostsProvider.future)`（`ucg-compose-post` / `ucg-profile`）

## 29. Feed 互动菜单浮层重做

- [x] 29.1 Flutter：`UcgMomentsActionMenu`「···」按钮高度减半（32→16 逻辑 px），宽度/字号同比缩小（`ucg-square-feed`）
- [x] 29.2 Flutter：点击「···」后在左侧 **8px 间距** 处弹出 detached 浮层 pill（点赞/评论），不与「···」同 Material（`ucg-square-feed` / `ucg-interactions`）
- [x] 29.3 Flutter：全屏透明 barrier + 点外部任意处收起；浮层 `OverlayEntry` + `CompositedTransformFollower` 定位在卡片内容之上（`ucg-square-feed`）
- [x] 29.4 Flutter：修复 `UcgMomentsActionMenu` 浮层在滚动/导航卸载时 `_unmount` 崩溃——dispose 同步摘除 listener/动画/OverlayEntry，`markNeedsBuild` 仅对已挂载 entry，`rootOverlay: true`（`ucg-square-feed`）

## 30. Web 头像 CDN CORS 修复

- [x] 30.1 Flutter：新增 `UcgAvatar`（`ClipOval` + `UcgNetworkImage` + person 占位），禁止 `CircleAvatar.backgroundImage` 直载 CDN 头像（`ucg-square-feed` / `ucg-profile` / `ucg-chat-ui`）
- [x] 30.2 Flutter：广场作者头像、资料页头像、消息列表/聊天顶栏/气泡旁头像、点赞网格（已用 `UcgNetworkImage`）统一走安全组件；`ucgNetworkImageProvider` 文档注明勿用于 Decoration（`ucg-visual-system`）
- [x] 30.3 规格：`ucg-square-feed` 增加 Web CDN 头像加载 Scenario；客户端优先修复，CDN 侧 CORS 头为可选增强

## 31. Feed 点赞头像尺寸与心形对齐

- [x] 31.1 Flutter：灰底互动块点赞头像网格尺寸缩至原 28px 的 **2/3**（**19** 逻辑像素）；占位 person 图标同比缩小（`ucg-square-feed` / `ucg_feed_moments_widgets.dart`）
- [x] 31.2 Flutter：心形图标与首行点赞头像垂直居中对齐（`SizedBox(height: _kLikerAvatarSize)` + `Center`；多行网格时心形不随整块居中）（`ucg-square-feed`）

## 32. 聊天已读与未读角标清除

- [x] 32.1 Flutter：`UcgRepository.markConversationRead` → `POST /conversations/{id}/read`（可选 `lastMsgId`）（`ucg-chat-ui` / `ucg-api-contract`）
- [x] 32.2 Flutter：进入聊天页加载历史后标记已读；收到对方 WS 新消息时再次标记；`ucgUnreadCountProvider` 与消息列表项 `unreadCount` 同步清零（`ucg-chat-ui`）

## 33. 消息列表刷新与对方资料展示

- [x] 33.1 Flutter：离开 `UcgChatScreen`（任意入口：消息 Tab / 他人主页私信 / 广场）时 `bumpUcgConversationsRefresh`；进入消息 Tab 时再次刷新；`ucgConversationsProvider` 替代本地 `_load`（`ucg-chat-ui`）
- [x] 33.2 Flutter：会话列表缺 `peerNickname`/头像时 `enrichConversationsWithPeerProfiles`（与聊天页 `_ensurePeerProfile` 一致）（`ucg-chat-ui` / `ucg-profile`）
- [x] 33.3 后端：`UcgConversationItem` / `conversationDTOToItem` 透出 `peerNickname`、`peerAvatarKey`、`peerAvatarUrl`（`loadConversationDTO` 已 enrichment，此前 HTTP 层丢弃）（`ucg-api-contract` / `ucg-chat-ui`）

## 34. Feed 媒体交互

- [x] 34.1 Flutter：广场/详情 Feed 图片点击打开全屏 lightbox（`InteractiveViewer` + `UcgNetworkImage`）（`ucg-square-feed`）
- [x] 34.2 Flutter：视频缩略点击内联播放（`video_player`）（`ucg-square-feed`）
- [x] 34.3 Flutter：视频播放器全屏展开按钮（immersive `SystemChrome` + 全屏 Route）（`ucg-square-feed`）

## 35. 视频全屏点击与 Feed 首帧封面

- [x] 35.1 Flutter：全屏视频页点击画面区域切换暂停/播放；短暂 play/pause 图标反馈（`ucg-square-feed` / `ucg_media_viewer.dart`）
- [x] 35.2 Flutter：广场 Feed 视频帖展示首帧封面——无服务端 poster 时用 `VideoPlayerController` 懒加载、静音暂停于 t=0，滚出视口 dispose；`thumbnailUrl` 优先（`ucg-square-feed` / `ucg_feed_moments_widgets.dart`）

## 36. 全屏视频点击切换播放（Bugfix）

- [x] 36.1 Flutter：`VideoPlayer` 平台视图拦截触摸导致全屏页点击无响应——`IgnorePointer` 包裹播放器 + 顶层透明 `GestureDetector`（`HitTestBehavior.opaque`）；内联播放器同步修复（`ucg-square-feed` / `ucg_media_viewer.dart`）

## 37. 全屏图片/视频手势（下拉关闭与捏合缩放）

- [x] 37.1 Flutter：全屏 photo lightbox 与 video fullscreen 支持下拉关闭——垂直拖动时内容跟随手指（translate + fade/scale）；释放超过阈值则 pop，否则弹性回弹；与多图横向 PageView 不冲突（垂直主轴判定 + 拖动时禁用翻页）（`ucg-square-feed` / `ucg_media_viewer.dart`）
- [x] 37.2 Flutter：全屏图片/视频双指捏合缩放；手势结束动画回弹至 1.0（非持久缩放）；图片用 `InteractiveViewer` + `TransformationController`；视频 pinch 于画面区域；单击播放/暂停与拖动用位移阈值区分（`ucg-square-feed` / `ucg_media_viewer.dart`）

## 38. 全屏视频手势回归修复（§37 后）

- [x] 38.1 Flutter：修复全屏视频点击切换播放/暂停——`_UcgFullscreenDismissLayer` 与内层 `onScale*` 手势竞技场冲突；视频页改用统一 `onScale*`（单指 tap/dismiss、双指 pinch），移除嵌套 `GestureDetector`（`ucg-square-feed` / `ucg_media_viewer.dart`）
- [x] 38.2 Flutter：全屏视频下拉关闭从屏幕任意位置触发（`Positioned.fill` + `HitTestBehavior.opaque`）；双指捏合时若垂直位移主导仍可下拉关闭（`ucg-square-feed` / `ucg_media_viewer.dart`）

## 39. 全屏手势与视频加载回归修复（§37–38 后）

- [x] 39.1 Flutter：`_UcgFullscreenDismissLayer` 改用 `Listener` 指针跟踪实现下拉关闭与单击，避免与 `InteractiveViewer` / `ScaleGestureRecognizer` 手势竞技场冲突；双指捏合仍由独立 `onScale*` 处理（`ucg-square-feed` / `ucg_media_viewer.dart`）
- [x] 39.2 Flutter：Feed 视频封面 `VideoPlayerController` 并发初始化限制（`_UcgVideoInitLimiter` max 2）；修复 dispose 竞态与「初始化中点击播放」无响应；Web 跳过首帧封面预加载（CDN 无 CORS）（`ucg-square-feed` / `ucg_media_viewer.dart`）
- [x] 39.3 Flutter：`flutter analyze` 通过；全屏 photo/video 手势路径与视频加载路径逻辑复核（`ucg-square-feed`）

## 40. Feed 性能：列表缩略图、交互加载全分辨率

- [x] 40.1 Flutter：`UcgMediaUrl.thumbnailUrl` / `fullUrl`——API `thumbnailUrl`/`thumbKey` 优先，否则对 `resorce.cuplay.top` 追加 OSS `image/resize,w_400`；九宫格/时间轴用缩略图，lightbox 用全分辨率（`ucg-square-feed` / `ucg_models.dart` / `ucg_feed_moments_widgets.dart`）
- [x] 40.2 Flutter：Feed 视频封面仅用静态 poster（API thumb 或 OSS `video/snapshot`）；移除列表内 `VideoPlayerController` 首帧预加载与 `_initCover`；点击后才初始化播放（`ucg-square-feed` / `ucg_media_viewer.dart`）
- [x] 40.3 Flutter：`flutter analyze` 通过；记录 CDN OSS 处理策略（客户端优先，后端 thumb 字段可选增强）（`ucg-square-feed`）
