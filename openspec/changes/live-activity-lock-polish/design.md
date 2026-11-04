## Context

`live-activity-lock-two-tier` 将锁屏改为双层，并把 Timing/Imminent 时间位从系统 `Text(timerInterval:)` 换成自算中文 + 分钟档 `TimelineView`。后果是锁屏 Timing 常不刷新；产品现要求时间位重新「会动」，并接受带秒；同时去掉「已过去」「…计时中」、上层 App 圆标，事件图缩至约 2/3。实现面集中在 `PredictLiveActivityViews.swift` 的 `LockScreenTwoTier` 与 Timing 锁屏 trailing。

## Goals / Non-Goals

**Goals:**

- Timing 锁屏右侧：系统 `Text(timerInterval:)` 自 `startTime` 起已计时（`countsDown: false`），允许带秒，由系统驱动刷新。
- Timing 锁屏标题：不再追加「计时中」；有名显示事件名，空名短兜底（如「事件」）。
- 上层品牌行：仅「胖宝」文字，无 `AppBrandMark` / 圆形 BrandLogo。
- 下层事件 logo：约 `56 * 2/3 ≈ 37` pt（Imminent / Timing 共用）。
- 同步 `LIVE_ACTIVITY.md` 与 capability 规格。

**Non-Goals:**

- 不要求锁屏格式为无秒的 `hh:mm`，不要求「不足 1 分钟按 1 分钟」。
- 不改 Island compact/expanded 的自算 `hh:mm:ss`（含 `CompactIslandTimeSlot`）。
- 不改 Imminent 锁屏「预计m分钟后」语义与过期无时间维文案。
- 不改推送 Attributes、App Group 视觉索引、本地 `Activity.request` 策略、Android。
- 不上 iOS 18-only `TimeDataSource` 双路径。

## Decisions

1. **Timing 锁屏回到 `timerInterval`，接受系统秒级格式。**  
   用 `Text(timerInterval: start...end, countsDown: false, showsHours: true)`（或等价）；`end` 取自 `startTime` 起有限上界（约 99 小时），避免历史上 `Date.distantFuture` 在部分场景的测量副作用；锁屏满宽不套 compact 占位槽。  
   *备选：继续中文 TimelineView — 否决（刷新不可靠）。*  
   *备选：iOS 18 FormatStyle 无秒 — 否决（部署分叉 + 本变更明确允许带秒）。*

2. **删除锁屏中文已计时 helper 的产品职责。**  
   `LockTimingMinuteText` / `timingElapsedChinese` 不再用于锁屏 trailing；可删除或降为未引用死代码一并清掉，避免回归。

3. **`timingLockTitle` 去后缀。**  
   `name.isEmpty ? "事件" : name`（文案可微调但 MUST NOT 含「计时中」）。Island 标题函数已基本无后缀，保持不动或仅对齐空兜底。

4. **`LockScreenTwoTier` 上层只留字。**  
   去掉 `AppBrandMark` 调用；可保留或删除 `AppBrandMark` 类型（若无引用则删）。「胖宝」仍用事件提亮色。

5. **事件图尺度。**  
   `eventLogo` size `56` → `37`（整数 pt）；标题/时间字号本变更不强制再缩，以免与「时间要醒目」冲突；若真机溢出再微调（非本设计硬约束）。

6. **Imminent 只吃共用布局变更。**  
   `LockImminentMinuteText` 保留；仅随 TwoTier 失去圆标、logo 变小。

## Risks / Trade-offs

- [系统 timer 带秒 / AOD 可能显示 `h:--`] → 产品已接受「会动优先」；AOD 降级为系统行为，不额外自绘。  
- [与 Island `hh:mm:ss` 自算并存两套时间实现] → 锁屏系统 Text、Island TimelineView，职责分离已有先例；不强制锁屏也自算秒。  
- [compact 曾被无界 timerInterval 撑宽] → 锁屏路径不进 `CompactIslandTimeSlot`；Island 仍用自算 + 占位，风险隔离。  
- [空事件名兜底「事件」偏短] → 优于「事件计时中」；推送侧仍应尽量带 `eventName`。

## Migration Plan

1. 仅发版 App + Widget Extension；用户更新后新 UI 生效。  
2. 回滚：恢复 `LockTimingMinuteText` 中文、`…计时中`、`AppBrandMark`、logo 56。

## Open Questions

- 无（探索已定：会动允许带秒；全部 Timing 去「计时中」；上层只去 logo；事件图 2/3）。
