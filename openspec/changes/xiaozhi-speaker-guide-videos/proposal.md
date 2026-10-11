## Why

Go 已提供 `GET /cash/app/api/xiaozhi-mcp/guide-videos`（运营配置的能力宣传 / 绑定教学视频）。小智音箱页需要按清单展示入口并全屏点播；未配置或拉取失败时不得残留空入口。现有「如何购买」howto 与视频引导正交，保持分离。

## What Changes

- 小智音箱页进入（及下拉刷新）时 Bearer 拉取引导视频清单。
- `list` 为空、或请求失败 → **完全不渲染**引导入口（失败一律当空）。
- 有项时：入口嵌在「绑定后可以做什么」玻璃卡**底部**；按服务端 `title` 展示；可用 `coverCdnUrl` 作封面。
- 点击条目进入**全屏播放页**，播放 `videoCdnUrl`。
- **不改**购买 howto（`?` / howto-buy）、MAC/Token 帮助、开通/绑定主流程。
- 不改 Go 契约（以兄弟仓 handoff 为准）。

## Capabilities

### New Capabilities

- `xiaozhi-speaker-guide-videos`：引导视频清单拉取、空/失败隐藏、卡底入口、全屏点播。

### Modified Capabilities

- （可选行为叠加）小智音箱管理页在「绑定后可以做什么」卡内增加条件入口；不修改购买 howto 需求本身。

## Impact

- 代码：`xiaozhi_speaker_screen`、新 DTO/repository（或并入既有 xiaozhi MCP repo）、全屏播放路由（登录门禁与音箱页一致）。
- 依赖：`video_player` / 既有网络图封面能力；API 经 authorized client。
- 联调：Hub 上传 `promo`/`tutorial` 后 App 可见；usage 会计入该 GET。
