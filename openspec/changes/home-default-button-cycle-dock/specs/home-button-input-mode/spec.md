## MODIFIED Requirements

### Requirement: 主页第三输入模式「按钮」

The client SHALL provide **button** input as the **default** home input mode on Android/iOS, toggled with **voice** only (not text) via the input mode dock. 在 Android/iOS 上，系统 MUST 以**事件按钮**为默认主输入模式，并与**语音**通过 dock **一键轮转**切换；**不得**在移动端提供与二者并列的键盘文字主输入。Web 端 MUST 继续遵循 `web-home-input-mode`，本需求不修改 Web 行为。

#### Scenario: 冷启动默认按钮模式

- **WHEN** 用户在 Android/iOS 上冷启动进入主页且本地无有效输入模式持久化（或持久化为已废弃的 `text`）
- **THEN** 底部 MUST 展示事件网格面板，且 MUST NOT 默认展示语音按住区域或文字输入框

#### Scenario: 切换到语音模式

- **WHEN** 用户通过 dock 从按钮模式轮转到语音
- **THEN** 底部 MUST 展示语音按住区域，且 MUST NOT 以文字输入框为主输入

#### Scenario: 从语音切回按钮

- **WHEN** 用户通过 dock 从语音模式轮转到按钮
- **THEN** 底部 MUST 恢复事件网格面板

#### Scenario: 持久化恢复 voice 或 buttons

- **WHEN** 本地持久化为 `voice` 或 `buttons` 且平台支持
- **THEN** 系统 MUST 恢复对应模式，不得强制覆盖为按钮（除非值为 `text` 或不可用）
