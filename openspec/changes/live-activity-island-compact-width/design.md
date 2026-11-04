## Context

`PredictLiveActivityViews.swift` 中 Imminent / Timing 的 `compactTrailing` 直接放入与锁屏共用的 `ImminentCountdownText` / `TimingElapsedText`。二者内部使用 `Text(timerInterval:)`；Timing 区间接到 `Date.distantFuture`。系统计时 Text 按区间理论上最长数字预留固有宽度，compact 岛按子视图固有宽度变长，形成互抬，岛被拉到接近满屏。锁屏 `HStack + Spacer` 满宽是规格内形态；长按 expanded 本就是宽胶囊。`live-activity-lock-ui` 未约束 compact 岛宽。

## Goals / Non-Goals

**Goals:**

- compact 灵动岛保持胶囊：固有宽度由短占位报告，真计时叠在槽内。
- Imminent 倒计时与「已过时」、Timing 已计时在 compact trailing 仍可见、仍每秒走。
- Timing compact 计时区间有上界，不再使用 `distantFuture`。
- 锁屏大字靠右、expanded / minimal、Attributes / 推送不变。

**Non-Goals:**

- 不改锁屏或 expanded 的「左图 / 中标题 / 右时间」结构。
- 不改 `showsHours` 产品格式（可后续另议）。
- 不改 token 注册、`Activity.request` 策略、Go 扇出。
- Android / Web。

## Decisions

1. **用隐藏占位 + overlay，而不是 `.frame(maxWidth:)`。**  
   compact 岛先问子视图固有 / ideal 宽度，`maxWidth` 经常箍不住。隐藏 `"00:00:00"`（等宽数字）向岛报告宽度，真计时 `overlay` 在该框内，可 `minimumScaleFactor` + 单行。  
   *备选：只加 `frame(maxWidth:)` — 岛上不可靠；否决为唯一手段。*  
   *备选：只缩短 Timing 区间 — Imminent 仍可能撑开；仅作防御。*

2. **包装只套在两个 `compactTrailing`，不改计时 View 本体。**  
   `ImminentCountdownText` / `TimingElapsedText` 继续给锁屏当大字（锁屏需要吃掉 Spacer 右侧空间）。compact 用私有槽（如 `CompactIslandTimeSlot`）包裹现有 View。

3. **「已过时」不走 `timerInterval`。**  
   现有普通 `Text("已过时")` 保持。若整段被占位槽包裹，「已过时」可缩小进 `"00:00:00"` 宽；不得为了这三个字改回无界 timer。

4. **Timing 区间上界约 99 小时。**  
   compact（及同一 `TimingElapsedText` 若共用区间）用 `start...(start + ~99h)`，不再 `distantFuture`。超过上界后数字停在上限可接受：服务端本应更早 end。占位 `"00:00:00"` 与 `H:MM:SS` / `HH:MM:SS` 同量级。  
   *若实现选择只在 compact 换区间、锁屏仍 `distantFuture`：允许，但锁屏不得再用 `.fixedSize()` 以免重现溢出。优先同一有界区间，少分叉。*

5. **expanded / minimal / 锁屏不动。**  
   expanded 已是宽胶囊；minimal 已是 logo / 闹钟图标。

## Risks / Trade-offs

- [占位偏窄，「已过时」或 `10:00:00` 被裁] → `minimumScaleFactor`（约 0.6）+ 单行；占位用 `"00:00:00"`。  
- [只改 `frame` 真机仍满宽] → 验收以占位 overlay 为准，不把 `maxWidth` 当主方案。  
- [锁屏与 compact 分叉后一边漏改] → 计时语义仍集中在现有两个 View；槽只限宽。  
- [99h 后 Timing 数字冻结] → 依赖对端 end；不在客户端无限累加。

## Migration Plan

1. 随 App Extension 发版；用户更新后新的 Live Activity 用新布局。  
2. 已挂起的 Activity 可能仍显示旧 Extension 快照，至下次 start/update。  
3. 回滚：去掉 compact 槽、Timing 区间恢复 `distantFuture`。

## Open Questions

- 无（探索已定：只箍 compact、占位 overlay、Timing 区间有界）。
