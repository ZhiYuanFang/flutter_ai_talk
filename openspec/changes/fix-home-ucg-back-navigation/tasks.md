## 1. UcgHomeShell 物理返回（`ucg-home-entry`）

- [x] 1.1 将 `UcgHomeShell` 改为 `ConsumerStatefulWidget`，引入 `PopScope` 与 `Platform.isAndroid` 判断
- [x] 1.2 实现返回分发：`Navigator.canPop` 为 true 时不拦截；Android + page 1 根层 → `_goToFeeding()`；Android + page 0 根层 → 双击退出逻辑
- [x] 1.3 喂养根层双击退出：维护 `_lastExitBackPress`，3 秒内第二次 `SystemNavigator.pop()`，否则 `ref.showApiToast('再试一次退出胖宝')`

## 2. UCG 广场 Tab 再点（`ucg-home-entry`）

- [x] 2.1 在 `UcgShell._onTabTap` 中：当 `index == 0 && _tabIndex == 0` 时调用 `widget.onBackToFeeding` 并 return

## 3. 验证

- [ ] 3.1 Android：UCG 任意 Tab 根层按返回 → 回喂养，不退出 App
- [ ] 3.2 Android：UCG 聊天/详情子页按返回 → 先 pop 子页
- [ ] 3.3 Android：喂养根层首次按返回 → AppToast「再试一次退出胖宝」；3 秒内再按 → 退出 App
- [ ] 3.4 Android：UCG 广场 Tab 已选中时再点「广场」→ 回喂养
- [x] 3.5 `flutter analyze` 无新增 error（`ucg_home_shell.dart`、`ucg_shell.dart`）
