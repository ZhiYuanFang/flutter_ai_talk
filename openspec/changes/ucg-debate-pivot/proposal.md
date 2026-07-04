## Why

UCG 广场当前以图文/视频「动态」（moment）为主，对目标用户「宝妈」的话题讨论与立场表达吸引力不足。产品决定 pivot 为**话题辩论**形态：用户围绕育儿话题选择立场、投票并发表论点，以提升互动深度与留存。本变更在保留 moment 类型的同时，将广场/关注 Feed 切换为仅展示 `debate` 帖，并贯通 App、go_ai_talk 后端与微信小程序三端能力。

## What Changes

- **帖子模型**：`type` 字段 `debate` | `moment` 共存；广场与关注 Feed **仅**拉取 `debate`；个人时间线可展示作者全部类型。
- **辩论帖字段**：`content`（话题正文，不限长）、`debateLeft` / `debateRight`（各方立场标签，各最多 5 字）；发帖**不得**附带媒体。
- **投票**：`POST /posts/{id}/vote { side: left|right }`；每用户每帖一票；Feed/详情返回 `leftVoteCount`、`rightVoteCount`、`myVoteSide`。
- **原力值**：作者 `forceValue` 字段（wx 表）；发帖作者投票时 +1 原力（评论不加）；档位 [0,500) 无展示、[500,1000) 青铜、每 +500 一档至钻石；个人页与广场作者行展示等级图标。
- **共享 UI `UcgDebateVsBar`**：广场、个人时间线、详情、分享截图**统一**组件；**仅展示百分比**，禁止展示原始票数；`minDisplayRatio=0.12`；0 票时对称条、**不显示**百分比数字；`interactive=true`（广场/详情可点投票）/ `false`（个人列表）；VS 图标位于色带分界。
- **评论即论点**：复用现有扁平评论 + `@mention` 回复；广场卡片内联展示，>5 条可展开；个人列表**不**展示论点；详情**全量**展示、无折叠。
- **点赞**：`debate` 帖**废弃**点赞；`moment` 保持现有点赞行为。
- **导航**：广场卡片**不得**跳转详情进行互动（就地投票/评论）；个人时间线点击进详情；广场 FAB 发帖，**移除**底部 Dock 发帖入口。
- **通知（方案 A）**：扩展现有互动收件箱；新增 `debate_vote` 类型；辩论帖通知文案/缩略图适配。
- **微信分享**：标题 = 话题 `content`；App 离屏渲染辩论详情布局 → 客户端上传截图至 OSS（复用 UCG presign）→ CDN URL 用于 fluwx 好友/朋友圈及小程序卡片。
- **微信小程序 `wx_ai_talk`**：完整投票 + 论点；`wx.login` → `POST /device/app/api/login platform=miniprogram`（go 新增 jscode2session 路径）；同 unionid 与 App fluwx 账号；底部 CTA 引导下载胖宝 App 发辩论。
- **BREAKING**：广场 Feed 默认内容从 moment 变为 debate；广场交互路径变更（无详情跳转）；debate 帖移除点赞 UI/API 调用。

## Capabilities

### New Capabilities

- `ucg-debate-post`：辩论帖数据模型、`type` 枚举、发帖校验（无媒体、立场标签长度）、Feed 按类型过滤。
- `ucg-debate-vote`：投票 API、幂等、计数、`myVoteSide`、作者投票 +1 原力值。
- `ucg-debate-vs-bar`：共享 `UcgDebateVsBar` 组件规范（百分比展示、交互态、0 票态、VS 图标）。
- `ucg-force-value`：原力值存储、档位计算、个人页与 Feed 作者行图标展示规则。
- `ucg-debate-share`：离屏渲染、截图 presign 上传、fluwx 分享参数。
- `ucg-debate-miniprogram`：微信小程序投票/论点、登录、发布 CTA。
- `ucg-debate-server-api`：go_ai_talk ucg-service / device-service 表结构、路由、通知写入（`[go]` 实现边界）。

### Modified Capabilities

- `ucg-api-contract`：新增 vote、forceValue、debate 字段 DTO；Feed 查询参数 `type=debate`；废弃 debate 帖 like 路径调用。
- `ucg-square-feed`：仅 debate；内联论点（>5 展开）；就地投票；无详情跳转。
- `ucg-compose-post`：辩论发帖 UI（话题 + 左右立场，无媒体）；广场 FAB 入口；移除 Dock 发帖。
- `ucg-interactions`：debate 帖禁用点赞；投票/评论登录门控；广场 vs 详情交互分工。
- `ucg-post-comment`：论点展示规则（广场折叠、详情全量、个人列表隐藏）。
- `ucg-profile`：时间线点击进详情；作者原力图标；debate/moment 混排展示。
- `ucg-shell-navigation`：广场 FAB；移除底部 Dock compose；个人页 → 详情路由。
- `ucg-notifications`：`debate_vote` 通知类型、文案与缩略图（无媒体辩论帖封面策略）。
- `wechat-oauth-login`：小程序 `platform=miniprogram` + jscode2session 登录路径（go_ai_talk）。

## Impact

- **flutter_ai_talk（本仓）**：`app/lib/ucg/**` Feed/详情/compose/profile/share 组件；`UcgApiClient` DTO；新增 `UcgDebateVsBar`；离屏截图上传；fluwx 分享参数；Debug tag 若新增须三联改。
- **go_ai_talk**：`ucg_post` 表 `type`/debate 字段；`ucg_post_vote`；`wx.force_value`；vote/feed/profile API；`NotifyOnVote`；device-service 小程序登录；历史 moment 数据兼容。
- **wx_ai_talk**：新小程序工程；投票/评论页；登录与分享卡片；发布 CTA。
- **基线对照**：变更触及 v2.0.3 中 `ucg-square-feed`、`ucg-compose-post`、`ucg-interactions`、`ucg-post-comment`、`ucg-profile`、`ucg-shell-navigation`、`ucg-notifications`、`ucg-api-contract`；历史 `history-event-square-sync` 同步的 moment 帖不受广场 Feed 过滤影响（仍可通过个人页访问）。
