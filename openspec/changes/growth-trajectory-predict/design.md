## Context

AI 分析页（`/prediction/ai-analysis`）已上线喂养记录分析（care-alert），成长轨迹仅为浅占位。兄弟仓已有可复用模式：Go cash 功能开通 + voice 调 Python；Python LangGraph + `with_node_thinking` / `\r` 编排字幕；Flutter `applyThinkingStageDelta`、VIP 合成开通、`markdown_widget`。本变更把成长轨迹做成跨 Flutter / Go / Python 的完整竖切；客户端只请求 Go。

## Goals / Non-Goals

**Goals:**

- 卡片内完成开通、预测、多轮问答（含历史确认与防选错再确认）、流式思考、7 天 Markdown 结果与重新预测。
- 商业化：邀请默认 7 天；支付 ¥19 / 30 天（无永久）；VIP 免开通；无喂养资格门闸。
- Go 控日限（默认 5，可后台改）；仅成功落库计次；按 `device_no` 存最新结果与最新反馈。
- Python LangGraph + checkpointer interrupt；SSE 推 thinking / question / result；提示词只约束任务与结构化产物。

**Non-Goals:**

- 不改喂养记录分析（care-alert）日限与资格逻辑。
- 不引入 Flutter→Python 直连；不以 WebSocket 做轨迹会话（本期 SSE）。
- 不规定 LLM 思考写作方式；提示词不出现 `\r`。
- 不自动新建 `**/test/**`。

## Decisions

### 1. 传输：HTTP SSE turn，不用业务 WS

- **选择**：`POST .../growth-trajectory/turn` SSE（事件：`thinking` / `question` / `result` / `error` / `done`）；`GET .../latest` 同步取最新 Markdown。
- **理由**：对齐 clinic/intent 流式习惯；避免新鉴权 WS 通道与 `ws-transport-governance` 额外成本。
- **备选**：Clinic 式 WS — 驳回（轨迹非常驻会话）。

### 2. featureId 与商业参数

- **选择**：`growth_trajectory_predict`；邀请 `invite_duration_days=7`；SKU `price_fen=1900`、`duration_days=30`；不种子永久产品；access = `entitlement ∨ VIP`。
- **理由**：产品明确无永久、VIP 免开通；与 care-alert 同 VIP 合成模式。
- **备选**：永久 SKU — 驳回。

### 3. 无喂养资格门闸

- **选择**：不绑定 `feeding_eligibility_scene`；缺喂养时 Python 自适应弱化喂养段。
- **理由**：产品明确不要求连续喂养日。

### 4. 日限语义

- **选择**：Redis（或等价）按上海日 + `device_no` 计数；仅 `result` 成功落库后 INCR；问答 submit 不计；超限开流前返回业务错误，Flutter Toast `message`。
- **备选**：客户端 prefs 藏按钮 — 驳回（产品要求 Go 控、Flutter 不控）。

### 5. 落库

- **选择**：MySQL（或 Go 既有库）按 `device_no` 存「最新结果 Markdown」与「最新反馈 JSON」；进页 `latest` 直出。
- **理由**：跨日仍要展示；不同于 care-alert 仅 Redis 日缓存。

### 6. LangGraph 状态机与轮次

```
confirm_prior（有历史反馈）——不计入 6
        ↓ 之后必须 plan_next（禁止直 generate）
ask / reconfirm ——计入 structured_round（上限 6）
        ↓ round==6 仍不够
final_free_text（固定 1 次，声明最后一次）→ generate
```

- `choice.choices` 长度必须为 2；文案模型自定义。
- `reconfirm` 计入 6；`confirm_prior` 不计入。

### 7. 思考与 `\r`

- **选择**：节点字幕经 `emit_thinking` → `ensure_orchestration_thinking_content` 段首 `\r`；LLM 思考增量全量透出，提示词不指导思考写法、不含 `\r`。
- **Flutter**：复用 `applyThinkingStageDelta`；question/result 到达后清空并隐藏思考区；思考区自适应高度（设合理 max）。

### 8. 跨仓分工

| 仓 | 职责 |
|----|------|
| flutter_ai_talk | UI 状态机、SSE 消费、开通、Toast |
| go_ai_talk | 权益、日限、落库、SSE 透传、调 Python |
| python_ai_talk | Graph、interrupt、提示词、SSE 事件 |

本仓 OpenSpec 以 Flutter 行为 + 契约摘要验收；Go/Python 任务在 `tasks.md` 标明跨仓路径，实现时在对应仓落地。

## Risks / Trade-offs

- [SSE 中断导致 session 悬挂] → Go/Python session TTL；客户端失败可 restart；single-flight 防连点。
- [reconfirm 耗尽 6 轮过早进入 final_free_text] → 产品已接受 reconfirm 计入 6；提示词控制随意 reconfirm。
- [三仓发布不同步] → 契约版本字段或能力探测；Flutter 对未知 phase 降级 Toast。
- [思考过长撑破卡片] → 自适应高度 + maxHeight + 内部滚动。

## Migration Plan

1. Go 先种子 feature_def/product 与表/日限配置（可先关 catalog status 或客户端未发版不可见）。
2. Python 上线 `/v1/growth-trajectory/*`。
3. Go 接通 SSE 与落库。
4. Flutter 替换占位并接 API。
5. 回滚：catalog 下线 feature 或客户端隐藏模块；已落库数据保留无害。

## Open Questions

- Admin 日限配置挂在既有 `ai_quota_*` 还是独立配置键（实现时选 Go 侧更贴近日限的表）。
- `final_free_text` 用户跳过/空提交时：强制再提示一次或直接 generate（建议空提交 Toast 且不结束会话）。
