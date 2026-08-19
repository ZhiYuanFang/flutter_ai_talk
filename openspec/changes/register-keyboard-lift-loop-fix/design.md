## Context

auth 内联输入页（login / register / change-password / baby-bind）采用统一模式：

- `Scaffold(resizeToAvoidBottomInset: false)`
- `SingleChildScrollView` + 贴底 `Column(mainAxisAlignment: end)`
- 底部 `padding: 16 + viewInsets.bottom`
- `keyboardLiftTarget` + `FocusNode` listener → `scrollInlineAuthFieldIntoView` → `scheduleKeyboardLift`
- **`build()` 内调用 `scheduleInlineAuthScrollOnInset`**（每次 rebuild 注册 postFrameCallback）

键盘弹出时 `MediaQuery.viewInsets.bottom` 在 ~300ms 内逐帧变化，导致 rebuild 风暴；每次 rebuild 再调度 `performKeyboardLift` → `animateTo(200ms)`，与 padding 顶起、focus listener 的多层 retry 叠加，形成规格所述「布局顶起循环」。

基线 Requirement（`account-registration`）已要求 Android 14 真机确认密码可稳定输入，本设计为实现该约束的技术方案。

## Goals / Non-Goals

**Goals:**

- 消除 auth 页键盘顶起的 build 副作用循环，主线程不再因重复 layout + scroll 动画洪泛而 ANR。
- 密码、确认密码聚焦后输入框 MUST 稳定露出在键盘上方，可持续键入。
- 修复逻辑集中在 `auth_field_scroll.dart` / `keyboard_lift.dart`，auth 页仅改接线。
- 登录、改密、绑定页与注册页行为一致（共享 helper）。

**Non-Goals:**

- 不改动 UCG `ManagedKeyboardTextField` / `keyboardInputBridge` 的 overlay 顶起路径。
- 不改变 auth 页贴底布局视觉（`inlineAuthScrollMinHeight`、品牌 header 等保持不变）。
- 不新增自动化 widget test（按 project.md 约定）。
- 不调整 Android 原生 `windowSoftInputMode`（除非真机验收仍失败，留作 Open Question）。

## Decisions

### 1. 用 `InlineAuthKeyboardLiftHost` 替代 build 内调度

**选择：** 新增轻量 `StatefulWidget`（或 mixin + `WidgetsBindingObserver`），包裹 auth 页 scroll 区域，在 `didChangeMetrics` / `MediaQuery` 变化时比较 **上一次 inset**，仅当 `|Δinset| >= 1.0` 且当前有聚焦 auth 字段时调用 `performKeyboardLift` 一次。

**理由：** 将副作用移出 `build()`，打断「rebuild → schedule → animate → rebuild」环。

**备选：** 保留 build 内调用但加 debounce —— 仍违反 Flutter 惯例，否决。

### 2. `performKeyboardLift` 增加 session 级幂等 guard

**选择：** 在 `keyboard_lift.dart` 维护 `_liftGeneration` 或 per-`(focusNode, insetBucket)` 的 in-flight 标记：

- 同一 focusNode 在 animate 进行中且目标 delta < 2px 时跳过。
- 新 lift 请求到来时 `ScrollController` 先 `jumpTo` 或取消进行中的 animation（`position.isScrollingNotifier`）再决定是否 animate。
- `allowInsetRetry` 在 auth inline 路径降为 **1 次** delayed retry（50ms），不再 3 次。

**理由：** 即使 observer 偶发多次触发，也不会叠加动画。

### 3. 保留 padding 顶起 + scroll lift，但协调时机

**选择：** 不删除 `padding: 16 + bottomInset`（贴底布局依赖此撑开 scroll extent）；scroll lift 仅在 inset **稳定或接近稳定**（最后一次 metrics 变化后单帧）执行，避免与 padding 动画中间态互搏。

**理由：** 去掉 padding 会破坏贴底表单在键盘收起/弹出时的视觉一致性；完全只靠 padding 则低字段仍可能被挡。

**备选：** 仅 padding、去掉 scroll —— 注册页三字段在部分机型仍不足，否决。

### 4. auth 页 focus listener 保留但不再双 postFrame

**选择：** `scheduleKeyboardLift` 对 inline auth 场景（由 `scrollInlineAuthFieldIntoView` 传入 `inlineAuth: true` 或独立 `scheduleInlineAuthKeyboardLift`）只注册 **一层** postFrameCallback。

**理由：** focus 变化仍需即时响应；双 postFrame + 双 perform 是多余放大因子。

## Risks / Trade-offs

- **[Risk] inset 稳定判定过早，首帧顶起不足** → Mitigation：focus 时仍立即 postFrame 一次；metrics 变化后再补一次；保留 50ms retry。
- **[Risk] 修改 `keyboard_lift.dart` 影响 UCG dock 顶起** → Mitigation：guard 仅作用于 `scrollController != null && !keyboardOverlayChrome` 的 inline auth 路径，dock 路径逻辑不变。
- **[Risk] 小屏 / 横屏 auth 页仍遮挡** → Mitigation：验收覆盖注册页三字段；若不足再调 `kKeyboardLiftGap`（非本 change 首选）。
- **[Trade-off] `jumpTo` 替代部分 `animateTo` 动效略硬** → 可接受，auth 页优先稳定性。

## Migration Plan

1. 实现 helper + guard，先在 `register_screen.dart` 接线验证。
2. 同步 login / change-password / baby-bind 移除 build 副作用。
3. 真机（Android 14+）手工路径：直接点密码、点确认密码、账号→下一项→密码→下一项→确认密码。
4. 无数据迁移、无后端变更；可单独 hotfix 发布。
5. 回滚：revert 单个 PR 即可恢复旧行为。

## Open Questions

- ANR 是否仅 Android 14，还是 Android 12/13 也有？（验收时一并记录）
- 若修复后仍偶发遮挡，是否需调整 `AndroidManifest` 的 `windowSoftInputMode`（当前未改）
