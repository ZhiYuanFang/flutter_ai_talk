## Why

喂养记录分析、成长轨迹预测在接收 agent 流式思考时，限高 `SingleChildScrollView` 不跟滚，用户看不到最新文案。胖宝诊疗流式思考同样缺少统一跟底体验。需要抽出共享思考展示组件，并写入工程级强制约定，避免各 feature 再复制一套滚动逻辑。

## What Changes

- 新增共享组件（建议 `AiThinkingPane`）：流式 `text` 更新默认跟滚到底；用户上翻超过阈值则暂停跟滚，并在底部悬停向下按钮；**仅**点击该按钮恢复跟滚（用户自行滑回底部 **不得** 自动恢复）。
- 回底按钮颜色：调用方传入的功能/强调色优先；未传则用 `ColorScheme.primary`。
- 接入：**喂养记录分析**、**成长轨迹预测**（替换私有 `_FeedingThinkingPane` / `_ThinkingPane`）；**胖宝诊疗**流式与展开态思考正文改用同一组件（折叠尾部窗口仍遵守既有 fold 规格，不改用 jumpTo 跟流）。
- 在 `openspec/project.md` 与 `AGENTS.md` 增加「AI 思考展示组件（强制）」全局约束；新增 capability `ai-thinking-pane` 规格。
- 禁止在 `app/lib/**` 再新增平行的可滚动思考跟滚实现。

## Capabilities

### New Capabilities

- `ai-thinking-pane`：共享可滚动 AI 思考正文的跟滚、暂停、回底按钮与强制复用边界。

### Modified Capabilities

- `pangbao-clinic-thinking-fold`：流式展示与展开态全文滚动 MUST 使用共享 `AiThinkingPane`（或等价公开组件）；折叠尾部窗口行为保持既有 Requirement。

## Impact

- **Flutter**：新建 `app/lib/ui/widgets/ai_thinking_pane.dart`（名以实现为准）；改 `feeding_analysis_screen.dart`、`growth_trajectory_screen.dart`、`pangbao_ai_screen.dart`。
- **工程文档**：`openspec/project.md`、`AGENTS.md`。
- **API / Android / iOS native**：无。
- **测试**：不新建 `**/test/**`；手工验收三处流式跟底、上翻暂停、按钮恢复与配色。
