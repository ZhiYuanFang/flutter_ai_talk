## Context

客户端多处对同一语义字段同时兼容 camelCase 与 snake_case（例如 `deviceNo` / `device_no`）。`device_login` 请求体当前使用 `device_no`；WebSocket 首包使用 `access_token`；版本接口解析 `downloadUrl` / `download_url`。产品要求统一为 **camelCase**（与 `deviceNo` 命名风格一致）。

## Goals / Non-Goals

**Goals:**

- 梳理所有发往网关的 JSON / 关键 query，列出并修正与 camelCase 不一致的键名。
- 梳理所有从 `data` 或业务 Map 读取的字段，统一读取路径与命名约定；与后端确认后移除不再需要的 snake 兼容代码。
- 更新文档与注释，避免向开发者传播 snake 作为「正式契约」。

**Non-Goals:**

- 不改变 HTTP 头 `Authorization: Bearer` 等非 JSON body 约定。
- 不强制重命名 Dart 本地变量、SharedPreferences 私有 key、路由 query 名（除非其直接序列化为网关 JSON）。

## Decisions

1. **命名规范**  
   网关业务 JSON（含 WebSocket 业务帧内对象）键名采用 **lowerCamelCase**，与常见 Java/Spring `@JsonProperty` 省略时及前端习惯一致。专有缩写保持连续大写规则由项目组统一（如 `deviceNo`、`accessToken`）。

2. **出站修正清单（当前代码审计，实施时以 tasks 勾选为准）**  
   - `POST /device/app/api/device_login`：body 键 **`deviceNo`**（替换 `device_no`）。  
   - WebSocket 首帧 JSON：`**accessToken**`（替换 `access_token`），`deviceNo` 保持不变。  
   - 其余 HTTP body/query（如 `bindwx` 的 `deviceNo`、`chat` 的 `deviceNo`/`transcript`、历史列表 query）已为 camelCase，仅做回归确认。

3. **入站解析策略**  
   - **阶段 A（推荐先落地）**：读取时 **优先 camelCase**；若后端尚未全量切换，可暂时保留 snake 作为第二候选，但在代码中集中到小工具函数（如 `String? pickStr(Map m, String camel, [String? snake])`），并打 `// TODO(api): remove snake fallback when gateway >= vX`。  
   - **阶段 B**：后端确认全量 camel 后，删除 snake 分支并更新 spec 为「不得接受 snake」。

4. **与后端对齐**  
   实施前必须确认：`device_login`、`token/refresh` 响应、`version/check` 响应、历史列表项、WebSocket `auth` 等是否已全部 camelCase。若否，客户端不可单独删除入站 snake 兼容。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 仅改客户端导致登录/WS 失败 | 与后端同学对齐发布顺序；必要时阶段 A 双读双写。 |
| 遗漏隐藏字段 | tasks 中全仓 `grep` + 联调用例覆盖。 |

## Migration Plan

1. 后端或网关发布 camel 新字段（或双写）。  
2. 客户端发出 camel 出站 + 阶段 A 入站。  
3. 观测无 snake 流量后，阶段 B 删兼容。

## Open Questions

- 网关是否仍存在 **仅 snake** 的老节点（灰度环境）？若有，兼容窗口多长？
