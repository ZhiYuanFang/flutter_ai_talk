## Context

`compactIslandName` 用 `String.prefix(3)` 截事件名；`CompactIslandLeading` 展示该短名。expanded 中心 Imminent `lineLimit(2)`、Timing `lineLimit(1)`。`live-activity-island-compact-name` 曾为控宽刻意三字；现产品要求两侧全放开。Imminent compact 已无 timer 右槽；Timing 仍有 `CompactIslandTimeSlot`。

## Goals / Non-Goals

**Goals:**

- compactLeading：trim 后全名，无 Character 上限、无人为省略号。
- expanded center：移除产品侧 `lineLimit(1|2)`（或不设上限），允许标题按系统布局完整展示／自然换行。
- Imminent 与 Timing 同步。
- 规格废止三字 Requirement，改为全名；文档同步。

**Non-Goals:**

- 不改锁屏标题、不改 Timing/Imminent 时间维策略。
- 不改 compact 名的字段来源规则（仍禁止用锁屏模板句）。
- 不强制给 leading 加固定 maxWidth（首版先全名；若真机过宽再另开 change）。
- 不改推送 Attributes。

## Decisions

1. **`compactIslandName` 只 trim，不再 `prefix(3)`。**  
   可改名为 `islandEventName` 或保留函数名改实现。空串 → leading 仅 logo。

2. **compact Text 仍可 `lineLimit(1)`。**  
   这是单行布局约束，不是字数截断；与「不要限制长度」不冲突。可选 `minimumScaleFactor` 缓解 Timing 过宽，**首版不加**，避免字变太小。

3. **expanded center 去掉 `.lineLimit(...)`。**  
   *备选：改成 `lineLimit(4)` — 仍是人为上限，否决；要松就去掉。*

4. **规格。**  
   REMOVED 两条「三字」Requirement；ADDED／MODIFIED 为 compact 全名 + expanded 不设产品行数上限。

5. **宽度风险接受。**  
   Timing 长名可能撑宽胶囊；产品已知晓，真机验收记录即可。

## Risks / Trade-offs

- [Timing compact 再次过宽] → 验收观察；必要时后续加 maxWidth / scale。  
- [超长 title 整句进 compact] → 对端应下发短事件名；本版不二次截断。  
- [expanded 多行撑高] → 系统 Live Activity expanded 区域有限，属可接受。

## Migration Plan

1. 发版 App + Extension。  
2. 回滚：恢复 `prefix(3)` 与 expanded `lineLimit`。

## Open Questions

- 无（探索已定：compact 全名 + expanded 去 lineLimit，两边一起）。
