## 1. 后端数据模型与迁移 [go]

- [x] 1.1 [go] 新增 migration：`ucg_post.type`（`debate`|`moment`，默认 `moment`）、`debate_left_label`/`debate_right_label` VARCHAR(5)
- [x] 1.2 [go] 新增 migration：表 `ucg_post_vote(post_id, voter_wx_id, side)` 唯一索引 `(post_id, voter_wx_id)`
- [x] 1.3 [go] 新增 migration：`wx.force_value INT DEFAULT 0`
- [x] 1.4 [go] debate 帖创建/更新校验：拒绝 `ucg_post_media` 写入；标签长度 ≤5

## 2. 后端 API 与 DTO [go]

- [x] 2.1 [go] 实现 `POST /posts/{id}/vote`（幂等、换边更新、moment 返回 400）
- [x] 2.2 [go] Feed `GET /feed/recommend|following` 支持 `type` 查询；辩论项聚合 `leftVoteCount`/`rightVoteCount`/`myVoteSide`
- [x] 2.3 [go] `GET /posts/{id}` 与 profile posts 返回 debate 字段与 vote 字段
- [x] 2.4 [go] 作者 DTO 增加 `forceValue`（可选 `forceTier`）
- [x] 2.5 [go] 作者投票成功时 `force_value += 1`（评论不触发）
- [x] 2.6 [go] debate 帖 like 接口返回 400
- [x] 2.7 [go] 实现 `NotifyOnVote` 写入 `debate_vote` 通知（`post_media_kind=3`）

## 3. 小程序登录 [go]

- [x] 3.1 [go] device-service：`POST /device/app/api/login` 支持 `platform=miniprogram`
- [x] 3.2 [go] 实现 jscode2session（`wx_ai_talk` appId/secret）与 unionid 账号合并
- [x] 3.3 [go] 补充 runbook/配置项文档（小程序 secret、合法域名）

## 4. API Client 与模型 [app]

- [x] 4.1 [app] `UcgPost`/`UcgAuthor` DTO 增加 `type`、`debateLeft`/`debateRight`、vote 字段、`forceValue`
- [x] 4.2 [app] `UcgApiClient` 新增 `votePost(postId, side)`；Feed 方法默认传 `type=debate`
- [x] 4.3 [app] debate 帖代码路径移除 like API 调用

## 5. UcgDebateVsBar 共享组件 [app]

- [x] 5.1 [app] 实现 `UcgDebateVsBar`（百分比展示、0 票无数字、minDisplayRatio=0.12、VS 图标、interactive 开关）
- [x] 5.2 [app] 单元/手工验证：极端票比钳制与点击色带 vote 回调（热区与视觉宽度一致）

## 6. 广场 Feed 改造 [app]

- [x] 6.1 [app] 辩论卡片布局：话题 + 作者行（含原力图标）+ VS 条 + 时间/属地
- [x] 6.2 [app] 内联论点（前 5 条 + 展开）；就地评论输入与 @mention
- [x] 6.3 [app] 移除广场辩论卡跳转详情；保留头像 → `UcgUserProfileScreen`
- [x] 6.4 [app] 广场 FAB 打开辩论 compose；移除 Dock 发帖入口

## 7. 辩论发帖 [app]

- [x] 7.1 [app] 新建 `UcgDebateComposeScreen`（话题 + 左右标签，无媒体）
- [x] 7.2 [app] 标签 5 字校验与 `POST /posts type=debate`
- [x] 7.3 [app] 若新增 Debug tag（如 `[UcgDebate]`）须三联改 `app_debug_log.dart` / `logcat_api_http.ps1` / `README.md`

## 8. 详情与个人页 [app]

- [x] 8.1 [app] 辩论详情：VS 条（interactive=true）+ 全量论点 + 评论输入
- [x] 8.2 [app] 个人时间线：debate 卡点击进详情；VS 条 interactive=false；隐藏论点列表
- [x] 8.3 [app] 个人页「关注 N」左侧原力图标；广场作者昵称旁原力图标

## 9. 通知收件箱 [app]

- [x] 9.1 [app] 解析并展示 `debate_vote` 类型文案与缩略图
- [x] 9.2 [app] 点击通知跳转辩论详情

## 10. 微信分享 [app]

- [x] 10.1 [app] 离屏 `RenderRepaintBoundary` 渲染辩论分享布局
- [x] 10.2 [app] presign + PUT 上传截图；fluwx 分享 title=`content`、imageUrl=CDN
- [x] 10.3 [app] 上传失败降级纯文字分享 + `AppDebugLog` 记录

## 11. 微信小程序 [mp]

- [x] 11.1 [mp] 初始化 `wx_ai_talk` 工程与 UCG API 封装
- [x] 11.2 [mp] `wx.login` → device login `platform=miniprogram`
- [x] 11.3 [mp] 辩论列表/详情页：VS 条（与 App 规则一致）、投票、论点列表与发表评论
- [x] 11.4 [mp] 底部 CTA「去胖宝 App 发起辩论」
- [x] 11.5 [mp] 分享卡片（若适用）使用服务端/App 提供的封面 URL

## 12. 联调与验收

- [ ] 12.1 [app] 手工路径：广场投票、展开论点、FAB 发帖、个人页进详情、分享截图
- [ ] 12.2 [go] 联调 vote 计数、原力 +1、通知写入
- [ ] 12.3 [mp] 联调小程序登录 unionid 与 App 同账号投票
- [ ] 12.4 [app] 若触及 `app/android/**` 或原生 SDK，合并前 `flutter build apk --release` 并更新 `proguard-rules.pro`
