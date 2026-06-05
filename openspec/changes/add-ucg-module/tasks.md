## 1. 配置与模块骨架

- [x] 1.1 新增 `app/lib/ucg/` 目录结构（data/providers/ui/widgets）
- [x] 1.2 在 `AppEnv` 增加 `wsUcgChatUrl` / `wsUcgChatUrlEffective`（参考 `wsHistoryUrl` / `wsHistoryUrlEffective` 模式；默认路径 `/ucg/app/ws/chat`）
- [x] 1.3 新增 `UcgApiClient` 或扩展 `ApiClient`，base path `/ucg/app/api`，分页 `page`/`pageSize`
- [x] 1.4 新增 `UcgMediaUrl.objectKeyToCdn`  helper（`ucg-media-cdn`）

## 2. Phase 2 — UCG 壳与入口（ucg-home-entry / ucg-shell-navigation / ucg-visual-system）

- [x] 2.1 实现 `UcgHomeShell`：PageView page0=`HomeScreen`、page1=UCG 壳，`AutomaticKeepAliveClientMixin`
- [x] 2.2 修改 `app_router.dart` `/home` builder 指向 `UcgHomeShell`
- [x] 2.3 实现右侧「进入广场」可展开拉条，仅 page0 显示，点击 `animateTo(1)`（玻璃/主题色与 `HomeInputModeDock` 一致）
- [x] 2.4 实现 UCG 五栏**玻璃悬浮 dock** 底部导航 + IndexedStack（广场/宝藏/+/消息/我的）；禁止默认 `BottomNavigationBar` 纯色条
- [x] 2.5 宝藏 Tab 与「我的宝藏」占位文案「尚未开通」
- [x] 2.6 抽取 UCG 共用视觉 helper：`UcgScaffold` / `UcgGlassCard` / `UcgSegmentedPills`，统一 `AppVisualTokens` + `themePrimaryBlend`

## 3. Phase 2 — 广场与 Profile（ucg-square-feed / ucg-profile / ucg-visual-system）

- [x] 3.1 广场 Tab：`HomeImmersiveHeader` 沉浸式顶栏 + **内嵌 pill 分段**（关注/推荐，禁止 Material TabBar 头身分离）+ 分页 ListView（WeChat 风格玻璃/表面卡片）
- [x] 3.2 推荐 Feed 未登录可浏览；关注 Tab 未登录引导登录
- [x] 3.3 实现 `requireUcgLogin` 统一门控 helper
- [x] 3.4 我的页：小红书布局（头像/昵称/简介、关注列表入口、我的动态、宝藏占位）
- [x] 3.5 Profile 编辑页对接 `GET/PUT /ucg/app/api/profile/me`
- [x] 3.6 他人主页只读跳转（Feed 点头像）

## 4. Phase 2 — 发布与草稿（ucg-compose-post）

- [x] 4.1 Compose 页：文本 + ≤9 图 OR 1 视频（15s/20MB 客户端校验）；全屏/Sheet 使用 `showGlassAdaptiveBottomSheet` 或同 shell 沉浸式 Scaffold
- [x] 4.2 presign 上传流程对接 `POST /ucg/app/api/media/presign`
- [x] 4.3 本地草稿 JSON 持久化与恢复
- [x] 4.4 发帖 `POST /ucg/app/api/posts`；与「我的动态」编辑共用 compose
- [x] 4.5 我的动态列表 `GET /ucg/app/api/posts/mine`，展示 pending/rejected 状态文案

## 5. Phase 3 — 审核状态 UI

- [x] 5.1 作者 pending 显示「审核中」；rejected 显示「违规已下架」+ reason
- [x] 5.2 公开 Feed 过滤非 published 帖子（客户端防御性过滤）

## 6. Phase 4 — 互动与关注（ucg-interactions）

- [x] 6.1 点赞/取消赞 API 与 UI；长按撤销自己的赞
- [x] 6.2 评论列表/发表评论/删除自己的评论
- [x] 6.3 关注/取消关注与关注列表页
- [x] 6.4 关注 Feed 对接 `GET /ucg/app/api/feed/following`

## 7. Phase 5 — 消息与 WS（ucg-chat-ui）

- [x] 7.1 新建 `UcgChatRepository`（参考 `RemoteFeedRepository`：auth 首帧、重连、生命周期）
- [x] 7.2 会话列表 UI + 未读红点（底部消息 Tab）；列表行与聊天页遵循玻璃/主题色规范，弹层用 `app_glass_overlay`
- [x] 7.3 左滑置顶/删除会话
- [x] 7.4 1:1 聊天页：文本/图片/视频发送与 pending/delivered/failed 态
- [x] 7.5 WS 连接 `AppEnv.wsUcgChatUrlEffective`（经 gateway `/ucg/app/ws/chat`，与 `apiBaseUrl` 同 host）

## 8. Phase 6 — polish

- [x] 8.1 PageView 横滑切换喂养/UCG（保留右侧拉条作为辅助入口；HomeScreen 以纵向滚动为主，横滑冲突风险低）
- [x] 8.2 UCG WS 连接策略优化（仅消息 Tab/有未读时常连）
- [x] 8.3 推荐 Feed 下拉刷新与空态/错误态
- [x] 8.4 UCG 全模块视觉走查：主题切换、深浅 shell、无 TabBar/AppBar 割裂、玻璃 dock 与卡片一致性
- [ ] 8.5 联调验收清单：未登录推荐、登录发帖、审核态、经 gateway 聊天 Option C
