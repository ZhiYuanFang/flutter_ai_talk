## Context

胖宝 UCG 模块（v2.0.3 基线）以图文/视频 moment 帖为核心：广场双列瀑布流、详情页点赞/评论、底部 Dock 发帖入口。后端 `go_ai_talk` ucg-service 提供 Feed、发帖、点赞、评论 API；微信登录经 fluwx OAuth2，device-service 已有 App 登录路径。

产品 pivot 要求将广场/关注 Feed 切换为**话题辩论**（`debate`），同时保留 `moment` 类型供历史同步与个人时间线。三仓协同：`flutter_ai_talk`（App）、`go_ai_talk`（API）、`wx_ai_talk`（小程序，当前空仓）。

工程约束：UCG HTTP 经 `UcgApiClient`；Debug 日志仅 `AppDebugLog`；副作用 HTTP 须 single-flight；公开读接口游客不带 Bearer（延续基线）。

## Goals / Non-Goals

**Goals:**

- 贯通 debate 帖模型、投票、原力值、共享 VS 条 UI、评论即论点、通知、微信分享截图上传、小程序只读/互动。
- 广场就地互动（投票/论点），个人页进详情；FAB 发辩论。
- 服务端 vote 幂等、Feed 按 `type=debate` 过滤、作者投票 +1 原力。
- 规格 delta 覆盖全部受影响 capability，任务按 `[app]`/`[go]`/`[mp]` 前缀分仓。

**Non-Goals:**

- 移除 moment 类型或迁移历史 moment 为 debate。
- 辩论帖点赞、媒体附件、AI 润笔（辩论 compose 不走润笔）。
- 小程序内发帖（仅 CTA 导 App）。
- 实时 WS 推送投票计数（首版 HTTP 刷新/乐观更新即可）。
- 重设计 UCG 聊天、历史同步广场逻辑（仍发 moment）。

## Decisions

### 1. 帖子 `type` 枚举与 Feed 过滤

- **决策**：`ucg_post.type` 新增 `debate` | `moment`（默认 `moment` 兼容存量）；`GET /feed/recommend` 与 `/feed/following` 增加 query `type=debate`，App 广场固定传参。
- **理由**：最小破坏；个人页 `GET /profile/{wxId}/posts` 不传 type，返回全部类型。
- **备选**：独立 `/feed/debate` 路径 — 拒绝，与现有 Feed 分页契约重复。

### 2. 辩论字段与存储

- **决策**：`debate_left_label`、`debate_right_label` VARCHAR(5)；`content` 承载话题正文（不限长，TEXT）；debate 帖禁止 `ucg_post_media` 行。
- **理由**：复用 `content` 减少 DTO 分裂；标签长度 UI+DB 双校验。

### 3. 投票表与 API

- **决策**：新表 `ucg_post_vote(post_id, voter_wx_id, side ENUM left|right)`，唯一索引 `(post_id, voter_wx_id)`；`POST /posts/{id}/vote` body `{ "side": "left"|"right" }`；重复投票同 side 幂等 200，换 side UPDATE。
- **计数**：Feed/详情 DTO 附带 `leftVoteCount`、`rightVoteCount`、`myVoteSide`（未登录 `myVoteSide` 省略）。
- **原力**：投票成功且 `voter_wx_id == post.author_wx_id` 时 `wx.force_value += 1`（评论不触发）。

### 4. `UcgDebateVsBar` 共享组件

- **决策**：单一 Widget `UcgDebateVsBar` 参数：`leftLabel`、`rightLabel`、`leftRatio`、`rightRatio`、`myVoteSide`、`interactive`、`minDisplayRatio=0.12`。
- **展示**：UI **仅百分比**（四舍五入整数 `%`）；总票为 0 时 50/50 对称条、**隐藏**百分比数字；有票后按 `max(ratio, minDisplayRatio)` 钳制视觉宽度。
- **VS 图标**：叠在左右色带分界中心。
- **交互**：`interactive=true` 时点击左/右色带触发 vote（热区宽度与视觉占比一致，非固定 50/50）；`false` 时 `IgnorePointer`。
- **使用面**：广场卡片、个人时间线、详情页顶、分享离屏 RenderRepaintBoundary。

### 5. 原力值档位

- **决策**：`wx.force_value INT DEFAULT 0`；档位函数：`[0,500)→none`（**不渲染**图标/占位）、`[500,1000)→bronze`，之后每 +500 升档至 diamond（与产品冻结表一致）。
- **展示**：个人页「关注 N」左侧；广场作者昵称旁。API：`author.forceValue`、`author.forceTier`（可选服务端计算）。

### 6. 评论即论点

- **决策**：复用 `POST/GET /posts/{id}/comments`；无新「论点」实体。
- **广场**：卡片底部内联前 5 条；>5 显示「展开 N 条论点」就地展开，**不**跳详情。
- **个人时间线**：debate 卡**不**展示论点列表。
- **详情**：全量评论，无折叠（延续基线 detail 行为）。

### 7. 点赞废弃（debate only）

- **决策**：`type=debate` 时客户端**不渲染**心形、**不调用** like API；服务端 like 接口对 debate 返回 400。moment 不变。

### 8. 导航与 Compose 入口

- **决策**：广场移除底部 Dock「发帖」；广场 Tab 右下角 FAB → `UcgDebateComposeScreen`（话题+左右标签，无媒体）。个人时间线 debate 卡点击 → 详情。广场卡**禁止**整卡跳详情（头像仍进 profile）。
- **备选**：保留 Dock 发帖 — 拒绝，产品明确要求 FAB。

### 9. 通知方案 A

- **决策**：扩展现有 `ucg_notification` 收件箱；新 `type=debate_vote`；缩略图：debate 无媒体时用话题摘要渲染图或固定辩论占位图（写入 `post_thumb_url`）；文案如「{nickname} 支持了你的观点「{sideLabel}」」。

### 10. 微信分享截图上传

- **决策**：App 用 `RenderRepaintBoundary` 离屏渲染辩论详情布局（话题+VS 条+前几条论点）→ PNG bytes → 复用 `POST /media/presign` + PUT OSS → 分享 URL 填入 fluwx `WeChatShareImageModel` / 小程序 path query。
- **理由**：用户决策客户端上传，避免服务端 headless 渲染成本。
- **流程**：presign `purpose=debate_share`（或复用 `post_cover`）→ PUT → `shareToWeChat` title=`content`。

### 11. 小程序登录

- **决策**：`wx.login` 取 code → `POST /device/app/api/login` body `{ platform: "miniprogram", code }`；go device-service 新增 jscode2session（`wx_ai_talk` appId/secret），签发与 App 相同 unionid 体系 JWT。
- **备选**：仅 OAuth2 H5 — 不符合小程序规范。

### 12. 三仓任务边界

- `[go]`：表迁移、vote API、Feed 过滤、force_value、通知、小程序登录、DTO。
- `[app]`：UI 组件、API client、compose、share 截图、通知展示。
- `[mp]`：页面、投票、评论、登录、CTA。

## Risks / Trade-offs

- **[Risk] 早期投票极少导致百分比误导** → `minDisplayRatio=0.12` + 0 票不显示数字；仅展示比例不展示绝对票。
- **[Risk] 截图分享 presign 失败** → 降级为纯文字分享（无图）；`AppDebugLog` 记录 err。
- **[Risk] 存量 moment 在广场不可见** → 产品预期；个人页仍可访问；通知/历史链接 moment 详情仍可用。
- **[Risk] 小程序与 App 账号不一致** → 强制 unionid 绑定；登录失败展示绑定说明。
- **[Risk] vote 并发计数漂移** → DB 事务 + `COUNT(*)` 聚合或冗余计数列带行锁；首版可用聚合查询。

## Migration Plan

1. **[go]** 部署 DB migration（`type`、debate 列、vote 表、`force_value`）— 向后兼容，默认 moment。
2. **[go]** 发布 vote API + Feed `type` 参数 + 通知类型。
3. **[app]** 发布：广场传 `type=debate`、新 UI；旧版 App 不传 type 仍得混合 Feed — 需服务端默认或强制升级（建议服务端未传 type 时仅返回 debate 以匹配产品）。
4. **[mp]** 独立提审；依赖后端 login + vote API。
5. **回滚**：App 回退版本；服务端保留列不删；Feed 去掉 type 过滤恢复混合流。

## Open Questions

- 无（discovery 决策已冻结）。实现阶段若 go 已有 `post.type` 草稿字段，以对齐仓库现状为准。
