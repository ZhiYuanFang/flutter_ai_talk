## Context

`PredictionWidgetShowcaseFab` 以宽 pill 居中钉在 `smart_prediction_screen` 竖屏底，列表 `cardsBottomPad` 约 96。竖屏语音球已在 `UcgHomeShell`；广场球在预测页 Stack。三者都走 / 应走 `EdgeDockOccupancy`。基线 `prediction-widget-showcase` 要求已登录已绑定的竖屏悬浮入口；实现曾额外要求「有正式 nextAt」，与基线略漂移。

## Goals / Non-Goals

**Goals:**

- 小组件入口改为壳上 EdgeDock 圆球；去掉底栏宽 FAB 与超额底垫。
- 与语音/广场球占位共存；可拖、可 peek、位置可持久化。
- 点击仍进 `/widgets/showcase`；钉态文案可达（Semantics / engaged 短 caption）。

**Non-Goals:**

- 改 showcase 页、sync、native 小组件；横屏入口；把入口塞进其它球的菜单。

## Decisions

1. **挂载点：`UcgHomeShell`**  
   与 `PredictionVoiceEdgeDock` 同层 `Positioned.fill`；仅当 `homePager == prediction`、竖屏、平台支持、`deviceNo` 非空时挂载。  
   *备选*：仍挂预测页 Stack → 否决（产品要「挂壳」）。

2. **组件形态**  
   新建 `PredictionHomeWidgetEdgeDock`（镜像语音/广场）：`EdgeDockShell` + 圆形 `Icons.widgets_outlined`；`occupancyId = kEdgeDockOccupancyHomeWidgetId`（sticky）。默认 peek：右侧偏下（如 along≈0.72），减少与广场默认右中、语音常见位重叠；松手走 occupancy resolve。  
   独立 prefs store（如 `home_widget_dock_v1_*`），勿复用语音/广场 keys。

3. **可见性**  
   对齐基线：**已登录已绑定** + 竖屏 + 预测 Tab 可见 + Android/iOS。去掉「必须有正式 nextAt」额外门闩（纠正与基线漂移）；无预测时 showcase 仍可引导添加。

4. **文案**  
   球面无长文案；`Semantics(label: 添加|查看桌面小组件)` 按 `hasPinnedHomeWidget` 刷新（lifecycle resume 同现 FAB）。可选 engaged 旁短 caption；peek 不强制出字。

5. **拆除**  
   预测页移除 FAB `Positioned`；`cardsBottomPad` 回到无 FAB 的常规值（如 24）；删除或瘦身 `prediction_widget_showcase_fab.dart`（若仅 FAB 使用）。广场球 `bottomReserve` 若曾为 FAB 抬高，改回与语音底栏一致。

6. **锁滑**  
   `onPointerOccupied` → `homePagerScrollBlockedProvider`，与语音/广场一致。

## Risks / Trade-offs

- [三球拥挤] → occupancy + 默认 along 错开；sticky 互推。  
- [图标不识] → Semantics + showcase 内完整文案；engaged 短 caption 可选。  
- [无 nextAt 也出球] → 符合基线；showcase 已处理空态。

## Migration Plan

1. 加 dock + occupancy id + store；壳上条件挂载。  
2. 拆预测页 FAB 与底垫。  
3. 回滚：恢复 FAB Positioned 即可。

## Open Questions

- （已定）方案 A；挂壳；基线登录绑定可见性。
