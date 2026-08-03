# Design: confirm-ui-adaptation

## Summary
WS 模式下，confirm 流程的意图判定与状态管理完全由 go_ai_talk 侧承担，Flutter 仅作为消息收发与展示通道。本设计文档说明为什么 Flutter 不需要新增 `analyzeIntent` / `confirmIntent` Repository 方法、不需要新增 UI 组件，并给出未来切换到 HTTP 模式时的备选适配方案。

## WS 模式下的 Flutter 交互流程

```
┌─────────────┐         sendCommand(text)          ┌─────────────┐         chatWithResult        ┌─────────────┐
│   Flutter   │  ───────────────────────────────▶  │     go      │  ──────────────────────────▶ │   Python    │
│  Home UI    │   POST /device/history/api/chat    │  ai_talk    │      HTTP / WS to py         │   ai_talk    │
└─────────────┘                                     └─────────────┘                               └─────────────┘
       ▲                                                  │   │
       │              { reply: "..." }                    │   │
       │  ◀───────────────────────────────────────────────┘   │
       │                                                      │  need_confirm=true?
       │  展示 reply（普通话术 or 确认话术）                    │  ├─ 是：go 内部保存 pending，返回确认话术
       │                                                      │  │     用户下一条消息 → go 自动判定 confirm/reject
       │                                                      │  │     go 内部调用 Python confirm 接口
       │                                                      │  └─ 否：返回普通 reply
       │                                                      ▼
       │  用户输入"确认"/"取消"或其他自然语言                  ▼
       │  ── 再次 sendCommand(text) ──────────────────▶  go 判定意图
       │  ◀──────────── { reply: "执行结果..." } ──────────────
```

关键点：
1. Flutter 调用的接口始终是 `POST /device/history/api/chat`，请求/响应契约不变。
2. Flutter 无法（也无需）区分当前 reply 是"普通话术"还是"确认话术"——两者在 UI 上都是一条聊天气泡。
3. confirm/reject 的判定由 go 基于 pending 状态自动完成，Flutter 不需要传递额外的 `intent` 或 `confirm_token` 字段。

## 为什么不新增 analyzeIntent / confirmIntent Repository 方法

| 维度 | 分析 |
| --- | --- |
| 接口契约 | go 的 `/device/history/api/chat` 已经在内部完成意图判定和 confirm 调用，对外只暴露 `{reply}`。Flutter 若新增 `analyzeIntent` / `confirmIntent` 方法，将没有对应的 go 端点可调用。 |
| 状态归属 | pending 状态保存在 go 内存中，Flutter 不持有 confirm token。拆分独立方法会要求 go 暴露 pending 状态与 confirm 端点，引入跨端状态同步问题。 |
| 用户体验 | 用户用自然语言回复即可，不需要前端先"分析意图"再"确认"。拆分方法会让交互变成两步 RPC，增加延迟与失败点。 |
| 复用性 | 当前 `sendCommand` 已能覆盖所有用户输入场景（含 confirm/reject），新增方法是冗余抽象。 |

结论：保持 `sendCommand(text)` 单一入口，confirm 逻辑对 Flutter 透明。

## 为什么不新增 UI 组件

Flutter 仓库中已存在 `showGlassConfirmDialog` 组件，但本场景**不应使用**：

| 维度 | 分析 |
| --- | --- |
| 触发条件 | `showGlassConfirmDialog` 适用于 HTTP 模式——前端拿到 `need_confirm=true` 后弹出独立确认框，用户点击按钮再走显式 confirm 接口。WS 模式下，go 返回的是"话术"而非"确认信号"，没有可触发弹窗的标志位。 |
| 交互形态 | WS 模式下确认是自然语言对话（用户输入"确认"/"取消"），而非按钮点击。强行弹窗会破坏对话流。 |
| 状态可见性 | Flutter 不知道当前是否处于 pending confirm 状态，无法决定何时弹窗、何时关闭。 |
| 一致性 | 把确认话术作为普通聊天气泡展示，与语音/文字输入路径的渲染逻辑保持一致，避免分叉。 |

结论：不新增、也不启用任何 confirm 专用 UI 组件；确认话术走现有聊天气泡渲染路径。

## Future: HTTP 模式备选适配方案

若未来 go 从 WS 模式切回 HTTP 模式（即 go 不再内部处理 confirm，而是把 `need_confirm` 透传给前端），Flutter 需要做如下适配。本节作为备选方案记录，当前**不实施**。

### 1. 响应契约扩展
go 的 `/device/history/api/chat` 响应需要新增字段：
```json
{
  "reply": "...",
  "need_confirm": false,
  "confirm_token": "optional-token"
}
```

### 2. Repository 层新增方法
在 `remote_feed_repository.dart` 或对应的 chat repository 中新增：
- `analyzeIntent(String text)`：调用 go 暴露的意图判定端点（如 `POST /device/history/api/intent`），返回 `intent: "confirm" | "reject" | "normal"`。
- `confirmIntent(String confirmToken, bool confirmed)`：调用 go 的显式 confirm 端点（如 `POST /device/history/api/confirm`），返回执行结果 reply。

### 3. UI 层启用 showGlassConfirmDialog
- 当 `sendCommand` 返回 `need_confirm=true` 时，调用 `showGlassConfirmDialog` 弹出确认框。
- 用户点击"确认"/"取消"按钮后，调用 `confirmIntent(token, true/false)`，把结果 reply 渲染为聊天气泡。
- 需要处理用户关闭弹窗（既不确认也不取消）的超时/兜底逻辑。

### 4. 风险点
- 需要在 Flutter 侧维护 `confirm_token` 状态（与 go 的 pending 状态对应）。
- 弹窗与对话流的切换需要平滑过渡，避免 UI 抖动。
- 多轮 confirm 场景（confirm 之后又触发新的 need_confirm）需要状态机管理。

## Files & Functions to change
- 无代码改动。本变更仅产出文档。

## Edge cases
- 用户在 confirm pending 期间发送与确认无关的内容：由 go 侧判定（可能视为 reject 或普通对话），Flutter 行为不变。
- 网络抖动导致 confirm 回包丢失：由 go 侧的重试/超时机制处理，Flutter 仅展示当前收到的 reply。
- 多设备并发 confirm：pending 状态以设备为维度由 go 管理，Flutter 无需感知。

## Tests
- 无需新增测试（无代码改动）。
- QA 验证场景：用户发送触发 confirm 的指令 → 收到确认话术 → 回复"确认" → 收到执行结果；回复"取消" → 收到取消提示；回复无关内容 → 由 go 判定。

---

Created-by: opsx-propose
