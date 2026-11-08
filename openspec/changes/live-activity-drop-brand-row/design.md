## Context

`unify-live-activity-list` 已在锁屏画居中主题色「胖宝」顶栏 + `items` 行。产品现要求去掉内容区 App 名以减高度；系统 LA 外框仍可表达 App 身份。Island 本无该品牌行。

## Goals / Non-Goals

**Goals:**

- 锁屏 Live Activity 内容区不渲染「胖宝」或等价 App 名顶栏。
- 保留按 `items` 动态堆叠的 Imminent/Timing 行样式与间距策略（可略收紧原顶栏相关 spacing）。
- 文档与 `unified-live-activity` 需求对齐「无品牌行」。

**Non-Goals:**

- 改 Island、register、ack、Go、桌面 Widget、行内事件名/logo。

## Decisions

1. **删除顶栏 HStack，不改行组件**  
   `BabyLiveActivityWidget` 锁屏 `VStack` 仅 `ForEach(items)`；行视图不动。  
   *备选：缩小字号保留品牌 — 否决（用户要去掉以减占位）。*

2. **主题色常量**  
   `themePrimaryHex` / `laThemeBrandColor` 若仅服务顶栏则删除或保留但不再引用；不引入新色。

3. **独立 change**  
   不回写打乱 `unify-live-activity-list` 已勾任务历史；以本 change 的 MODIFIED spec 覆盖顶栏要求。实现依赖统一列表 Widget 已存在。

## Risks / Trade-offs

- [品牌弱化] → 接受；依赖系统 LA 外壳 App 标识。  
- [与 unify 文档短暂不一致] → 本 change 更新 `LIVE_ACTIVITY.md` 并 MODIFIED spec。

## Migration Plan

1. 改锁屏视图 + 文档。  
2. 真机确认高度下降且无「胖宝」顶栏。  
3. 回滚：恢复顶栏 HStack（一行级）。

## Open Questions

- 无（范围：仅锁屏 LA 内容区 App 名）。
