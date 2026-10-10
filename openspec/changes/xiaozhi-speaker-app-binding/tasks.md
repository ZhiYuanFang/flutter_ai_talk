## 1. 数据层与模型

- [x] 1.1 新增绑定 DTO/仓库：`GET/POST/PUT/DELETE /device/app/api/xiaozhi-mcp/bindings`（字段含 alias、tokenMask、speakerMac、connected、mcpToken 入参等）
- [x] 1.2 新增开通 DTO/仓库：`GET /cash/app/api/xiaozhi-mcp/unlock`、`POST /cash/app/api/xiaozhi-mcp/orders`（unlocked、trialAvailable、expiresAt、product）
- [x] 1.3 Riverpod：开通态 + 绑定列表加载/刷新；写操作后失效刷新；失败路径经 ApiHttpLog（禁止打印完整 token）

## 2. 永久开通支付

- [x] 2.1 实现 `XiaozhiMcpPaymentService`：Android `alipay` / iOS `apple_iap` + 既有 Apple 验单入口；建单走 MCP orders
- [x] 2.2 管理页永久开通 CTA：可售时调起支付，成功后刷新 unlock；Web/不支持平台友好提示

## 3. 管理页与设置入口

- [x] 3.1 路由 `/settings/xiaozhi-speaker`（或等价）加入登录门禁集合
- [x] 3.2 `settings_screen` 已登录玻璃 tile「小智音箱」→ 管理页
- [x] 3.3 管理页：开通四态条、未绑宝宝禁用 Add、绑定列表（备注/MAC/脱敏 token/绿红灯）、改备注、删除确认

## 4. 添加表单与试用确认

- [x] 4.1 添加弹层/表单：alias、speakerMac、mcpToken；controller 由弹层 State 持有并 dispose
- [x] 4.2 `trialAvailable` 且未 unlocked 时提交前二次确认「开始 24h 体验」；已 unlocked 跳过
- [x] 4.3 提交 POST；成功刷新列表与 unlock；体验用尽时 Add 禁用并引导支付

## 5. 字段帮助

- [x] 5.1 MAC `?` → 说明 + `assets/images/mac_1.png`、`mac_2.png`
- [x] 5.2 MCP 接入点 `?` → 说明 + `assets/images/token_1.png`、`token_2.png`
- [x] 5.3 确认 pubspec 已包含 `assets/images/`（已有则无需改）

## 6. 自检

- [ ] 6.1 手工：未登录无入口；登录进页；试用可用 Add 确认 → 列表出现；改备注/删除
- [ ] 6.2 手工：体验用尽 Add 禁用；支付（或 Admin 授）后可再 Add；同 MAC 再提交列表仍一条
- [x] 6.3 确认功能开通 catalog 无 MCP 瓷砖；帮助图可打开且无完整 token 泄露
