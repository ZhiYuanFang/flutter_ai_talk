## Context

竖屏预测页已有标题栏图标切换 `PredictionCardsLayout.list` / `.grid`（瀑布 compact）。列表卡为准确率图区；网格卡为倒计时预测卡。骨架 `useDemoSkeleton` 时卡 tap 走登录/绑定意图，不应再被长按切布局。横屏 `useGridLayout` 恒 true。

## Goals / Non-Goals

**Goals:**

- 竖屏整卡长按：当前 grid → list；当前 list → grid；持久化 + 既有 usage 事件。
- 骨架卡不参与；标题栏切换保留。

**Non-Goals:**

- 仅 chrome 可长按；横屏改布局；新布局枚举；改图区短按小结。

## Decisions

1. **回调挂点**  
   `_PredictionEventCard` 增加可选 `onLongPressLayout`；外层 `InkWell`（或与 `onCardTap` 同层 Material）设 `onLongPress`。无回调则不响应（骨架 / 横屏不传）。

2. **谁传回调**  
   竖屏 `!useDemoSkeleton` 的 list/grid `itemBuilder` 传入同一闭包：读当前 layout → `setLayout(other)` → haptic（可选 `HapticFeedback.lightImpact`）→ usage 上报（与标题栏同事件）。横屏 waterfall builder **不传**。

3. **图区与子控件**  
   准确率图区继续吞短按；长按由父级 InkWell 竞争——Flutter 中子级未声明 `onLongPress` 时父级可收到。Switch / 停止等若吞长按则该落点不切换，可接受。

4. **骨架**  
   `useDemoSkeleton == true` 时不挂 `onLongPressLayout`，避免误切布局或与闸门手势纠缠。

## Risks / Trade-offs

- [用户误触长按] → 仅切换布局可逆；标题栏仍可切回。  
- [图区长按偶发不触发] → 可再挂图区显式转发；v1 先整卡 InkWell。

## Migration Plan

1. 卡加 longPress；竖屏 builder 接线。  
2. 回滚：去掉回调即可。

## Open Questions

- （已定）整卡；骨架不参与；竖屏；保留 AppBar。
