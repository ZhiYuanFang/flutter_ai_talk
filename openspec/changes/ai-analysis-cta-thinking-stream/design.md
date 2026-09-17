## Context

喂养工作台 CTA 已在正文下，成长仍在 AppBar；喂养用量文案未消费 Go 已返回的 `usedToday`/`dailyLimit`。值得留意详情用壳主题色，并暴露忽略/追问。成长 turn 已有 SSE，但 Python 仅 `with_node_thinking` 编排 caption + `llm_client.invoke`；care-alert 全链阻塞 JSON。兄弟仓：`go_ai_talk`、`python_ai_talk`。

## Goals / Non-Goals

**Goals:**

- 喂养/成长工作台 CTA +「今日已用 x/y 次」同构（正文下）。
- 值得留意详情：care 功能色；隐藏忽略/追问。
- 成长：LLM thinking token 经既有 SSE 透出。
- 喂养：分析过程有流式思考 UI（新 SSE 路径）。

**Non-Goals:**

- 不重做开通/VIP/日限业务规则（沿用现网上限与错误码）。
- 不恢复值得留意追问 clinic 产品打磨（仅隐藏入口）。
- 不把忽略/追问服务端 API 删除（可保留，客户端不展示）。
- 不新建 `**/test/**`。
- 不改 home-shell notify/version 编排。

## Decisions

1. **CTA 布局以喂养为准**  
   成长去掉 AppBar `actions` CTA；在 `ListView`/`Column` 正文下方居中放置主按钮 + 小号 `usageCopy`。流式/提问中隐藏 CTA（行为与现网 AppBar 隐藏一致）。覆盖未归档 `feeding-workspace-flat-parity` 的「AppBar CTA」要求。

2. **用量文案统一**  
   文案：`今日已用 $usedToday/$dailyLimit 次`。成长沿用 `GrowthTrajectoryUiState.usageCopy`。喂养：扩展 `CareAlertRepository.fetchDaily`（或结果类型）解析 `usedToday`/`dailyLimit`，写入 `PredictionCareAlertState`；CTA 下展示。无快照时可用默认 limit=5、used=0 或隐藏数字行直至首次 daily 返回。

3. **值得留意详情 chrome**  
   `resolveFeatureColor(context, careFeature)` 驱动 AppBar/正文强调/玻璃描边等可见强调色；底栏忽略/追问 **不渲染**（feature flag 或常量 `false`，便于日后打开）。

4. **成长 LLM thinking（Python 为主）**  
   在 `plan_next` / `confirm_prior` / `generate_trajectory` 等 LLM 节点：改 `llm_client.stream(..., thinking_enabled=True)`（对齐 clinic/tip）。reasoning 增量写入 custom stream（**禁止**每个 token 套 `\r` 编排清屏；仅节点级 `emit_thinking` 用 `\r`）。JSON/结果仍本地聚合后发 question/result。模型需具备 reasoning 输出；若 SKU 无 thinking，至少保持编排 caption。

5. **Care-alert 思考 SSE**  
   - **Python**：分析图节点包 `with_node_thinking`；LLM 节点尽量 stream thinking；最终 `items` 经 SSE `result`（或 `done`+JSON）发出；保留非流式 `POST /v1/care-alert/analyze` 供兼容或内部调用可选。  
   - **Go**：新增设备侧 SSE（建议 `GET`/`POST /device/api/care-alert/daily/stream?force=1` 或 turn 风格），代理 Python、flush thinking；日限/单飞/锁与现 `CareAlertDaily` 一致；结束后仍可写日缓存。  
   - **Flutter**：手动「AI智能分析」改走 SSE；复用 `applyThinkingStageDelta` + 类成长 `_ThinkingPane`；结束后用 result 刷新列表与 usedToday。旧阻塞 GET 可留作无 force 拉缓存。

6. **实现顺序建议**  
   UI（CTA/用量/详情）→ 成长 LLM stream → care-alert SSE 全链，便于分段验收。

## Risks / Trade-offs

- **[Risk] 模型无 reasoning_content** → 仅见编排 caption；验收时确认模型 SKU。  
- **[Risk] care-alert SSE 超时/代理缓冲** → 对齐 growth flush；客户端 90s+ 可配置。  
- **[Risk] 与 flat-parity AppBar 规格冲突** → proposal 已声明以本变更为准。  
- **[Trade-off] 一 change 跨三仓** → tasks 按仓分组；部署需 Go/Python/App 同发或兼容旧 JSON。

## Migration Plan

- 客户端先上 UI 无害。  
- Growth LLM stream：仅 Python 发版即可增强。  
- Care SSE：需 Go+Python+App 协同；App 可 feature 检测失败回退阻塞 GET（可选，默认直接 SSE）。  
- 回滚：隐藏 SSE 入口、恢复 invoke；UI 回滚独立。

## Open Questions

- （已定）用量文案与成长同款「今日已用 x/y 次」。  
- （已定）忽略/追问先隐藏而非删除 API。  
- Care SSE 路径命名实现时与现有 `/daily` 对齐即可，不必阻塞开做。
