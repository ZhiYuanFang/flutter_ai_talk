## 1. 状态模型与失败分类

- [x] 1.1 扩展 `LiveActivityRegistrationStatus`：每类 attributes 的 `ptsEventSeen` / register Ok、错误类别枚举、可复制 `diagnosticSummary` 字段
- [x] 1.2 `_register`：收到 `push_to_start` 先标记 seen；HTTP 失败写入类别 `register_http_failed` 且保留文案
- [x] 1.3 `forceRetryPushToStart` 超时逻辑：有 HTTP 错不覆盖；无事件 → `no_system_token`；部分成功 → `partial_attributes`；全成功但本轮无新事件 → `timeout_kept_prior_success`

## 2. 原生诊断信号

- [x] 2.1 Bridge：`deliver` 对 push_to_start 累加计数；`getSystemStatus`/`getDiagnostics` 返回 `pushToStartDeliverCount`
- [x] 2.2 Dart `LiveActivityNative` 读取并并入 status / diagnosticSummary

## 3. 设置页展示

- [x] 3.1 `LiveActivitySettingsScreen`：分 kind 展示「已见事件 / 已上报」；下方失败文案 + 可复制诊断摘要（无 token）
- [x] 3.2 确认错误类别对应人话中文短句可读、可复述给客服

## 4. 验收

- [x] 4.1 手工或说明：模拟 HTTP 失败时超时后仍显示 HTTP 文案
- [x] 4.2 手工或说明：无 PTS 事件时显示未收到系统 token，且摘要含 seen=0 / deliver=0（若可得）
- [x] 4.3 `dart analyze` 相关文件无新增问题
