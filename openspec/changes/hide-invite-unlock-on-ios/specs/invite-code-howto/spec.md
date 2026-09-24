## MODIFIED Requirements

### Requirement: Shared invite-code dialog lives in feature_unlock UI module
The client SHALL implement a shared glass invite-code input dialog under `app/lib/ui/feature_unlock/` for the feature unlock hub (and any other non-slot invite unlock callers that still exist). The dialog MUST NOT be required by a prediction slot-full flow (that product capability is removed). The dialog MUST accept injectable title, body/subtitle, and confirm-button label. The left action MUST be labeled「获取邀请码」and MUST return a distinct how-to result (not a redeem code). The confirm action MUST pop the trimmed input string (including empty). The `TextEditingController` MUST be owned and disposed by the dialog body `State` (MUST NOT dispose after `await show*` returns). Callers MUST use this shared dialog rather than private duplicate widgets. 共享邀请码弹窗必须落在 `app/lib/ui/feature_unlock/`，服务于开通中心等现存邀请开通调用方；**不得**再绑定预测槽位满额流程；标题/正文/确认文案可注入；左键「获取邀请码」；确认弹出修剪后字符串；controller 归弹层 State。

#### Scenario: How-to action from dialog
- **WHEN** the user taps「获取邀请码」in the shared dialog
- **THEN** the dialog MUST close with a how-to result
- **AND** the caller MUST navigate to the「如何获取邀请码」screen

#### Scenario: Confirm returns trimmed code
- **WHEN** the user taps the confirm button with input「  ABC  」
- **THEN** the dialog MUST pop with「ABC」

#### Scenario: Empty confirm still pops empty string
- **WHEN** the user taps confirm with empty input
- **THEN** the dialog MUST pop with an empty string (caller decides silent dismiss vs navigate)

#### Scenario: Prediction page MUST NOT use slot-full invite dialog
- **WHEN** 用户在智能预测页开启事项预测开关
- **THEN** 客户端 MUST NOT 因「预测槽位已满」打开共享邀请码弹窗
- **AND** 预测页 MUST NOT 保留仅服务于该流程的无用 invite_code_dialog 引用
