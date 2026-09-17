## 1. UCG PageView KeepAlive

- [x] 1.1 在 `ucg_home_shell.dart` 新增 `_KeepAliveUcgPage`（`AutomaticKeepAliveClientMixin`，`wantKeepAlive => true`），模式对齐 `_KeepAlivePredictionPage`
- [x] 1.2 `PageView.builder` UCG 分支：在 `_ucgEverMounted` 之后用 KeepAlive 包装 `UcgShell` / `FeatureLockOverlay` 整棵子树；保留懒挂载闸门
- [x] 1.3 确认资格锁态与合格态切换仍渲染正确，且往返不 dispose 广场 State

## 2. 可选与校验

- [x] 2.1 （可选）`ucgEligibilityStateProvider.ensureLoaded`：已 ready 时短路，避免每次进 UCG 重复资格 HTTP
- [x] 2.2 `flutter analyze` 覆盖改动的 `ucg_home_shell.dart`（及若改 eligibility notifier）通过
- [ ] 2.3 手工：预测↔UCG 多次往返，「推荐」列表与滚动位置保持，无整表首刷加载态
- [ ] 2.4 手工：冷启未进 UCG 时无 `UcgShell`、无推荐首刷、无定位授权弹窗；首次进入 UCG 仍正常首刷
- [x] 2.5 本 change 不改 `app/android/**`；若触及原生须补 release 构建与 proguard
