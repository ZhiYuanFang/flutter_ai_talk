## Context

`/home` 由 `UcgHomeShell` 承载：`PageView` page 0 为喂养 `HomeScreen`，page 1 为 `UcgShell`（UCG 底部 Tab + 内层 `Navigator.push` 子页如聊天、详情）。AppBar 已有 `ucgBackLeading` → `_goToFeeding()`，但 **未** 拦截 Android 物理返回；在 GoRouter 根路由 `/home` 上按返回会直接退出 App。

基线 `ucg-home-entry` 要求「系统返回或壳内返回控件」回到喂养，本变更补齐 Android 物理返回与广场 Tab 再点语义。Toast 统一走全局 `apiToastProvider` / `AppToast`；Web 不单独分支。

## Goals / Non-Goals

**Goals:**

- UCG 模块根层：Android 物理返回 → PageView 回 page 0，不退出 App。
- 内层路由（聊天、发帖、GoRouter 子页等）仍优先 pop。
- 喂养 page 0 根层：Android 物理返回 3 秒内连按两次才退出；否则 AppToast「再试一次退出胖宝」。
- UCG 广场 Tab 已选中时再点一次 → 回喂养（与 AppBar 返回一致）。

**Non-Goals:**

- Web 浏览器后退键的专门逻辑（不新增 Web 分支）。
- iOS 侧滑返回手势的额外定制（无硬件返回键）。
- 修改 PageView 横滑切页、右侧「进入广场」拉条既有行为。

## Decisions

### 1. 拦截层放在 `UcgHomeShell` 而非 `UcgShell`

**选择**：`UcgHomeShell` 包 `PopScope`，持有 `_pageIndex` 与 `_goToFeeding()`。

**理由**：PageView 索引在 HomeShell；喂养双击退出也需在 page 0 判断。`UcgShell` 无法单独决定 PageView 切页。

**备选**：在 `UcgShell` 只处理 UCG 内返回 — 无法覆盖喂养双击退出，否决。

### 2. 内层路由优先 pop

**选择**：`PopScope` 逻辑顺序：

```
if (Navigator.of(context).canPop()) → 不拦截（canPop: true，默认 pop）
else if (Android && pageIndex == 1) → canPop: false，_goToFeeding()
else if (Android && pageIndex == 0) → canPop: false，双击退出逻辑
else → 默认
```

**理由**：与 Material 返回栈一致；聊天/设置等子页行为不变。

### 3. 仅 Android 启用物理返回定制

**选择**：`Platform.isAndroid`（或 `defaultTargetPlatform == TargetPlatform.android`）包裹定制分支。

**理由**：需求明确针对 Android 物理返回；Web/iOS 不单独设定。

### 4. 双击退出用 AppToast（info 调性）

**选择**：`ConsumerStatefulWidget` + `ref.showApiToast('再试一次退出胖宝')`；第二次 3 秒内 `SystemNavigator.pop()`。

**理由**：用户指定全局 AppToast；与 `toast_bus.dart` 现有体系一致，不用 SnackBar。

**状态**：`DateTime? _lastExitBackPress`；间隔 `≤ 3s` 视为第二次。

### 5. 广场 Tab 再点在 `UcgShell._onTabTap`

**选择**：`index == 0 && _tabIndex == 0` 时调用 `widget.onBackToFeeding?.call()` 并 return。

**理由**：最小改动；与 Dock 现有 index 语义一致（`kUcgTreasureEnabled == false` 时 index 0 即广场）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| `UcgHomeShell` 改为 `ConsumerStatefulWidget` 才能用 Toast | 仅增加 `flutter_riverpod` 依赖，改动局部 |
| 从喂养 `context.push('/settings')` 时误触双击退出 | `canPop` 为 true 时走默认 pop，不进入双击逻辑 |
| 鉴权/登录页在栈上 | 同上，优先 pop 子路由 |
| 3 秒窗口用户觉得短 | 与需求一致；后续可调常量 |

## Migration Plan

纯客户端 UI 行为变更，无数据迁移。发版后即可验证；回滚即 revert `PopScope` 与 Tab 再点逻辑。

## Open Questions

（无 — Toast 与 Web 范围已确认。）
