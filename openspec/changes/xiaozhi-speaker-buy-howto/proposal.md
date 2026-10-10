## Why

小智音箱绑定页已能开通与登记 MCP，但未说明硬件需用户自行采购，易被误解为 App 内含音箱或官方直销。用户不清楚从哪里买兼容设备时，需要可进群咨询的入口；官方微信群二维码已由功能开通 catalog 的 `inviteGroupQrUrl` 提供，可复用。

## What Changes

- 在「小智音箱」管理页增加能力说明：须自行采购小智音箱后方可使用绑定；旁附 `?`（或等价）入口「如何购买」。
- 新增购买说明页（方案 A）：短文说明自购硬件 + 复用 catalog `inviteGroupQrUrl` 展示群二维码，引导进群咨询购买；**不**内嵌电商外链、**不**新增后端 API。
- URL 为空或图片加载失败时：仍展示文字说明，二维码整块隐藏（对齐邀请码 howto 失败语义）。
- **不做**：改 go 契约、改绑定/支付逻辑、把购买说明与 MAC/Token 字段帮助合并。

## Capabilities

### New Capabilities

- `xiaozhi-speaker-buy-howto`：小智页硬件自购能力说明、`?` 进入购买教程、复用群二维码进群咨询。

### Modified Capabilities

- （无；不修改 `settings-center` 入口文案，仅扩展已有小智音箱管理页内容。）

## Impact

- **代码**：`xiaozhi_speaker_screen` 说明条；新路由如 `/settings/xiaozhi-speaker/howto-buy`（登录门禁）；复用 `featureCatalogStateProvider.ensureLoaded`、`resolveInviteGroupQrUrl` 与邀请码页同类 QR 展示模式。
- **依赖**：catalog 已配置非空 `inviteGroupQrUrl` 时才有图；与 `xiaozhi-speaker-app-binding` 并存。
- **基线**：对照 `openspec/specs/v2.1.3.md` 邀请码 howto / 群 QR 展示约定；MCP 仍不进 feature catalog 瓷砖。
