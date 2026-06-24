## Why

当前 `/home` 的 `UcgHomeShell` 在 Android 物理返回键上缺少统一拦截：用户在 UCG 模块（PageView page 1）按返回会直接退出 App，与 AppBar「返回喂养」及产品预期不符；喂养页（page 0）也缺少「二次确认退出」防护，易误触退出。此外 UCG 广场 Tab 已选中时再次点击无额外语义，用户期望与「返回喂养」一致。

基线 `ucg-home-entry` 已约定「系统返回或壳内返回控件」应回到喂养，但客户端尚未完整实现 Android 物理返回与双击退出、广场 Tab 再点行为。

## What Changes

- 在 `UcgHomeShell` 增加 `PopScope`：UCG 模块根层按 Android 返回时切回喂养页，不得直接退出 App；若顶层 `Navigator` 可 pop（聊天、详情等内层路由），则优先 pop 内层。
- 喂养页根层按 Android 返回：3 秒内连续两次才 `SystemNavigator.pop()` 退出 App；首次或超时则用全局 **AppToast** 提示「再试一次退出胖宝」。
- UCG 底部 Dock：当前已是「广场」Tab 时再次点击「广场」，执行与「返回喂养」相同的 PageView 切回 page 0。
- Toast 使用现有 `apiToastProvider` / `showApiToast` 体系；**不**为 Web 单独分支（Web 无 Android 物理返回，沿用默认路由行为即可）。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `ucg-home-entry`：补充 Android 物理返回在 UCG/喂养两页的语义、双击退出 AppToast 文案、广场 Tab 再点回喂养。

## Impact

- **代码**：`app/lib/ucg/ui/ucg_home_shell.dart`（`PopScope`、退出计时）、`app/lib/ucg/ui/ucg_shell.dart`（`_onTabTap` 广场再点）。
- **依赖**：`flutter/services.dart`（`SystemNavigator`）、`dart:io` 或 `defaultTargetPlatform` 限定 Android 物理返回逻辑；`providers/toast_bus.dart`（AppToast）。
- **基线**：与 `openspec/specs/` 中 `ucg-home-entry`「从 UCG 返回喂养」场景对齐并落地实现。
