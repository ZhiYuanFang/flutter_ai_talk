# Tasks: confirm-ui-adaptation

1. 分析 Flutter 交互流程
   - 确认 Flutter 当前走 `sendCommand(text)` → `POST /device/history/api/chat` → `{reply}` 的调用链。
   - 确认 go 侧 `chatWithResult` 在 WS 模式下内部处理 confirm 逻辑，返回的 reply 即确认话术。
   - 结论：Flutter 与 go 之间的请求/响应契约未变，confirm 流程对 Flutter 透明。
   - Status: ✅ 已完成（见 proposal.md 与 design.md 的交互流程图）。

2. 确认无需修改 sendCommand
   - 检查 `sendCommand` 是否需要新增 `intent` / `confirm_token` 等参数。
   - 结论：不需要。go 侧基于 pending 状态自动判定用户下一条消息的意图，Flutter 只需透传文本。
   - Status: ✅ 已确认（见 design.md「为什么不新增 analyzeIntent / confirmIntent Repository 方法」）。

3. 确认无需新增 Repository 方法
   - 评估是否需要新增 `analyzeIntent` / `confirmIntent` 方法。
   - 结论：不需要。go 没有暴露独立的 intent/confirm 端点；拆分方法会引入跨端状态同步问题。
   - Status: ✅ 已确认（见 design.md 同名章节的四维度分析）。

4. 确认无需新增 UI 组件
   - 评估 `showGlassConfirmDialog` 是否需要启用，或是否需要新增 confirm 专用组件。
   - 结论：不需要。WS 模式下确认话术作为普通聊天气泡展示，走现有渲染路径；`showGlassConfirmDialog` 仅适用于 HTTP 模式。
   - Status: ✅ 已确认（见 design.md「为什么不新增 UI 组件」）。

5. 创建变更文档
   - 创建 `openspec/changes/confirm-ui-adaptation/proposal.md`：记录变更概述、结论、验收标准。
   - 创建 `openspec/changes/confirm-ui-adaptation/design.md`：记录交互流程图、不新增方法/组件的理由、HTTP 模式备选方案。
   - 创建 `openspec/changes/confirm-ui-adaptation/tasks.md`：本文件，记录分析任务清单。
   - Status: ✅ 已完成。

6. Flutter 代码改动
   - 无。本变更不修改任何 Flutter 源码。
   - Status: ✅ 不适用（WS 模式下无需改动）。

---

Done-by: opsx-propose
