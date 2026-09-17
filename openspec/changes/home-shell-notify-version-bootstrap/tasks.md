## 1. 启动编排入口

- [x] 1.1 新增主壳串行 bootstrap（如 `runHomeShellDialogBootstrap`）：先 `await maybeShowNotifyBannerPrompt`，再对游客与已登录 `await maybeShowVersionPrompt`；同挂载 single-flight
- [x] 1.2 在 `UcgHomeShell` 挂载首帧回调中调用该 bootstrap（使用壳 `context`）；确认不挂在 resume / lifecycle

## 2. 从喂养页剥离

- [x] 2.1 从 `HomeScreen._init` 移除 `_runHomeDialogBootstrap` 与 `_runPostLoginBootstrap` 的自动弹窗调用（保留网关/传输/logo 等非弹窗补全）
- [x] 2.2 从 `_onLoggedInWhileHomeMounted`（及 session listen）去掉自动 notify/version；登录中途不得再弹

## 3. 验收

- [x] 3.1 手工：冷启落预测页（游客/已登录）可看到 notify→version 串行；无 notify 时直接 version
- [x] 3.2 手工：resume、主壳内登录成功均不自动弹；设置「检查更新」游客仍可用
- [x] 3.3 确认未新建 `**/test/**`；本 change 不改 `app/android/**`（无需 release/R8 专项）
