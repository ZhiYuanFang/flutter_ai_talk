## Why

AI 分析子页布局与用量提示不一致：成长轨迹 CTA 仍在 AppBar，喂养已在正文下却只显示固定「每日最多 5 次」而非「今日已用 x/y」；值得留意详情仍跟 App 主题色且暴露未打磨的忽略/追问。同时喂养分析思考无流式，成长轨迹仅流式 LangGraph 编排 caption、未透出 LLM 思考，等待体验差。

## What Changes

- **成长工作台**：主 CTA（「轨迹预测」/「重新预测」）与「今日已用 x/y 次」从 AppBar 下移到正文下方（对齐喂养工作台）。
- **喂养工作台**：CTA 下用量文案改为与成长同款 **「今日已用 x/y 次」**（解析 Go `care-alert/daily` 已返回的 `usedToday`/`dailyLimit`，替换固定「每日最多 5 次」类文案）。
- **值得留意详情**：壳/强调色改跟 **喂养记录分析（care-alert）功能色**；底栏 **忽略 / 追问** 先隐藏（不暴露未打磨的智能对话）。
- **成长轨迹思考流**：保留编排阶段 caption；Python 打开 LLM `stream` + thinking，经既有 SSE `thinking` 透出至客户端。
- **喂养 / care-alert 思考流**：新增端到端流式思考（Flutter↔Go↔Python），生成日列表前实时展示思考过程，不再仅静态「正在思考中」。

## Capabilities

### New Capabilities

- `care-alert-thinking-stream`：care-alert 日分析 SSE（或等价）思考流契约与客户端展示。
- `care-alert-detail-chrome`：值得留意详情功能色与底栏动作显隐策略。

### Modified Capabilities

- `ai-analysis-page`：喂养/成长工作台 CTA 均在正文下；用量文案「今日已用 x/y 次」对齐。
- `prediction-care-alert`：喂养工作台用量来自服务端已用/上限；手动分析可伴随思考流（与新 capability 交叉引用）。
- `growth-trajectory-predict`：思考区 MUST 包含 LLM 思考增量（不仅编排 caption）；CTA 位置改正文下。

## Impact

- **Flutter**：`growth_trajectory_screen.dart`、`feeding_analysis_screen.dart`、`prediction_care_alert_screen.dart`、care-alert repository/provider、growth thinking pane 复用。
- **Go**（`go_ai_talk`）：care-alert 新增/扩展 SSE 代理；growth turn 透传不变或小改。
- **Python**（`python_ai_talk`）：growth 节点改 `llm_client.stream` + thinking；care-alert 图增加 thinking emit 与流式响应。
- **测试**：不新建 `**/test/**`；手工验收布局、用量、详情色/隐钮、两条思考流。
- **关联**：与未归档的 `feeding-workspace-flat-parity`（AppBar CTA）冲突处，以本变更为准（正文下 CTA）。
