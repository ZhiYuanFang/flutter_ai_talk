## MODIFIED Requirements

### Requirement: 主页后台补全网络状态

The system SHALL run version check, baby profile fetch, deviceNo remote refresh, history/catalog remote sync, and event logo file downloads after the home shell is shown without blocking the initial route transition. 系统必须在展示主页壳子之后执行版本检查、宝宝信息拉取、`deviceNo` 远端 refresh、历史与事件目录远端同步及事件 logo 文件下载；这些任务**不得**阻塞从 Splash 到 `/home` 的路由跳转。自动版本检查 MUST 由 `UcgHomeShell` 启动编排触发（对游客与已登录均适用），MUST 排在 notify banner 处理之后，MUST NOT 依赖喂养页 mount，且 MUST NOT 因 resume 或登录中途单独再跑一遍自动弹窗链。

#### Scenario: 进主页后版本提示

- **WHEN** 用户已进入 `/home`（含游客）且版本检查发现新版本，且 notify 启动步骤已结束（无弹窗或弹窗已关闭）
- **THEN** 系统必须按既有 `maybeShowVersionPrompt` 规则展示提示（非强制更新可延迟，但不得回到 Splash 阻塞）

#### Scenario: 进主页后 catalog 与 logo 补全

- **WHEN** 用户已进入 `/home` 且已登录
- **THEN** 系统 MUST 在后台触发 `event/options` 对比刷新与 logo 文件下载，且不得要求用户再次经过 Splash 等待

#### Scenario: 预测页着陆也可版本提示

- **WHEN** 用户冷启进入 `/home` 且停在智能预测页
- **THEN** 系统 MUST 仍可在 notify 步骤之后展示版本提示，不得要求用户先滑到喂养页
