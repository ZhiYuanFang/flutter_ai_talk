## 1. 位置存储与球组件

- [x] 1.1 新增 `UcgSquareDockStore`（独立 prefs keys；默认 `DockEdge.right` + along≈0.5）
- [x] 1.2 新增 `UcgSquareEdgeDock`：EdgeDockShell、纯图形球面、按 DockEdge 换角的未读红点、occupancy、锁 PageView 横滑
- [x] 1.3 interactive 点按 → `requestPage(HomePagerPage.ucg)`；松手持久化 edge/along 或 floating

## 2. 挂载与资格预热

- [x] 2.1 在 `SmartPredictionScreen` 竖屏条件挂载广场球（`qualified` + 非横屏 + pager 开启）
- [x] 2.2 在 `UcgHomeShell._onEnterPredictionPage`（或等价）主动 `ucgEligibilityStateProvider.ensureLoaded()`
- [x] 2.3 红点绑定 `ucgUnreadCountProvider > 0`（无数字），与消息 tab 同源

## 3. 验收

- [ ] 3.1 合格：预测竖屏见球；点按进 UCG；拖动不切页；首启右中 peek，拖后重启仍记住
- [ ] 3.2 左右贴边 peek 时红点仍在屏内半圆；有未读有点、无未读无点
- [ ] 3.3 未合格 / 横屏 / 喂养无球；`openspec validate ucg-square-edge-dock-ball --strict`
