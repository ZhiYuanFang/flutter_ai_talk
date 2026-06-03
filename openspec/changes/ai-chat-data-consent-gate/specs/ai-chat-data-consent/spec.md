## ADDED Requirements

### Requirement: 未同意不得发起 AI 对话

The client MUST NOT invoke `sendCommand` (or equivalent chat submit to `/device/history/api/chat`) until the user has accepted AI chat data processing disclosure. 在用户未完成 AI 对话数据知情同意前，客户端**不得**调用 `sendCommand` 或等价的聊天提交接口。

#### Scenario: 未同意时文字提交被拦截

- **WHEN** 本地尚未记录 AI 对话数据同意，且用户在首页文字输入模式提交非空文本
- **THEN** 系统必须展示知情同意弹窗，且**不得**发起 `sendCommand`

#### Scenario: 未同意时语音松手不发送

- **WHEN** 本地尚未记录 AI 对话数据同意，且用户完成一次按住说话流程
- **THEN** 系统必须在按住阶段拦截，**不得**进入录音/`startSession`，因而**不得**在松手后调用 `sendCommand`

### Requirement: 未同意时重复展示告知弹窗

The system MUST show the AI chat data disclosure dialog on every voice-orb press-and-hold attempt and on every text submit attempt until consent is stored. 在未持久化同意前，系统必须在**每次**按住语音球时、以及**每次**文字提交时展示同一告知弹窗。

#### Scenario: 每次按住语音球均弹窗

- **WHEN** 用户尚未同意，且反复按住主页语音球（含点取消后再次按住）
- **THEN** 每次按住都必须再次展示告知弹窗

#### Scenario: 每次文字提交均弹窗

- **WHEN** 用户尚未同意，且反复提交文字（含点取消后再次提交）
- **THEN** 每次提交都必须再次展示告知弹窗

### Requirement: 同意并继续持久化

The system MUST treat tapping「同意并继续」as informed consent and MUST persist acceptance locally so subsequent voice holds and text submits do not show the dialog again. 用户点击「同意并继续」后，系统必须将同意状态持久化到本地；此后语音按住与文字提交**不得**再展示该弹窗。

#### Scenario: 同意后语音不再弹窗

- **WHEN** 用户曾在告知弹窗中点击「同意并继续」，并再次按住语音球
- **THEN** 系统必须直接进入现有语音门控（登录、WS、麦克风等），**不得**再次展示 AI 对话告知弹窗

#### Scenario: 同意后文字不再弹窗

- **WHEN** 用户曾在告知弹窗中点击「同意并继续」，并再次提交文字
- **THEN** 系统必须直接调用 `sendCommand`，**不得**再次展示 AI 对话告知弹窗

### Requirement: 告知弹窗内容与交互

The disclosure dialog MUST state that user input and recent feeding data will be sent to third-party AI services for analysis and reply; it MUST NOT include a privacy-policy link or a separate checkbox row. 告知弹窗必须说明：用户输入内容及近期喂养记录将发送至第三方 AI 服务用于分析与回复；**不得**包含「查看隐私政策」类入口；**不得**包含独立勾选框行；点击「同意并继续」即视为知悉并同意。

#### Scenario: 弹窗文案与按钮

- **WHEN** 系统展示 AI 对话数据告知弹窗
- **THEN** 弹窗必须包含标题「使用 AI 对话前请知悉」、正文说明输入与近期喂养数据将发送至第三方 AI、以及「取消」与「同意并继续」两个操作；**不得**出现勾选框或隐私政策按钮

#### Scenario: 取消中止当前操作

- **WHEN** 用户在告知弹窗中点击「取消」
- **THEN** 系统必须中止当前语音按住或文字提交流程，且**不得**写入同意状态，**不得**调用 `sendCommand`

### Requirement: 不区分语音识别引擎

The disclosure MUST NOT vary copy or consent flow based on cloud ASR versus system STT. 告知文案与同意流程**不得**因云端 ASR 与 iOS 系统识别等引擎差异而分支。

#### Scenario: 切换语音识别引擎后同意门不变

- **WHEN** 用户在设置中心切换语音识别方式后尚未同意 AI 对话数据 processing
- **THEN** 按住语音球时展示的告知弹窗必须与默认引擎下完全一致

### Requirement: 不提供设置中心撤回

The system MUST NOT expose a settings entry to revoke AI chat data consent. 系统**不得**在设置中心提供撤回 AI 对话数据同意的入口。

#### Scenario: 设置中心无撤回项

- **WHEN** 用户打开设置中心
- **THEN** 界面中**不得**出现用于撤回 AI 对话数据同意的开关或菜单项
