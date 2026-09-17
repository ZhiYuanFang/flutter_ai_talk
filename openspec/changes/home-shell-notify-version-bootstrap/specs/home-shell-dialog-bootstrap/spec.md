## ADDED Requirements

### Requirement: 主壳挂载 SHALL 串行编排启动级弹窗

When `UcgHomeShell` mounts after navigation to `/home`, the client SHALL run a single home-shell dialog bootstrap that sequentially awaits notify banner handling and then version update handling. The bootstrap MUST use the shell `BuildContext`, MUST NOT depend on the feeding `HomeScreen` being built or visible, and MUST coalesce concurrent invocations in the same mount into one in-flight Future (single-flight). 进入 `/home` 且主壳挂载后，客户端 **必须** 运行一次启动级弹窗编排：先完成 notify 处理（含可能的弹窗关闭），再完成 version 处理；**必须** 使用壳层 context；**不得** 依赖喂养页已构建或可见；同挂载周期并发调度 **必须** single-flight。

#### Scenario: 冷启落在预测页仍跑编排

- **WHEN** 用户冷启动进入 `/home` 且默认停在智能预测页、尚未滑到喂养页
- **THEN** 客户端 MUST 仍执行 notify→version 串行编排

#### Scenario: notify 弹出后关闭再检查 version

- **WHEN** notify 服务返回 `active=true` 且展示了可关闭公告弹窗，用户随后关闭该弹窗
- **THEN** 客户端 MUST 在该弹窗关闭之后再发起版本检查（或展示版本弹窗）

#### Scenario: 无 notify 则立刻 version

- **WHEN** notify 拉取失败、inactive、或 contentKey 已被「不再提示」
- **THEN** 客户端 MUST 不阻塞地进入版本检查步骤

#### Scenario: resume 不跑启动编排

- **WHEN** 应用从后台 resume 且主壳仍挂载
- **THEN** 客户端 MUST NOT 因 resume 再次自动运行 notify→version 启动编排

#### Scenario: 登录中途不跑启动编排

- **WHEN** 主壳已挂载期间用户从游客变为已登录
- **THEN** 客户端 MUST NOT 因此自动运行 notify 或自动 version 弹窗编排（设置中心手动「检查更新」除外）
