## Context

进广场主路径仍是预测页左滑；未读红点只在 UCG 底栏「消息」。tip 球已删；竖屏语音 EdgeDock 代码在但 flag 关闭。`EdgeDockShell` + occupancy 可用。资格靠 `ucgEligibilityStateProvider`；未读靠 `ucgUnreadCountProvider`（与消息 tab 同源）。既有 `ucg-entry-gate` 倾向「进 UCG 才刷 eligibility」，球挂预测页需要提前 ensure。

## Goals / Non-Goals

**Goals:**

- 资格开通后，预测竖屏显示可拖广场贴边球；点按进 UCG。
- 未读红点球内角随贴边换位；无数字。
- 默认右中 peek；prefs 记住位置。
- 预测/shell 主动 ensure eligibility。

**Non-Goals:**

- 不改横屏 / 喂养入口；不恢复 tip 球；不重开竖屏语音球。
- 不改资格算法 / VIP 绕过；不改消息 tab 红点语义。
- 不把广场球塞进 `prediction-history-refresh-on-resume`。
- 不新建 `**/test/**`。

## Decisions

### D1：挂载面 = 预测竖屏 Stack

在 `SmartPredictionScreen` 竖屏 overlay（与语音 EdgeDock 同层思路）条件挂载；`!isLandscape` 且当前为主壳预测页可见时渲染。喂养 / 横屏 / UCG 页不挂。

**备选**：挂 `UcgHomeShell` — 难仅限预测页内容坐标系；否决。

### D2：可见性 = `isQualified` 且 pager 允许 UCG

`kUcgHomePagerEnabled && ucgEligibilityStateProvider.isQualified`。加载中 / fail-closed 未合格 → 不显示球（避免闪假开通）。

### D3：复用 EdgeDockShell + 独立 Store

镜像 `PredictionVoiceEdgeDock` / `PredictionVoiceDockStore`，新建 `UcgSquareEdgeDock` + `UcgSquareDockStore`（keys 如 `ucg_square_dock_v1_*`）。

默认：`DockEdge.right`、`along = 0.5`、`edgePeek`。有 prefs 则还原 edge/along 或 floating。

拖动期间经 `onPointerOccupied` → `homePagerScrollBlockedProvider`，与语音球一致，防误切 PageView。

`occupancyId` 接入共享占位（如 `ucg-square`），与未来语音球共存。

### D4：点按 = requestPage(ucg)

`onInteractiveTap` / engaged 点按 → `homePagerRequestProvider.requestPage(HomePagerPage.ucg)`。peek 累计拉满行为沿用 EdgeDock 既有（先 engage，再可选业务）；**不得**在 peek 轻点误跳页（与壳约定一致：peek 点按不走 interactive）。

### D5：红点几何随 DockEdge

未读：`ref.watch(ucgUnreadCountProvider) > 0`，8px 圆点，球 **内** 角（非 icon 外飘）。

| 贴边 | 红点角落（朝屏内） |
|------|-------------------|
| right | 左上 |
| left | 右上 |
| top | 下侧朝内角（实现定左下或右下之一，保持对称清晰） |
| bottom | 上侧朝内角 |
| floating | 默认右上 |

### D6：球面纯图形

玻璃圆 + `Icons.auto_awesome_rounded`（与底栏「广场」同系）；无 caption、无「广」字。色经 `AppColor` / panelGlass。

### D7：eligibility 预热

在 `UcgHomeShell._onEnterPredictionPage`（冷启默认预测也会走）`unawaited(ucgEligibilityStateProvider.notifier.ensureLoaded())`。既有进 UCG 的 ensure 保留。副作用 HTTP 遵守 single-flight / 熔断（notifier 已有）。

**相对旧 gate 文案**：允许「进入预测」触发 ensure，不仅「进入 UCG」。

## Risks / Trade-offs

- [与小组件 FAB / 未来语音球抢边] → 默认右中 + occupancy；语音默认左。
- [peek 半圆裁掉红点] → D5 换角；验收左右贴边。
- [未合格用户仍靠左滑发现广场] → 有意；锁层进度仍在。
- [ensure 增加 eligibility 请求] → 复用既有 single-flight；与进 UCG 合并。

## Migration Plan

- 纯客户端。回滚：去掉预测挂载与 store；恢复仅进 UCG 才 ensure 的表述（若已改 gate）。

## Open Questions

- 无（explore 已锁定）。
