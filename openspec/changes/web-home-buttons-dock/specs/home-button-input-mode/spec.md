## MODIFIED Requirements

### Requirement: 主页第三输入模式「按钮」

The client SHALL provide **button** input as the **default** home input mode on **all platforms** (Android, iOS, and Web). On Android/iOS, button mode MUST toggle with **voice** only (not text) via the input mode dock. On Web, button mode MUST toggle with **text** only (not voice) via the input mode dock. 在 **所有平台**上，系统 MUST 以**事件按钮**为默认主输入模式。Android/iOS 通过 dock 与**语音**轮转；Web 通过 dock 与**文字**轮转；**不得**在移动端提供键盘文字主输入；**不得**在 Web 提供语音主输入。

#### Scenario: 冷启动默认按钮模式

- **WHEN** 用户在 Android/iOS 或 Web 上冷启动进入主页且本地无有效输入模式持久化（或持久化为已废弃/无效值）
- **THEN** 底部 MUST 展示事件网格面板，且 MUST NOT 默认展示语音按住区域或文字输入框

#### Scenario: 切换到语音模式

- **WHEN** 用户在 **Android/iOS** 上通过 dock 从按钮模式轮转到语音
- **THEN** 底部 MUST 展示语音按住区域，且 MUST NOT 以文字输入框为主输入

#### Scenario: 从语音切回按钮

- **WHEN** 用户在 **Android/iOS** 上通过 dock 从语音模式轮转到按钮
- **THEN** 底部 MUST 恢复事件网格面板

#### Scenario: Web 切换到文字模式

- **WHEN** 用户在 **Web** 上已登录且已绑宝宝，通过 dock 从按钮模式轮转到文字
- **THEN** 底部 MUST 展示文字输入框与显式提交路径，且 MUST NOT 以语音按住区域为主输入

#### Scenario: Web 从文字切回按钮

- **WHEN** 用户在 **Web** 上通过 dock 从文字模式轮转到按钮
- **THEN** 底部 MUST 恢复事件网格面板

#### Scenario: 持久化恢复 voice 或 buttons（移动端）

- **WHEN** 在 Android/iOS 上本地持久化为 `voice` 或 `buttons` 且平台支持
- **THEN** 系统 MUST 恢复对应模式，不得强制覆盖为按钮（除非值为 `text` 或不可用）

#### Scenario: 持久化恢复 buttons 或 text（Web）

- **WHEN** 在 Web 上本地持久化为 `buttons` 或 `text`
- **THEN** 系统 MUST 恢复对应模式

#### Scenario: Web 忽略 voice 持久化

- **WHEN** 在 Web 上本地持久化为 `voice`
- **THEN** 系统 MUST 视为无效并回退为 `buttons`

#### Scenario: 游客或未绑宝宝仅按钮

- **WHEN** 用户在 Web 上处于游客态或未绑宝宝（`blockHomeInputChrome` 为真）
- **THEN** 底部 MUST 仅展示事件网格面板，MUST NOT 展示文字输入框，且 MUST NOT 展示输入模式 dock
