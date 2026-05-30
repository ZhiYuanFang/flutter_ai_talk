## Why

胖宝当前以 Mock 仓库与本地存储为主，与真实后端 `pangbao.cuplay.top` 的契约、鉴权、设备绑定及实时数据尚未固化。需要一份 **OpenSpec 级联调契约**，统一 **HTTP 响应壳、微信登录与 deviceNo、历史与 WebSocket、语音聊天、趋势与版本检查**，便于客户端与服务端并行实现与验收。

## What Changes

- 定义全局 **HTTP JSON 响应壳**（`code` / `message` / `data`）及 **HTTP 恒 200**、失败时 **`data` 可为 null**、**Toast 展示 `message`** 的客户端义务。
- 定义 **微信同一用户体系**、**access_token + refresh token 静默续期**；登出 **不调**服务端接口。
- 定义 **用户详情 → `device_no` 映射为 `deviceNo`**；**绑定**（`bindwx`）、**创建宝宝**（`auto_save`）及「**登录成功 ≠ 可调业务接口**」直至具备有效 `deviceNo` 的引导规则。
- 定义 **历史列表分页**、**历史事件更新**接口；**WebSocket** 推送与客户端 **按 `id` 更新或新增** 的合并规则（取代 SSE）。
- 定义 **`/voice/text/chat`** 请求与 **`reply` 小字展示**；**趋势**强依赖 `deviceNo`、未登录 **图表遮罩 + 跳转登录**；**版本检查**独立接口（由本变更提议 path 与 `data` 形状供服务端对齐）。

## Capabilities

### New Capabilities

- `http-api-envelope`：统一响应壳、成功/业务失败语义、Toast 与 `data` 为空约定。
- `session-device-and-user`：微信登录、token 与刷新、用户详情 `device_no`、绑定与创建宝宝、未登录/未绑定状态机与界面引导（含历史失败文案、点击事件范围）。
- `history-voice-realtime`：历史列表 GET、事件更新 POST、WebSocket 合并、`/voice/text/chat` 与回复展示。
- `trends-and-app-version`：趋势 `deviceNo`、未登录遮罩与按钮；远程版本检查 GET 契约。

### Modified Capabilities

- （无）根目录 `openspec/specs/` 尚无已归档基线；与旧 Mock 行为的差异由本变更 **ADDED** 能力覆盖，实现阶段再替换 `Mock*Repository`。

## Impact

- 客户端：`repositories.dart`、各 `*Repository` 实现、`dio`/`http`、WebSocket 客户端、`session`、路由与 **主页/历史/趋势/设置/登录** 等页面。
- 服务端：按本变更 `design.md` 与 `specs/**` 对齐 path、字段名与 WebSocket 消息；OAuth 细节由服务端封装，契约中仅保留占位说明。
