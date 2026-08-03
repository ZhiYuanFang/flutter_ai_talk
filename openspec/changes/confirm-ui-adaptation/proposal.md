# Proposal: confirm-ui-adaptation

## What
分析 Flutter 侧在 go_ai_talk 切换到 WS 模式后的 confirm 流程适配需求，并记录分析结论。本变更**不修改任何 Flutter 代码**，仅以文档形式固化结论。

## Why
go_ai_talk 侧已适配 confirm 流程（走 WS 模式）。go 的 `/device/history/api/chat` 接口（Flutter 调用的 `sendCommand`）的响应行为发生变化：
- 当 Python 返回 `need_confirm=true` 时，go 会返回确认话术作为 `reply`，同时在内部保存 pending 状态。
- 用户下一条消息会被 go 自动判定为 confirm/reject，go 内部调用 Python 的 confirm 接口。
- Flutter 侧**无需调用独立的 confirm 接口**，走 WS 模式时 Flutter 只需：
  1. 正常发送消息（`sendCommand`）。
  2. 如果回复内容是确认话术，直接展示在聊天界面。
  3. 用户回复"确认"/"取消"等自然语言，go 自动处理。

## Conclusion
**Flutter 侧无需代码修改**，WS 模式下 confirm 流程对 Flutter 透明。原因：

1. Flutter 当前走 `sendCommand(text)` → `POST /device/history/api/chat` → 返回 `{reply: "..."}`，契约未变。
2. go 侧在 `chatWithResult` 中处理 confirm 逻辑，返回的 `reply` 即是确认话术，Flutter 仅作为展示方。
3. 用户下一条消息（"确认"/"取消"）通过同样的 `sendCommand` 发送，go 自动判定意图并走 confirm/reject 分支。
4. Flutter 中已存在的 `showGlassConfirmDialog` 组件**不需要使用**（因为 go 走 WS 模式而非 HTTP 模式，不需要前端弹出独立确认框）。

## Scope
- 影响：无代码改动；仅新增 OpenSpec 变更文档（proposal/design/tasks）。
- 行为变化：无。Flutter 侧交互行为与当前一致。

## Acceptance criteria
- 文档清晰说明 WS 模式下 Flutter 的交互流程。
- 文档说明为什么不新增 `analyzeIntent` / `confirmIntent` Repository 方法。
- 文档说明为什么不新增 UI 组件。
- 文档给出未来如切换到 HTTP 模式时的备选适配方案。
- Flutter 仓库中没有任何源码改动。

## Risk / Mitigation
- 风险：未来若 go 侧从 WS 模式切回 HTTP 模式，需要前端引入显式 confirm 组件与独立接口调用。
  - 缓解：design.md 中保留 HTTP 模式备选方案，便于后续切换时参考。
- 风险：用户使用非"确认/取消"关键词（如"好的"、"不要"）导致 go 侧判定语义模糊。
  - 缓解：由 go 侧负责自然语言意图识别，Flutter 无需关心。

---

Created-by: opsx-propose
