## Context

预测页成为 `/home` 默认着陆（`UcgHomeShell` + `PageView`，`initialPage = prediction`）后，notify / version 仍在喂养 `HomeScreen._init`：先 `await` 网关与 version，再 postFrame 跑 notify——与基线「notify 先于 version」及「进入 `/home` 即拉」不符。探索已拍板：壳挂载串行 bootstrap；游客也要 version；resume / 登录中途两者都不自动弹。

## Goals / Non-Goals

**Goals:**

- 主壳挂载即拉+弹 notify，再拉+弹 version（串行 await）。
- 游客与已登录均自动 version；冷启停在预测页也可见。
- 强阻断 notify 未退出前不得抢弹 version。
- 从喂养页剥离自动弹窗职责。

**Non-Goals:**

- 不改 notify / version 弹窗 UI、dismiss contentKey、强阻断「仅退出」语义。
- 不在 resume 上自动 re-check。
- 不在登录中途自动弹（设置手动检查保留）。
- 不把预测门闸、计时提醒等交互弹窗纳入启动队列。
- 不新建 `**/test/**`。

## Decisions

1. **触发点 = `UcgHomeShell` 挂载一次**  
   在 `initState` 的首帧 `addPostFrameCallback`（或等价「壳已 mounted」）启动编排。不依赖喂养页是否已被 PageView 构建。离开 `/home` 再进入会再次挂载 → 允许再次自动检查（与「启动进主页」一致）。

2. **编排函数串行**  
   抽出例如 `runHomeShellDialogBootstrap(context, …)`：  
   `await maybeShowNotifyBannerPrompt(…)` → `await maybeShowVersionPrompt(…)`。  
   notify 无 active / 已 dismiss / 失败静默 → Future 立即完成 → 立刻 version。有弹窗则 `await` dialog 关闭。用壳层 `BuildContext`。

3. **游客 version**  
   去掉「仅 `isLoggedIn` 才自动 version」守卫。`VersionRepository.checkForUpdate` 已 `withAuthorization: false`。设置页手动路径不变。

4. **排除路径**  
   - resume：壳 lifecycle 已有 HTTP/WS，**不**挂 dialog bootstrap。  
   - 登录中途：`HomeScreen` / 壳上 session listen **不得**再调 notify 或自动 version。喂养页 `_onLoggedInWhileHomeMounted` 可保留网关/传输补全，但删除 `_runHomeDialogBootstrap` / `_runPostLoginBootstrap` 弹窗段。  
   - 现网 listen 条件 `prev != true || !loggedIn` 疑似写反；本 change 以「登录中途不弹」为准，清理误挂即可，不强制修成「登录后弹」。

5. **single-flight**  
   壳 State 内 `Future? _dialogBootstrapInFlight`：同挂载周期重复调度则 await 同一 Future，避免双弹。非 Riverpod listen 风暴；若未来改 listen，须遵守 `side-effect-http-governance`。

6. **与网关 bootstrap 解耦**  
   notify / version 均无鉴权，**不必**等待 `GatewayBootstrapGate`。可与历史 WS activate 等并行，但弹窗链本身串行且尽早启动。

## Risks / Trade-offs

- **[Risk] 强阻断 notify 永久挡住 version** → 可接受（维护期应退出；与产品一致）。  
- **[Risk] 壳 context 与子页同时 showDialog** → 启动级仅壳编排；交互弹窗仍由子页；队列锁降低叠窗。  
- **[Risk] 游客频繁看到升级窗** → 与「游客也要更新」一致；非强制可稍后；设置手动仍可用。  
- **[Trade-off] 再进 `/home` 会再检查** → 可接受；不做跨会话「本进程只一次」除非后续产品要求。

## Migration Plan

- 无服务端/数据迁移。  
- 回滚：把调用点移回 `HomeScreen._init`（不推荐，会再现预测页漏弹）。

## Open Questions

- （已定）登录中途不弹 version。  
- （已定）resume 不弹。  
- （已定）游客自动 version。
