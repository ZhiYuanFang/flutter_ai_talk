## Context

当前冷启动流程（`app/lib/app.dart`）：

1. `hideNativeSplash()` 收起原生 Splash；
2. 并行执行 `ColdStartBootstrap.run(session)` 与 `Future.delayed(kMinStartupBrandingDisplay)`（**2400ms**）；
3. 已登录时额外 await history / event catalog bootstrap；
4. `goRouter.go(result.route)` 跳转目标路由；
5. `AnimatedOpacity` **350ms** 淡出后移除 `StartupBrandingOverlay`。

遮罩视觉（`StartupBrandingOverlay`）含 `SplashLogoPulse`（心跳缩放+光晕）与 `StartupTaglineReveal`（1.5s 渐显）。产品现要求：**无动画、最短 300ms、尽快进主页**。

## Goals / Non-Goals

**Goals:**

- 启动遮罩仅展示静态 Logo + 静态标语「最懂你的胖宝」，无任何循环或 Reveal 动画。
- 品牌遮罩最短展示 **300ms**；路由跳转时机为 `max(ColdStartBootstrap + 登录后 bootstrap 完成, 300ms)`。
- 满足时序后**立即**移除遮罩，无淡出动画。
- 删除不再使用的动画 Widget 与常量，降低维护成本。

**Non-Goals:**

- 不修改 Android/iOS 原生 Launch Screen。
- 不改变 `ColdStartBootstrap` 本地门禁项（session、路由决策）。
- 不调整登录后进主页前的 history / event catalog bootstrap 顺序（除非 bootstrap 本身超过 300ms，则以实际完成时间为准）。

## Decisions

### 1. 最短展示 300ms，与 bootstrap 取 max

**选择**：保留 `Future.wait([bootstrapFuture, delayed(300ms)])` 模式，仅将常量改为 300ms。

**理由**：若本地 bootstrap 或已登录时的 history/catalog 加载超过 300ms，仍须等数据就绪再 `go`，避免主页闪空；若 bootstrap 更快，则至少展示 300ms 品牌帧，满足产品「停留 300ms」语义。

**备选**：固定 300ms 后强制跳转、bootstrap 后台继续 ——  rejected，会与现有「进主页前 bootstrap history/catalog」策略冲突，且可能复现历史闪空问题。

### 2. 静态布局内联于 `StartupBrandingOverlay`

**选择**：在 `splash_logo_pulse.dart`（或重命名为 `startup_branding_overlay.dart`）内用 `Image.asset` + `Text` 实现静态布局；删除 `SplashLogoPulse`、`StartupTaglineReveal` 类及 `startup_tagline_reveal.dart`。

**理由**：动画组件无复用点；静态实现更简单，减少 `AnimationController` 与 ticker 开销。

### 3. 即时移除遮罩

**选择**：删除 `_overlayOpacity` 状态与 `AnimatedOpacity`；bootstrap 与最短展示完成后 `setState(() => _showStartupOverlay = false)`。

**理由**：用户明确要求去掉动画；即时切换符合「300ms 就进主页」预期。

### 4. 标语样式

**选择**：使用终态样式（约 21sp、`FontWeight.w700`、主题 `primary` 满不透明），与原先 Reveal 结束态一致。

**理由**：无动画时仍需可读、与品牌一致；无需从 14sp 过渡。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 已登录冷启动若 history/catalog bootstrap > 300ms，用户仍须等待 | 与现逻辑一致；300ms 为**下限**非上限；后续可独立优化 bootstrap 耗时 |
| 去掉淡出可能造成遮罩与主页切换略突兀 | 300ms 极短，用户感知可接受；原生 Splash → Flutter 首帧仍连续 |
| 删除动画组件后 `startup-branding-tagline` 变更部分需求作废 | 在本变更 specs 中以 REMOVED/MODIFIED delta 明确 supersede |

## Migration Plan

1. 修改常量与 `app.dart` 遮罩逻辑。
2. 简化 `StartupBrandingOverlay` 为静态 Widget。
3. 删除 `startup_tagline_reveal.dart` 及 `SplashLogoPulse`。
4. 本地 `flutter run` 验证：冷启动、已登录/未登录、弱网下 bootstrap 慢于 300ms 场景。

回滚：恢复常量 2400ms 与动画 Widget 即可，无数据迁移。

## Open Questions

- （无）产品已明确 300ms 与去动画；若后续希望「无论 bootstrap 多久最多只展示 300ms」，需另开变更调整 `app.dart` 登录后 await 策略。
