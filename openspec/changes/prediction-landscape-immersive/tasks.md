## 1. 依赖

- [x] 1.1 在 `app/pubspec.yaml` 增加 `wakelock_plus`（或 design 选定等价包）并 `flutter pub get`

## 2. 生命周期绑定

- [x] 2.1 预测页（或宿主）在「可见 ∩ 横屏」时启用 `immersiveSticky` + wakelock；竖屏或不可见时恢复 `edgeToEdge` 并 disable wakelock
- [x] 2.2 结合 `homePagerIndexProvider`（或等价）处理 PageView KeepAlive，滑离预测页必须释放
- [x] 2.3 横屏去掉顶/底 SafeArea 占位；竖屏保持现有 SafeArea

## 3. 校验与冒烟

- [x] 3.1 `openspec validate prediction-landscape-immersive --strict`
- [ ] 3.2 手工：预测横屏无状态栏+常亮；回竖屏/滑走恢复；喂养横屏不被误开
