## 1. 竖屏路由门闩收窄

- [x] 1.1 阅读并对照 `LandscapeVoiceLifecycleBinder`：将竖屏 `routeCurrent = ModalRoute.isCurrent` 改为「仅 PageRoute 覆盖才否」，Overlay（sheet/dialog）不得使 `surfaceVisible` 变 false
- [x] 1.2 确认 `RouteAware.didPushNext` / `didPopNext`（或等价 Page 级检测）在推设置/登录等 Page 时仍能触发 deactivate；横屏 binder 行为不变
- [x] 1.3 用中文注释标明：Overlay 翻转 `isCurrent` 不得 teardown；与 design.md 决策一致
- [x] 1.4 将 `appRouteObserver` 改为 `RouteObserver<PageRoute>`（ModalRoute 泛型会让 sheet 触发 didPushNext）；`activate` 加 single-flight + lifecycle gen

## 2. 生命周期与日志验收

- [ ] 2.1 手工：竖屏已唤醒就绪 → 打开喂养事件选择 sheet → logcat **不得** 出现本次 `endSession reason=teardown` / `ready=false` 成对拆会话
- [ ] 2.2 手工：关闭 sheet（✕ 与点外部）→ **不得** 出现成对 `InitEncoder` 冷启动；关闭无明显「先卡一下才关」
- [ ] 2.3 手工：主壳推入设置（或其它 PageRoute）→ **必须** 仍 deactivate；返回主壳可再次 activate
- [ ] 2.4 手工：未合格 UCG / 竖屏 flag 关闭等既有表面门闩仍生效

## 3. 收尾

- [x] 3.1 若改动触及 Debug 文案，确认仍走 `AppDebugLog.landscapeVoice`（无裸 `debugPrint`）
- [x] 3.2 本变更不涉及 `app/android/**`；无需 release APK / proguard 项
