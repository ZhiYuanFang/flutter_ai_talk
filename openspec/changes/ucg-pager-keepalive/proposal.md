## Why

用户从智能预测页横滑到 UCG 时，「推荐」Feed 几乎每次都会整表重拉（定位 + `fetchRecommendedFeed`）。根因是 `/home` PageView 上喂养与预测已用 `AutomaticKeepAliveClientMixin` 保活，UCG 槽位仍是裸 `UcgShell`：滑走即 dispose，再滑回 remount → `UcgSquareTab.initState` 固定 `_load(refresh: true)`。产品预期是离开再回来保留列表与滚动，而不是每次当首次进入。

## What Changes

- 首次进入 UCG 后，PageView UCG 槽位 **必须** 与喂养/预测一样 KeepAlive，滑走 **不得** 销毁 `UcgShell` / 广场 State。
- 保留既有懒挂载：冷启动未进过 UCG 时 **不得** 提前 build `UcgShell`、**不得** 触发推荐首刷 / 定位授权。
- 再次进入已挂载的 UCG **不得** 仅因 PageView 切页而触发广场「推荐」整表 refresh（发帖变更、下拉刷新、模式切换等既有路径除外）。
- （可选轻量）进 UCG 时若资格态已 ready，`ensureLoaded` 可短路，避免多余资格 HTTP；不改变资格语义。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `ucg-home-entry`：UCG 页在首次挂载后 MUST KeepAlive；再次横滑进入 MUST NOT 因 remount 重跑广场首刷。

## Impact

- **Flutter**：`app/lib/ucg/ui/ucg_home_shell.dart`（新增 `_KeepAliveUcgPage` 或等价包装；itemBuilder 返回保活子树）。
- **广场**：`UcgSquareTab` 的 `initState` `_load(refresh: true)` 可保留（仅真·首次挂载触发）；不必为修此 bug 改 Feed API。
- **Android / iOS / API**：无原生与接口变更。
- **测试**：不新建 `**/test/**`；手工验收预测↔UCG 往返推荐列表与滚动位置保持。
