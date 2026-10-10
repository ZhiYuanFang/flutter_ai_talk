## Context

兄弟仓已交付：

- 绑定：`/device/app/api/xiaozhi-mcp/bindings*`（Add 必填 `speakerMac`；列表含 `tokenMask` / `speakerMac` / `connected`）
- 开通：`GET /cash/app/api/xiaozhi-mcp/unlock`（`unlocked`、`trialAvailable`、`expiresAt`、可售 `product`）、`POST …/orders`
- 试用：每 wx 一次 24h；**首次成功 Add** 时由 cash `EnsureAccessForAdd` claim；无 App 独立领取接口
- 工具闸门：过期后 tools/call 拒答并懒停桥，绑行保留

本仓无小智相关代码。可复用：Settings glass tile、`ApiClient` envelope、功能开通支付的平台分流（iOS StoreKit + VIP 验单入口；Android 支付宝）、`dialog-text-controller-lifecycle`。MCP **不得**进入 `feature/catalog`。

## Goals / Non-Goals

**Goals:**

- 设置入口「小智音箱」+ 管理页：开通四态、永久支付、绑定 CRUD、连接态。
- 试用可用时允许 Add，提交前二次确认将消耗 24h 体验。
- MAC / MCP 接入点字段 `?` 帮助页 + 既有四张步骤图。

**Non-Goals:**

- 改 go API、Hub 静态页、直连 mcp-service。
- 并入开通功能管理 / 邀请码 / VIP 自动旁路。
- 新建 `**/test/**` 测试文件。
- 主动轮询连接态以外的实时推送。

## Decisions

### D1. 入口与路由

- **选择**：`settings_screen` 已登录玻璃 tile「小智音箱」→ `/settings/xiaozhi-speaker`（须登录门禁）。
- **理由**：与「功能开通」「反馈」一致；不挂 `ucg_home_shell`。
- **备选**：开通中心卡片 → 否决（MCP 不进 catalog）。

### D2. 数据层拆分

- **选择**：
  - `XiaozhiMcpBindingRepository`：bindings CRUD
  - `XiaozhiMcpUnlockRepository`：unlock GET + orders POST
  - `XiaozhiMcpPaymentService`：复用支付宝/`in_app_purchase` + VIP Apple 验单入口，建单走 MCP URL
- **理由**：契约独立于 feature catalog；避免污染 `FeaturePaymentService`。
- **备选**：硬塞 feature 支付服务 → 否决。

### D3. 开通四态（客户端）

| 条件 | UI |
|------|-----|
| `!unlocked && trialAvailable` | 「可免费体验 24 小时」；Add 可用；永久开通 CTA；Add 前确认将开始体验 |
| `unlocked && expiresAt > 0` | 「体验中 · 至 …」；Add 可用；永久开通 CTA |
| `unlocked && expiresAt == 0` | 「已永久开通」；仅绑定管理 |
| `!unlocked && !trialAvailable` | 「体验已用完」；Add 禁用直至支付成功 |

- List/改备注/删除不依赖开通态（与服务端一致）。
- 未绑宝宝：禁用 Add，引导 `/settings/bind-baby`。

### D4. 添加表单与 upsert 文案

- 字段：`alias`、`speakerMac`、`mcpToken`（可粘贴完整 `wss://…/?token=`）。
- 服务端同 MAC upsert：成功 toast 区分新建 / 更新接入点（若接口无区分字段，可用「添加前列表是否已有该规范化 MAC」启发式，或统一「已保存」+ 刷新列表）。
- 输入弹层：`TextEditingController` **必须**由弹层 `State` 持有并 dispose。

### D5. 字段帮助

- MAC / MCP 旁 `?` → 全屏或可滚动 glass 帮助页：短说明 + 纵向展示两张图。
- 资产路径：`assets/images/mac_1.png`、`mac_2.png`、`token_1.png`、`token_2.png`。
- 文案对齐小智控制台：设备列表抄 MAC；配置 → 扩展能力 → MCP 接入点 → 复制。

### D6. 连接态

- 列表项：`connected==true` 绿灯，否则红灯；不引入黄灯。
- 刷新：进页与写操作成功后重新 GET；不做独立 WS。

### D7. 日志

- 失败路径用既有 `ApiHttpLog` / 若需业务 tag 则三联改（本变更优先不新增 tag，除非调试必要）。
- **禁止**打印完整 `mcpToken`。

### D8. 试用确认默认

- `trialAvailable` 且用户点添加/提交时：glass 确认「添加后将开始 24 小时免费体验，每账号仅一次」。
- 已 `unlocked` 时跳过该确认。

## Risks / Trade-offs

- [Risk] Admin 未配 Apple ID / 价格 → 支付失败 → **Mitigation**：展示服务端错误；可先试用/手工授联调。
- [Risk] 过期后仍显示曾连接绿→红延迟 → **Mitigation**：文案提示体验结束后对话可能断开；接受懒停。
- [Risk] Hub 代绑消耗用户试用 → **Mitigation**：属 go 侧约定；App 文案标明「添加即开始体验」。
- [Risk] 同 MAC upsert 无显式响应标志 → **Mitigation**：刷新列表 + 中性成功文案优先，避免误导。

## Migration Plan

1. 合入本仓 UI 与 API 客户端。
2. 确认 gateway 已反代 cash/device 小智路径；Admin 配价。
3. 回滚：隐藏设置入口或 feature flag（若有既有开关习惯则用；否则移除路由即可）。

## Open Questions

- （已拍板）入口文案「小智音箱」；首版含开通+绑定；试用 Add 前二次确认；过期提示一句即可。
- usage 是否计入属 go 侧待确认项，本仓不改。
