## Context

`xiaozhi-speaker-app-binding` 已提供管理页、开通与绑定。群二维码来自 `GET /cash/app/api/feature/catalog` 的 `inviteGroupQrUrl`，邀请码 howto（`/features/invite-howto`）已解析并展示；失败整块隐藏。本变更只补「自购硬件」说明与购买教程页。

## Goals / Non-Goals

**Goals:**

- 管理页可见：绑定需自行采购小智音箱；`?` → 如何购买。
- 购买页：短说明 + 同 invite 的群 QR（有 URL 时）；进群问购。
- 复用 catalog 加载与 URL 解析，无新 API。

**Non-Goals:**

- 官方商城外链、SKU、支付硬件。
- 合并 MAC/Token 字段帮助。
- 新建测试文件。

## Decisions

### D1. 入口位置

- **选择**：管理页列表顶部、开通条之上（或紧贴开通条上方）玻璃条：一句说明 + `?`「如何购买」。
- **理由**：进页即见硬件前提，不依赖打开添加表单。
- **备选**：仅 AppBar action → 发现性弱，否决为首选。

### D2. 教程路由

- **选择**：`/settings/xiaozhi-speaker/howto-buy`，加入与小智页相同的登录门禁集合。
- **理由**：与现有 `help-mac` / `help-token` 并列，栈清晰。

### D3. 群 QR 复用

- **选择**：进页 `featureCatalogStateProvider.notifier.ensureLoaded()`；`resolveInviteGroupQrUrl(catalog.inviteGroupQrUrl, apiBase)`；展示模式对齐 invite howto（可点进全屏预览便于扫码；加载失败隐藏整块含标题）。
- **理由**：运维只维护一处群码；无新配置面。
- **备选**：静态 asset QR → 易过期，否决。

### D4. 文案范围（方案 A）

- 页说明：须自行采购小智音箱才能使用绑定；App 提供开通与绑定，不含硬件。
- 教程：补充「不确定型号/渠道可扫码进官方群咨询」；有 QR 时展示；无 QR 仅文字。

### D5. 与字段帮助隔离

- 购买 howto **不得**塞进 MAC/Token 帮助页；反之亦然。

## Risks / Trade-offs

- [Risk] catalog 未配 QR → 教程只有字 → **Mitigation**：文案仍成立；运维配 `inviteGroupQrUrl`。
- [Risk] 进小智页触发 catalog 拉取 → **Mitigation**：`ensureLoaded` 已有 single-flight/缓存；与开通中心同源。
- [Risk] 用户把「永久开通」当成买音箱 → **Mitigation**：页顶说明与开通条文案区分「App 能力」vs「硬件」。

## Migration Plan

1. 合入 Flutter 说明条 + howto-buy 路由。
2. 确认生产 catalog 已有群 QR（与邀请码共用）。
3. 回滚：隐藏说明条与路由即可。

## Open Questions

- （已拍板）方案 A：短说明 + 群 QR，无电商外链。
