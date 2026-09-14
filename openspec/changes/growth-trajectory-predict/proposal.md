## Why

AI 分析页上的「成长轨迹预测」仍是浅占位，家长无法结合宝宝近况获得「未来 7 天可能发生什么 / 要注意什么」。需要与智能分析同页落地可开通、可多轮问答、可落库复看的完整能力，并由 Go 控日限、Python LangGraph 做断点追问与生成。

## What Changes

- **替换** AI 分析页成长轨迹浅占位为完整模块：开通门闸、历史结果展示、「轨迹预测 / 重新预测」、卡片内问答与流式思考、Markdown 结果。
- **新增** 功能开通项（建议 `featureId=growth_trajectory_predict`）：邀请码默认 **7 天**；支付默认 **¥19 / 有效期 30 天**；**无永久**开通 SKU；**VIP 免开通**；**无喂养资格天数门闸**。
- **新增** 客户端只调 Go 的轨迹会话 API：拉取最新结果；SSE turn（start / answer / restart）；日限错误仅 Toast；问答 submit **不计次**，仅完整预测成功落库计次（默认每日 5，后台可改）。
- **跨仓**：Go（cash 权益 + voice 编排/落库/日限）与 Python（LangGraph + checkpointer interrupt + 流式 thinking）同步实现；Flutter 不直连 Python。
- 问答：`choice` 恰好 **2** 个选项（文案由智能体定，不限「是/否」）；`free_text` 自由回答；历史反馈先 `confirm_prior`（**不计入** 6 轮）后再按月龄补问，禁止仅凭历史直出结果；不合理选择可 `reconfirm`（**计入** 6）；满 6 轮仍不够则 **最后一次** free_text 后强制生成。
- 思考：SSE 实时展示，卡片自适应高度；收到 question/result 后隐藏思考；`\r` 清空符仅编排层注入（复用 `applyThinkingStageDelta`），**提示词不规定思考写法、不出现 `\r`**。

## Capabilities

### New Capabilities

- `growth-trajectory-predict`：成长轨迹预测的开通、会话状态机、SSE 思考/问答/结果展示、日限 Toast、历史结果与重新预测、以及跨端契约摘要（Flutter 行为验收为主；Go/Python 实现约束写入 design/tasks）。

### Modified Capabilities

- `ai-analysis-page`：成长轨迹模块由「浅占位、无 HTTP」改为完整可交互模块（与喂养记录分析并列）；进页可拉取最新轨迹结果，不得因占位文案禁止 HTTP。

## Impact

- **Flutter**（本仓）：`ai_analysis_screen.dart` 占位替换；`feature_unlock_models` / catalog / VIP 合成；新 repository/provider；复用邀请弹框、`markdown_widget`、`applyThinkingStageDelta`；开通中心自动出卡。
- **Go**（`go_ai_talk`）：feature_def / product 种子与 Admin 日限；access（entitlement∨VIP）；`growth-trajectory` latest + SSE turn；按 `device_no` 落最新结果与最新反馈；成功落库后日限 INCR；调 Python。
- **Python**（`python_ai_talk`）：LangGraph 轨迹图、checkpointer 断点、SSE thinking/question/result、提示词（仅约束任务与结构化输出）。
- 对照基线 `openspec/specs/v2.1.0.md`；`ai-analysis-page` 目前主要在 change `ai-analysis-care-alert-relocate` / `ai-analysis-invite-grant-dialog` 中，本变更对其成长轨迹 Requirement 做增量修改。
- 不自动新建 `**/test/**`；本变更若仅 Flutter 无 Android 原生改动则不必强制 release APK（Go/Python 各自仓验证）。
