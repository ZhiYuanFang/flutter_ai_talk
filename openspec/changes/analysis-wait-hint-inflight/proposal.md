## Why

喂养记录分析与成长轨迹的智能体思考往往要很久，页面只显示「正在思考」，用户不知道可以先离开、回来再看。喂养页还有一个具体故障：点「AI智能分析」后退出再进，正文被历史记录盖掉，按钮看起来能点，再点却没有任何反馈——上一次请求仍在客户端单飞里，第二次点击根本没发出去。

## What Changes

- **两个详情页**在思考进行中展示固定提示：正在为宝宝做针对性分析，用时较久，可以先去做别的，过一会儿回来看结果。提示不写进会被思考增量清掉的流式正文。
- **成长轨迹**：该提示只在流式思考阶段出现；提问作答阶段不出现（用户必须留在页上答题）。
- **喂养记录分析**：分析尚未结束时再进页，不得用历史 latest 覆盖进行中状态，须继续展示思考区与上述提示。
- **喂养记录分析**：进行中再次点击「AI智能分析」不得静默无效；须 Toast「上一次分析还在进行，请稍后再试」，且不得再发一次生成请求。
- **不在本次范围**：成长轨迹 `MemorySaver` 断点内存释放；Go / Python 锁与接口文案（本故障的第二次点击未到达服务端）。

## Capabilities

### New Capabilities

- 无。

### Modified Capabilities

- `prediction-care-alert`：喂养工作台思考中展示等待提示；进行中再进页保持思考态；重复点击须提示上一次仍在分析。
- `growth-trajectory-predict`：成长工作台仅在流式思考阶段展示同等等待提示；提问阶段不展示。

## Impact

- **Flutter**：`feeding_analysis_screen.dart`、`prediction_care_alert_provider.dart`（`hydrateLatestOnly` 不得覆盖进行中分析；`refreshDailyManual` 在单飞占用时返回可 Toast 文案）、`growth_trajectory_screen.dart`。
- **Go / Python**：不改。
- **测试**：不新建 `**/test/**`；手工验收思考提示、退出再进、重复点击 Toast。
- **基线**：`openspec/specs/v2.1.0.md` 尚未收录这两项能力；行为以当前未归档变更（`ai-analysis-cta-thinking-stream`、`feeding-workspace-flat-parity`、`growth-trajectory-predict`）及现网代码为准，本变更只追加等待提示与喂养进行中重入语义。
