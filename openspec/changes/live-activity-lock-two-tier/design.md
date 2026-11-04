## Context

`PredictLiveActivityViews.swift` 中 Imminent / Timing 的锁屏 `ActivityConfiguration` content 仍为单行：事件 logo（28pt）+ 标题 + `Spacer` + 系统 `Text(timerInterval:)` 秒级数字。灵动岛 compact 已用 `CompactIslandTimeSlot` 箍宽，且 compactLeading 最多三字事件名。Extension 无法可靠区分设备是否锁定；未解锁锁屏约按分钟档刷新，秒级数字价值低。产品已定：锁屏双层 + 中文到分钟；Island 保留数字但固定 `hh:mm:ss`。

## Goals / Non-Goals

**Goals:**

- 锁屏 content：上窄行品牌（圆形 BrandLogo +「胖宝」），下宽行事件 logo + 既有标题 + 右侧中文时间；下层尺度约翻倍；时间靠右。
- Timing 锁屏时间：「已过去h时m分钟」；`h=0` →「已过去m分钟」；不足 1 分钟按 1。
- Imminent 锁屏时间：「预计m分钟后」（总分钟）；不足 1 分钟按 1；`now ≥ nextAt` 时右侧不展示时间维文案（含「已过时」）。
- Island（compact / expanded 时间位）：始终 `hh:mm:ss`（两位时分秒）；compact 继续短占位，禁止中文长句进 trailing。
- 标题语义：`timingLockTitle` / `lockTitle` 不变。

**Non-Goals:**

- 按锁定态分支两套锁屏文案。
- 改 compact 三字名、胶囊宽度策略、推送 Attributes、本地 `Activity.request`、Android。
- 改上层 App 名为动态/多语言资源以外的产品名（本变更固定「胖宝」）。

## Decisions

1. **锁屏用 VStack 双层，不用单行塞品牌。**  
   上层 `HStack`：圆形 clip 的 `BrandLogo` + `Text("胖宝")`，accent = 事件提亮色，字体/图标小于下层。下层：事件 `eventLogo`（约 56pt 量级）+ 原标题函数 + `Spacer` + 中文时间。  
   *备选：品牌替换事件图 — 否决（探索已澄清要两层）。*

2. **锁屏时间自算分钟文案 + 分钟档 TimelineView，不用 timerInterval。**  
   由 `startTime` / `nextAt` 与 `context.date` 算整分钟（`ceil` 到至少 1）；Timing 拆 h/m；Imminent 只输出总 m。过期 Imminent 返回 `nil`/空，下层不渲染 trailing。  
   *备选：继续 timerInterval 再本地化 — 系统格式不可控且带秒；否决。*

3. **Island 数字强制 `hh:mm:ss`。**  
   不依赖系统 `timerInterval` 在不足 1h 时的省略行为；用 `TimelineView(.periodic(by: 1))` + 自格式化 `%02d:%02d:%02d`（Timing 已计时；Imminent 倒计时）。仍包在 `CompactIslandTimeSlot` 内，占位保持 `"00:00:00"`。Imminent 过期：compact trailing 可空或仅留占位叠空内容（与锁屏一致：无「已过时」）；expanded trailing 同。  
   *备选：仅 `showsHours: true` — 真机仍可能 `mm:ss`；否决为唯一手段。*

4. **尺度。**  
   下层事件 logo / 标题 / 时间相对现状约 ×2（如 logo 28→56，标题 subheadline→title 级）；上层保持窄小。以真机不溢出为微调上限。

5. **文档。**  
   `LIVE_ACTIVITY.md` 补一句锁屏双层与中文/Island 格式差异；不改推送字段表。

## Risks / Trade-offs

- [锁屏卡片变高] → 双层是产品意图；控制上层 padding，避免无意义空白。  
- [自算 hh:mm:ss 与系统 timer 观感差] → Island 仍每秒刷新；锁屏按分钟文案可接受。  
- [Imminent 过期右侧空白] → 产品明确不要时间维文案；下层仍有事件图+标题可辨。  
- [中文误入 compact] → 规格与代码路径分离：锁屏 helper ≠ Island helper。

## Migration Plan

1. 仅发版 App + Widget Extension；用户更新后生效。  
2. 回滚：恢复单行 + timerInterval /「已过时」视图。

## Open Questions

- 无（探索已定：双层、中文规则、Island `hh:mm:ss`、标题不变、过期无时间文案）。
