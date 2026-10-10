## Why

兄弟仓 `go_ai_talk` 已提供小智 MCP 音箱绑定 CRUD、永久开通/建单、以及每账号一次 24h 试用（首次成功 Add 时 claim）契约，但 Flutter 客户端尚无入口与 UI。C 端用户无法在 App 内开通能力、登记音箱 MAC 与 MCP 接入点，也无法对照小智控制台截图理解字段来源。

## What Changes

- 设置中心新增已登录入口「小智音箱」，进入独立管理页（开通条 + 绑定列表 + 添加）。
- 对接 `GET /cash/app/api/xiaozhi-mcp/unlock`：展示 `unlocked` / `trialAvailable` / `expiresAt` 与可售永久 SKU；对接 `POST /cash/app/api/xiaozhi-mcp/orders` 完成支付宝/Apple 永久开通（**不**进入功能开通 catalog）。
- 对接绑定 CRUD：`GET/POST/PUT/DELETE /device/app/api/xiaozhi-mcp/bindings`（添加必填 `speakerMac`、`mcpToken`、`alias`；列表展示脱敏 token、MAC、连接态绿/红灯）。
- 试用：无独立领取接口；当 `trialAvailable` 时允许添加，服务端在首次成功 Add 时 claim 24h；添加前二次确认「将开始 24 小时体验」。
- 添加表单中 MAC 与 MCP 接入点旁提供 `?` 帮助：字段说明 + 步骤图（`mac_1/2.png`、`token_1/2.png`）。
- **不做**：改 go 契约、直连 xiaozhi-mcp-service、把 MCP 并入「开通功能管理」/邀请码/VIP 旁路。

## Capabilities

### New Capabilities

- `xiaozhi-speaker-binding`: 小智音箱绑定管理页、列表 CRUD、连接态展示、未绑宝宝门禁、添加/改备注/删除交互。
- `xiaozhi-speaker-unlock`: 开通态四态展示、试用提示与 Add 前确认、永久开通支付（独立 cash 路径）。
- `xiaozhi-speaker-field-help`: MAC / MCP 接入点字段帮助（`?` → 说明 + 本地步骤图）。

### Modified Capabilities

- `settings-center`: 已登录设置列表新增「小智音箱」入口（与「功能开通」等并列玻璃 tile；登录门禁同反馈入口）。

## Impact

- **代码**：设置入口与路由、`XiaozhiMcp*` repository/provider/payment、管理页与添加表单/帮助页；复用 `ApiClient`、Settings glass、支付通道骨架（对齐 `FeaturePaymentService` 平台分流，但建单走 MCP 专用 URL）。
- **资产**：使用已有 `app/assets/images/mac_1.png`、`mac_2.png`、`token_1.png`、`token_2.png`（`assets/images/` 已在 pubspec）。
- **依赖**：兄弟仓已上线/即将上线的 App API；Admin 需配置 MCP SKU 价格与 Apple 商品 ID 后支付才可购。
- **基线**：对照 `openspec/specs/v2.1.3.md` 的 `settings-center`、`dialog-text-controller-lifecycle`、功能开通支付模式；MCP **不**修改 `feature-unlock-hub` catalog 语义。
