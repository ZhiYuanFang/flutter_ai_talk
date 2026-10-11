## Context

列表项已有 `XiaozhiMcpBindingItem.connected` 与绿/红文案；Hub 行为：`!connected` →「重连」→ `POST .../bindings/{id}/reconnect` → 刷列表。go 接口快速返回，仅表示已触发 ForceRestart。

## Goals / Non-Goals

**Goals:**

- App 未连接态可手动重连，语义对齐 Hub。
- 成功反馈清晰；列表刷新观测 `connected`。

**Non-Goals:**

- 不改 go / 不阻塞等待 WS 握手。
- 不做推送式连接态订阅；不做自动轮询（可选一次短延迟再刷）。

## Decisions

### D1：仅 `!connected` 显示「重连」

与 Hub 一致；已连接不提供多余入口。

### D2：成功文案与刷新

- toast：`已触发重连`（success）。
- 立即 `invalidate(xiaozhiMcpBindingsProvider)`；额外 `Future.delayed(1.5s)` 再 invalidate 一次（弱网握手延迟），不阻塞 UI。

### D3：单卡 loading

`_reconnectingId == item.id` 时禁用该卡重连钮并显示小 progress，避免连点。

### D4：无开通门禁

过期用户仍可对已有绑定点重连（与 go 一致）。

## Risks / Trade-offs

- [刷完仍未连接] → 文案已说明「触发」；用户可再点或下拉刷新。
- [429/节流] → 展示服务端 message。

## Open Questions

- （无）
