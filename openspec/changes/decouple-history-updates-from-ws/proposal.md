# Decouple history updates from WebSocket

## 摘要

将历史事件的“停止计时 / 编辑 / 更新”类操作从依赖历史 WebSocket (history WS) 的路径中解耦，改为以 HTTP 请求为主路径：UI 先行，立即触发 HTTP 更新；HTTP 成功则保留并校验 UI，HTTP 失败则回退 UI 并提示用户。语音相关的喂养/AI 路径仍保留对 history WS 的依赖。

## 动机（Why）

- 实际产品场景中，按钮触发的事件（新增/停止计时/编辑）对实时性要求低，HTTP 请求即可满足一致性需求；依赖 WS 增加了复杂性与失败面，导致 optimistic 行在 WS 未就绪时长时间停留“同步中”。
- 当前问题：当 WS 未就绪或连接不稳定时，按钮产生的 optimistic pending 行会被留存或走持久化 outbox，影响用户体验并引入额外实现复杂度。

## 目标（What）

- 按钮操作（新增、停止计时、编辑、修改备注等）优先走 HTTP；若 HTTP 成功则替换/保留 UI；若 HTTP 失败则回退 UI 并提示用户。
- 保留语音输入/ASR 触发路径对 history WS 的依赖（语音转写/AI 交互仍需要 WS）。
- 保持现有的历史 WS 订阅用于服务器推送和历史流合并（不移除 WS 订阅本身）。

## 范围与非范围

- In-scope:
  - `app/lib/ui/home_screen.dart` 中停止计时（`_stopActiveTimer`）与按钮更新路径的行为调整。
  - 其他走 `enqueueHistoryUpdateOutbox` 的 UI 路径审查并按需改为 HTTP 优先。
  - OpenSpec 文档与测试用例更新。

- Out-of-scope（本变更不立即完成）：
  - 大规模移除或重构持久化 outbox 机制（`history_outbox_store.dart`、`history_outbox_flusher.dart`）：保留为后备，必要时在后续变更中处理。

## 成功指标

- 在 WS 不就绪的情况下，用户通过按钮触发的停止计时/编辑操作不会留下长时间的 pending 行；失败会即时回退并提示。
- 语音输入路径继续依赖 WS，语音功能不受影响。

## 兼容性与风险

- 风险：在网络不稳定时频繁回退会造成闪烁及用户困惑；需在 UI 提示和重试策略上做好权衡。
- 风险：若服务器对重复/并发更新敏感，需保证后端具有幂等性或在前端增加防重策略。

---

提出者: 自动生成 OpenSpec 草案

