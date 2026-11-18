## ADDED Requirements

### Requirement: 未同意隐私政策不得进入业务冷启动联网

The client MUST NOT run cold-start networking that can expose personal information or network identifiers to the server until the user has accepted the privacy policy gate. 在用户完成首启隐私政策同意前，客户端**不得**执行会向服务端暴露个人信息或网络标识的冷启动联网（含游客事件目录拉取、iOS 网络探针、推送 token 注册、设备型号上报等）。

#### Scenario: 首次安装未同意时不拉事件目录

- **WHEN** 本地尚未记录隐私政策同意，且用户冷启动 App
- **THEN** 系统必须展示首启隐私门闩，且**不得**请求 `/device/history/api/event/options`（或等价事件目录接口）

#### Scenario: 首次安装未同意时不跑 iOS 探针

- **WHEN** 本地尚未记录隐私政策同意，且用户在 iOS 上冷启动 App
- **THEN** 系统**不得**发起 `IosNetworkPermissionProbe` 所使用的 `version/check`（或等价）请求

#### Scenario: 同意后恢复正常冷启动

- **WHEN** 用户在首启门闩点击「同意并继续」，且本地已写入同意
- **THEN** 系统必须继续既有冷启动与后续 sync（含在适用条件下的目录拉取等），行为与门闩引入前的已同意用户一致

### Requirement: 首启门闩展示可滚动隐私政策 WebView

The first-launch privacy gate MUST load `AppEnv.privacyPolicyUrl` in a scrollable WebView without an extra title/AppBar, and MUST show fixed bottom actions to accept or decline. 首启隐私门闩必须在可滚动 WebView 中加载 `AppEnv.privacyPolicyUrl`，**不得**再叠加独立标题栏/AppBar（网页自带标题即可）；必须提供固定底栏「不同意并退出」与「同意并继续」。

#### Scenario: 无额外标题

- **WHEN** 用户看到首启隐私门闩
- **THEN** 界面上半为隐私政策 Web 内容且可滚动，且**不得**出现与网页标题重复的原生「隐私政策」AppBar 标题

#### Scenario: 加载失败可重试且不得默认同意

- **WHEN** 隐私政策 URL 加载失败
- **THEN** 系统必须提示失败并允许重试，且**不得**将失败视为已同意，**不得**自动进入业务冷启动联网

### Requirement: 不同意必须退出应用

When the user declines the first-launch privacy gate, the client MUST exit the application and MUST NOT persist acceptance. 用户选择不同意时，客户端必须退出应用，且**不得**将同意状态写入本地。

#### Scenario: 点击不同意并退出

- **WHEN** 用户在首启门闩点击「不同意并退出」
- **THEN** 系统必须结束进程（或等价退出），且本地同意标志仍为未同意

#### Scenario: 系统返回键等同不同意

- **WHEN** 用户在首启门闩按下系统返回键（Android back 或等价）
- **THEN** 系统必须按不同意处理：退出应用且**不得**写入同意

### Requirement: 同意必须持久化

Accepting the first-launch privacy gate MUST persist consent locally so subsequent cold starts skip the gate. 用户点击「同意并继续」后，系统必须将同意持久化到本地；之后冷启动**不得**再展示该门闩（除非更换同意键/版本策略另有规定）。

#### Scenario: 再次冷启动跳过门闩

- **WHEN** 用户曾同意并成功写入本地，并再次冷启动 App
- **THEN** 系统**不得**再次展示首启隐私门闩，并按已同意路径启动
