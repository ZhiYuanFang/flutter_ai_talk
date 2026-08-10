## Context

预测页当前在标题下渲染玻璃 tip 卡（「小贴士」+ 正文 +「点击进入陪伴」），再接值得留意与 list/grid 卡片。产品要求 tip 沉底、去标签、横向跑马灯，短文静止，点击进陪伴。

## Goals / Non-Goals

**Goals:**

- tip 固定在预测页底部；无文案则隐藏。
- 只显示正文；横向溢出才滚，否则静止。
- 整条可点 → 激活陪伴 WS + `push('/companion')`。
- 卡片区不被底栏遮挡（Column 底槽或等价 padding）。

**Non-Goals:**

- 不改 tip 文案来源与缓存策略。
- 不改值得留意竖向跑马灯规则。
- 不做多条 tip 轮播（单段文案）。

## Decisions

### D1：页面结构

```
Column(
  标题(+布局图标),
  值得留意?,
  Expanded(卡片 list|grid),
  tip 底栏?,   // 有文案才挂
)
```

- tip 从标题下方 **删除**。
- SafeArea 包住含底栏，尊重底部 inset。

### D2：横向跑马灯

- 测量文案 intrinsic 宽度 vs viewport；`overflow →` 循环/单向横向滚动；否则左对齐或垂直居中静止。
- 实现可选：`OverflowBox` + `AnimationController`、或 `marquee` 自研轻量；不强制新依赖。
- 滚动速度约 30–40 logical px/s；停顿可选（实现微调）。

### D3：视觉

- 保持玻璃拟化轻条，高度约单行 + 垂直 padding；无标题/CTA 行。
- `maxLines: 1`；过长依赖横向滚而非折行。

### D4：点击

- 整条 `InkWell`/`GestureDetector`；逻辑复用现 tip `onTap`（`activateCompanionClinicWs` + `/companion`）。

## Risks / Trade-offs

- [底栏挡最后一行卡片] → Column 底槽，不用裸 Stack 浮层。
- [短文误滚] → 宽度测量后再决定是否开动画。
- [与留意双跑马灯干扰] → 轴向不同、定位不同，可接受。

## Migration Plan

- 纯 UI；回滚恢复顶卡即可。

## Open Questions

- （无）短文静止已冻结。
