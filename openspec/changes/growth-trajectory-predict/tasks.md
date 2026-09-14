## 1. 跨仓契约对齐

- [x] 1.1 冻结 SSE 事件与 DTO：`thinking` / `question{id,prompt,format,choices[2]}` / `result{markdown}` / `error` / `done`；turn 入参 `action=start|answer|restart`、`sessionId`、`answer`
- [x] 1.2 约定日限错误码/文案、`featureId=growth_trajectory_predict`、horizonDays=7、轮次规则（confirm_prior 不计；reconfirm 计；6+final_free_text）

## 2. Go（go_ai_talk）— 开通与日限

- [x] 2.1 种子 `feature_def`（邀请 7 天）与付费 SKU（1900 分 / 30 天）；禁止永久 SKU；Admin 可改邀请/广告天数与日限默认 5
- [x] 2.2 access：`entitlement ∨ VIP`；不绑 feeding eligibility
- [x] 2.3 按 `device_no` 落库最新结果 Markdown + 最新反馈 JSON；`GET latest` API
- [x] 2.4 日限：成功落库后 INCR；问答不计；超限开流前拒绝

## 3. Python（python_ai_talk）— LangGraph 智能体

- [x] 3.1 新建 growth-trajectory 图：profile/可选弱喂养 → confirm_prior → plan_next → ask/reconfirm/final_free_text → generate；checkpointer + interrupt
- [x] 3.2 节点字幕 `thinking_messages` + `with_node_thinking`（编排层 `\r`）；LLM 思考全量透出；提示词不规定思考写法、不含 `\r`
- [x] 3.3 HTTP SSE：`/v1/growth-trajectory/turn`（及必要 resume）；输出 question/result 契约
- [x] 3.4 提示词：system + plan/ask/validate/confirm/generate（仅任务与 JSON/Markdown schema）

## 4. Go — 编排接通 Python

- [x] 4.1 `POST .../growth-trajectory/turn` SSE 透传 Python；注入 device 画像/可选喂养摘要/prior_feedback
- [x] 4.2 result 到达时写库并日限 +1；single-flight / session TTL
- [x] 4.3 Python 客户端超时与错误映射为 Flutter 可 Toast 的 message

## 5. Flutter — 开通与模型

- [x] 5.1 增加 `kFeatureIdGrowthTrajectoryPredict`；catalog/VIP 合成 `isFeatureEffectivelyUnlocked`
- [x] 5.2 AI 分析页/开通中心：邀请与支付文案（30 天，非永久）；无喂养资格进度

## 6. Flutter — 轨迹模块 UI 与会话

- [x] 6.1 替换 `_GrowthTrajectoryPlaceholder`：未开通引导 / latest 展示 /「轨迹预测」「重新预测」
- [x] 6.2 Repository + Provider：latest、SSE turn（start/answer/restart）、single-flight
- [x] 6.3 思考区：`applyThinkingStageDelta`、自适应高度、question/result 后隐藏
- [x] 6.4 问答 UI：双选项按钮（服务端文案）与 free_text 提交；空提交不结束为成功
- [x] 6.5 结果 Markdown 展示；日限/业务错误 Toast；本地不计日次

## 7. 验收

- [ ] 7.1 手工路径：邀请/支付/VIP、首轮问答、历史 confirm 后仍补问、reconfirm、满 6+末问、结果落库再进页、日限第 6 次拒、重新预测
- [x] 7.2 `openspec validate growth-trajectory-predict --strict` 通过
