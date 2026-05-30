## Context

- 约定 **Base**：`https://pangbao.cuplay.top`（联调环境；生产是否全站 HTTPS 由部署决定，客户端通过 `API_BASE_URL` 等配置注入）。
- 所有 REST 响应：**HTTP 状态码恒为 `200`**，业务成败看 **`code`**；**`code == 0`** 成功，**非 0** 失败；失败时 **`data` 可为 `null`**，**`message` 为人类可读失败原因**，客户端 **Toast**。
- **OAuth / code 换 token**：由服务端封装，客户端只对接你们暴露的登录入口（具体 path 不写死在 spec，以服务端文档为准，本仓库 `design` 仅描述职责划分）。

## Goals / Non-Goals

**Goals:**

- 用 **OpenSpec** 固化联调契约，便于 Flutter 与后端 **并行开发、联调验收**。
- **WebSocket** 作为实时通道；消息体中带业务 **`id`**，客户端与当前列表比对 **同 id 更新、否则新增**。
- 客户端字段统一：**服务端 `device_no` → 客户端 `deviceNo`（string）**。

**Non-Goals:**

- 本变更 **不实现** 具体 Dart 代码（实现见 `tasks.md` 后续 `/opsx:apply`）。
- 不在此文档定义微信开放平台各步参数（由服务端封装）。

## Decisions

| 主题 | 决策 | 说明 |
|------|------|------|
| HTTP 客户端 | 推荐 **Dio**（或项目已有栈） | 统一拦截器解析 `code/message/data`；非 0 抛业务异常或返回 Result，由 UI Toast。 |
| WebSocket URL | **待定**，与后端共定 | 建议形态：`ws(s)://{host}/device/.../stream`；与 REST 同域便于 Cookie/证书策略（若不用 Cookie 则首包带 token）。 |
| WS 鉴权 | **首条 JSON 消息鉴权** | 例如 `{ "type":"auth", "access_token":"..." }`，服务端回 `{ "type":"auth_ok" }` 后再推业务；**未登录不建连**；**无有效 `deviceNo` 不建连**（与「绑定后才可请求业务」一致）。 |
| 历史 `id` 类型 | 服务端 **int64**；客户端 **字符串化** 存储 | 避免 JS/Web 大整数精度问题；与现有 `HistoryRecord.id` 对齐时统一 `toString()`。 |
| 版本检查 | 采用变更内提议的 **GET** `/device/app/api/version/check` | `data` 形状见 `trends-and-app-version` spec；后端可改 path，字段名建议保留。 |

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| HTTP 恒 200 易忽略网络层错误 | 对 **连接失败、超时** 单独 Toast「网络异常」；与业务 `code` 分支分离。 |
| Web 与 App WebSocket 行为差异 | 用同一抽象类 + 平台实现；关注浏览器后台挂起断线重连。 |
| `eventNumber`/`remark` 与旧「动作」单行文案不一致 | UI 层组合展示或迭代产品文案，spec 要求「完整展示服务端返回字段」。 |

## Migration Plan

1. 先实现 **envelope 拦截器** 与 **用户详情 + deviceNo 缓存**。  
2. 再换 **历史列表 + 更新**；最后 **WS + 语音 + 趋势 + 版本**。  
3. Mock 保留开关或 flavor，便于无网演示（可选，非本 spec 强制）。

## Open Questions

- WebSocket **正式 path** 与 **每条业务消息** 的 `type` 枚举（需后端给出一版 JSON 样例）。  
- `GET .../list` 在 **已登录但未绑定** 时，服务端返回的 `code`/`message` 是否与「未登录」区分（客户端可统一走「请绑定宝宝信息」+ 跳转绑定，若后端区分可细化 Toast）。
