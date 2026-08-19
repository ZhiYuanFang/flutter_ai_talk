## 1. 方向 helper

- [x] 1.1 在 `smart_prediction_screen.dart` 抽取 `_exitLandscapeToPortrait()`：`portraitUp` → 短暂等待 → `DeviceOrientation.values`（Web 跳过）
- [x] 1.2 投屏入口确认后仍仅锁 `landscapeLeft/Right`；与 exit helper 对称注释

## 2. 右栏 UI

- [x] 2.1 `_LandscapeColumnDensitySideRail` 顶部加紧凑返回竖屏按钮（`Icons.stay_current_portrait`、`Tooltip`、约 36×36 命中区）
- [x] 2.2 横屏 Row 右栏传入 `onExitLandscape` 回调，调用 exit helper

## 3. 文案与校验

- [x] 3.1 更新投屏确认对话框：移除「需重启应用才能退出」，补充右栏返回竖屏说明
- [x] 3.2 `dart analyze` 触及文件无新增 error
- [ ] 3.3 手工：投屏进横屏 → 点右栏返回 → 竖屏 + 可自由旋转；密度轨仍可拖
