## 1. API

- [x] 1.1 `XiaozhiMcpBindingRepository.reconnect(int id)`：`POST /device/app/api/xiaozhi-mcp/bindings/{id}/reconnect`；错误 toast 与既有 CRUD 一致

## 2. UI

- [x] 2.1 `_BindingCard`：`!connected` 时展示「重连」；重连中禁用并示意 loading
- [x] 2.2 管理页：点击 → reconnect → success toast → invalidate 列表；可选约 1.5s 后再刷一次

## 3. 验收

- [ ] 3.1 真机/联调：未连接点重连有请求与提示，列表可变为已连接或仍未连接但可再试；已连接无重连钮
