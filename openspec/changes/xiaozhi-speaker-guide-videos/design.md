## Context

Go change `xiaozhi-guide-videos-drop-transcode` 已交付 App GET；槽为 `promo` / `tutorial`，App 仅返回已配置项。Flutter 小智页已有自购说明 +「绑定后可以做什么」文案卡 + 开通/绑定。播放可复用仓内 `video_player` 模式。

## Goals / Non-Goals

**Goals:**

- 进页拉清单；空或失败藏入口；有项挂在能力说明卡底部；全屏播。

**Non-Goals:**

- Admin/上传；改购买 howto；客户端写死中文槽名（展示用 `title`）；新建测试文件。

## Decisions

### D1：入口位置

嵌在「绑定后可以做什么」`SettingsGlassPanel` **底部**（文案下方）。无视频时该卡仅保留原说明文字，不出现分隔/空列表。

### D2：全屏播放

独立路由（如 `/settings/xiaozhi-speaker/guide-video`），入参 `title` + `videoCdnUrl`（及可选封面）。登录门禁与音箱页一致。退出即 dispose 播放器。

### D3：失败 = 空

HTTP/业务失败、解析失败 → 视为 `list=[]`，隐藏入口；Debug 日志记录 `err=`（用既有或新 tag，须三联改若新增）。不 Toast「加载引导失败」以免噪音（下拉刷新可重试）。

### D4：数据层

`GET /cash/app/api/xiaozhi-mcp/guide-videos`；DTO：`slot`、`title`、`videoCdnUrl`、可选 `coverCdnUrl`。过滤无 `videoCdnUrl` 的异常项。进页与 `_refreshAll` 一并拉取。

### D5：与购买 howto 正交

卡底视频入口 **不**替代自购说明旁 `?`。

## Risks / Trade-offs

- [CDN 播失败] → 全屏页内错误提示 + 返回；不影响音箱页。
- [封面缺失] → 标题行 + 播放图标即可。
- [列表顺序] → 尊重服务端 `list` 顺序，不按 slot 重排（除非产品另定）。

## Migration Plan

1. 合入 Flutter；Hub 未上传时入口不可见（符合预期）。
2. 回滚：去掉卡底入口与路由即可。

## Open Questions

（无；入口位置、全屏、失败当空已拍板。）
