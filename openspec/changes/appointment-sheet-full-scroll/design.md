## Context

`showAppointmentNextSheet` 现为 `scrollable: false` + body `LayoutBuilder`：有界高时滚轮 `Expanded`，无界高时固定 200。键盘 inset 把 `contentMaxH` 压得很矮时，非滚 body 溢出（横屏实测 ~55px）。用户要求整窗可滚。

## Goals / Non-Goals

**Goals:**

- 外壳 `scrollable: true`，内容超出 `maxHeightFraction`（扣 inset）时可内滚。
- 滚轮在滚动内容里用固定高度，不依赖 `Expanded`。
- 保留：备注获焦/键盘可见收起滚轮；`respectKeyboardInset`；备注 `keyboardLift`。

**Non-Goals:**

- 不改年份行 / 四列语义 / PUT 契约。
- 不单独做「仅横屏可滚」。
- 不解决 picker 与外层滚动偶发抢手势的深度定制（固定高区域内 picker 优先即可）。

## Decisions

1. **`scrollable: true`**  
   走 `AppAdaptiveBottomSheet` 的 `SingleChildScrollView`；矮约束下可滚到 footer。

2. **统一固定滚轮高**  
   展示滚轮时用固定高度（现有 200 或略按 tight 微调）；删除或闲置「bounded + Expanded」分支，避免与 ScrollView 无界高冲突。

3. **收起滚轮保留**  
   `collapseWheels` 仍只渲染 header+footer（更短），外层仍可滚；双保险。

4. **横竖屏同一策略**  
   实现简单；竖屏内容不足时 ScrollView 不滚动即可。

## Risks / Trade-offs

- [CupertinoPicker 与外滚抢势] → 固定高区内通常可接受；若严重再加 physics 隔离。  
- [竖屏滚轮不再撑满剩余] → 换可滚与矮屏不炸；可接受。

## Migration Plan

纯客户端。回滚：`scrollable: false` + Expanded 即可。

## Open Questions

（无）
