## Why

切换账号已调用 `wipeAccountLocalState` 清空历史磁盘与 `homeHistory` 状态，但 `HomeHistoryNotifier` 上未完成的 `refreshFromRemote`、飞入冻结队列等仍可能在 wipe 之后把上一账号记录写回。用户登录下一账号（尤其未绑定 `deviceNo`）时会出现「请绑定宝宝」与旧喂养列表并存，违背切号擦除承诺。

## What Changes

- 强化 `clearForSignOut`（或等价）：作废 in-flight 刷新世代、清空飞入冻结队列、重置 warm future，确保 wipe 后迟到的写操作不得再改 state。
- 已登录但本地无 `deviceNo` 时，历史 refresh/warm 路径 **必须** 保持空列表（不得 early-return 留下旧 items）。
- 扩展 `account-local-wipe` 规格：擦除在时间上对并发写回有效，而非仅瞬时 `items=[]`。

## Capabilities

### New Capabilities

- （无）本变更补强既有切号擦除与历史会话隔离，不引入独立产品能力名。

### Modified Capabilities

- `account-local-wipe`: 切号/注销擦除后，迟到的历史写回不得复活上一账号列表；未绑定会话不得展示非空喂养历史。

## Impact

- 代码：`app/lib/providers/home_history_notifier.dart`（主）；`wipe_account_local_state.dart` 调用点通常不变。
- 行为：切换账号 → 登录未绑定账号时，首页应为绑定空态，不应出现上一账号时间线。
- 关联：复用并收紧 `switch-account-local-wipe` 已落地的 wipe 入口。
