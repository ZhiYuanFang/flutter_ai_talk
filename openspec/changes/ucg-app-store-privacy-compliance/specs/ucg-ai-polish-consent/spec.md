## ADDED Requirements

### Requirement: UGC AI 润笔首次使用前 MUST 展示独立同意告知

The app SHALL gate the UGC compose AI polish action behind a one-time, device-local consent dialog that is separate from the feeding AI chat consent (`ai_chat_data_consent_v1`).

客户端 MUST 在用户首次触发 UGC 发帖页「AI 润笔」时，展示独立于喂养 AI 对话的同意弹窗；同意状态 MUST 持久化于设备本地（`SharedPreferences`，key `ucg_ai_polish_consent_v1`），MUST NOT 同步至服务端。

#### Scenario: 首次点击 AI 润笔

- **WHEN** 用户在 UGC 发帖页点击「AI 润笔」且本地尚未记录同意（`UcgAiPolishConsentStore.load()` 为 false）
- **THEN** 系统 MUST 展示玻璃风格确认弹窗，标题为「使用 AI 润笔前请知悉」，正文为「您所选图片及当前正文将发送至第三方 AI 服务，用于生成润色文案。」
- **AND** 确认按钮文案 MUST 为「同意并继续」
- **AND** 弹窗 MUST NOT 包含隐私政策链接
- **AND** 弹窗 MUST NOT 包含勾选框

#### Scenario: 用户拒绝润笔同意

- **WHEN** 用户在润笔同意弹窗中选择取消或关闭
- **THEN** 系统 MUST NOT 调用 `polishPost` API
- **AND** MUST NOT 写入同意标记

#### Scenario: 用户同意后再次润笔

- **WHEN** 用户曾点击「同意并继续」且 `UcgAiPolishConsentStore.load()` 为 true
- **THEN** 再次点击「AI 润笔」时 MUST NOT 重复展示同意弹窗
- **AND** MUST 直接执行润笔请求

#### Scenario: 润笔同意与喂养 AI 同意互不影响

- **WHEN** 用户已同意喂养 AI 对话（`ai_chat_data_consent_v1`）但未同意 UGC AI 润笔
- **THEN** 首次使用 AI 润笔时 MUST 仍展示润笔同意弹窗
- **AND** 反之亦然：仅同意润笔不影响喂养 AI 对话的门控
