## MODIFIED Requirements

### Requirement: Quota and auth errors use dialog plus inline summary

For business code 40301, the client MUST continue to show the existing glass login guidance via `handleAiQuotaBusinessCode` (after silent refresh rules), and MUST also set the assistant inline error summary consistent with the dialog message. For business code 40302, the client MUST NOT show a quota-exhausted glass dialog; the assistant MAY show a generic inline error that MUST NOT be framed as monthly quota UX. 对 40301 **必须** 继续登录引导（遵循 silent refresh）；对 40302 **不得** 弹出额度用尽框，inline MAY 使用通用错误且 **不得** 作为额度产品文案。

#### Scenario: Quota exhausted 40302 without quota dialog

- **WHEN** WS error 帧 `code == 40302`
- **THEN** MUST NOT 弹出「本月额度已用完」类弹框
- **AND** assistant inline MAY 展示通用错误摘要（MUST NOT 唯一依赖「额度用完」产品语义）

#### Scenario: Not logged in 40301

- **WHEN** WS error 帧 `code == 40301` 且 silent refresh 失败
- **THEN** **必须**弹出登录引导弹框
- **AND** assistant inline **必须**展示等价摘要（如「请先登录账号」）

### Requirement: Inline assistant error bubble on WebSocket error

When a companion/clinic question turn fails with a WebSocket error during streaming, the smart companion screen MUST retain the assistant message row and display an inline error state with the parsed user message instead of removing the assistant bubble. 当进行中的陪伴轮次收到 WS error 时，页面**必须**保留助手消息行并以 **inline error** 展示解析后的文案；**不得**调用 `removeAssistant` 静默删除助手气泡。

#### Scenario: Error during active streaming turn

- **WHEN** 用户已发送 question且 `_activeAssistant != null`，且收到 `type:error`
- **THEN** 对应 assistant **必须**标记为 error 态并展示 `errorMessage`
- **AND** 用户 question 行**必须**仍可见
- **AND** **不得**展示「本回答仅供参考，不能替代医生诊断」

#### Scenario: Partial thinking preserved before error

- **WHEN** error 到达前 assistant 已收到非空 `thinking` 且无成功 `answer`
- **THEN** thinking 块** MAY** 仍展示
- **AND** error 块**必须**展示于 thinking 之后或替代空 answer 区

#### Scenario: Error bubble visual distinct from success answer

- **WHEN** assistant 处于 error 态
- **THEN** 文案**必须**以纯文本展示（**不得**经 Markdown 渲染）
- **AND** **必须**使用与成功答案可区分的 error/警示视觉（如 `errorContainer` + error 图标）
