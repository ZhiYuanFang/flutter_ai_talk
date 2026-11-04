## Context

compact 岛 `compactLeading` 目前只有 18pt 事件 logo，`compactTrailing` 已由 `CompactIslandTimeSlot` 箍为 `"00:00:00"` 宽。expanded center 与锁屏已有全名。日常不长按看不到事件名。用户选定方案 B：左 logo + 最多三字，右计时不变。三字从事件名字段截取，不用锁屏模板句。

## Goals / Non-Goals

**Goals:**

- compactLeading：logo 右侧展示事件名，最多 3 个 Character。
- Timing 从 `eventName` 取名；Imminent 从 `title` 取名（契约上即事件名，无独立 `eventName` 字段）。
- 空名只显示 logo。超过三字硬截、无省略号。
- 保持 compact 胶囊：不把全名丢进 leading；不改 trailing 占位槽。

**Non-Goals:**

- 不改锁屏 / expanded 全名文案（仍可用「计时中」等模板）。
- 不改 minimal。
- 不新增推送字段，不把 `name` 写入 `laEventVisuals`。
- 不为拉丁字母单独放宽到 6 字。
- 不改 token / `Activity.request`。

## Decisions

1. **布局：`compactLeading` 为 `HStack(logo 18, Text(前三字))`。**  
   右 trailing 不动。普通 `Text` 按真实字形量宽，三字不会像 `timerInterval` 那样撑满屏；`lineLimit(1)` 即可。  
   *备选：用名字替换 logo — 否决，保留事件色图。*  
   *备选：leading 再套隐藏「某某某」占位 — 非必须；若真机仍被长串撑开再加。*

2. **截断：Swift `Character` 前缀最多 3，无省略号。**  
   `母乳亲喂` → `母乳亲`。按字而非 UTF-16。空 / 空白视为无名称。

3. **数据源：事件名字段，不是锁屏标题函数。**  
   Timing：`state.eventName` 非空则用，否则 `attributes.eventName`。  
   Imminent：无 `eventName`，用 `state.title` 否则 `attributes.title`（LIVE_ACTIVITY：`title` 即事件名文案）。  
   MUST NOT 调用 `timingLockTitle` / `lockTitle(..., empty: "即将发生")` 再截三字，避免出现「事件」或「即将发」。  
   *备选：Imminent 新增 `eventName` 推送字段 — 要改 Go；否决。*  
   *备选：App Group 索引加 name — 本版不需要。*

4. **空名：只 logo。**  
   与截断前行为一致，岛不因空 Text 变宽。

5. **expanded / 锁屏 / trailing 不动。**  
   全名与大字时间、`CompactIslandTimeSlot`、99h 上界保持 `live-activity-island-compact-width`。

## Risks / Trade-offs

- [Imminent `title` 是整句，三字变成「该喝配」] → 契约要求 title 为事件名；残句是对端文案问题，本版不改载荷。  
- [拉丁三字母不可读] → 目录以中文为主；不为本版加拉丁规则。  
- [三字仍略增 leading 宽] → 可接受；不得取消 trailing 占位。  
- [空 title 时 compact 仍无字] → 只 logo；锁屏仍走「即将发生」回退。

## Migration Plan

1. 随 App Extension 发版。  
2. 已挂起 Activity 至下次 start/update 才换布局。  
3. 回滚：`compactLeading` 恢复为仅 logo。

## Open Questions

- 无（探索已定：B、最多三字、从 eventName / Imminent 的 title）。
