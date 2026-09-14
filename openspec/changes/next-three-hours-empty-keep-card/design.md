## Context

`buildNextThreeHoursTimelineText` 在窗内段落为空时返回 `null`；预测页用 `timelineText != null` 决定是否渲染 `_NextThreeHoursTimeline`。AI 分析入口挂在该卡上，空窗时入口一并消失。Auth 冷态本就不展示三小时卡，本变更不改。

## Goals / Non-Goals

**Goals:**

- 已绑定态空窗仍显示三小时卡 + 指定空态文案，保证「AI分析」常显
- 有事项时文案与手势行为不变

**Non-Goals:**

- 不改段落算法 / 3h 窗口 / 推演关闭过滤
- 不改 Auth 冷态隐藏规则
- 不改 AI 分析路由或喂养跳转

## Decisions

1. **展示条件**：`!authGuestChrome` 即渲染卡；不再依赖 `timelineText != null`。  
2. **正文**：`timelineText ?? '接下来 3 小时暂无事项，享受属于自己的时光吧。'`（或等价常量）。  
3. **builder 可保持返回 `String?`**：UI 层兜底空文案即可，避免扩散改调用方；若希望单点真相，也可让 builder 空窗返回该常量——取 UI 兜底更小 diff。  
4. **空态手势**：与有数据时相同（主区喂养、AI 分析独立）。

## Risks / Trade-offs

- [空态卡占纵向空间] → 产品接受，换入口可达性  
- [规格与旧「空窗隐藏」冲突] → 本 change 明确覆盖该 Requirement

## Migration Plan

纯客户端；回滚恢复 `timelineText != null` 门闸。

## Open Questions

无。
