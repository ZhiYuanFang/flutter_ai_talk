## Context

锁屏 LA UI 在 `PredictLiveActivityViews.swift`：BrandLogo + 标题/副文 + chevron。Timing 用 `TimelineView` 自算已计时且挤在标题下；Imminent 的 `nextAt` 未展示。ContentState 无 logo/color；Imminent Attributes 有 `eventId`，Timing 无。桌面小组件已有 App Group `group.com.fzy.pangbao.widget` + `home_widget_logos/{id}.{ext}` + `parseColor`，但 helper 私有于 `PangbaoWidget.swift`，LA 未复用。Extension 展示瞬间不能跑 Flutter，故「按 eventId 取视觉」= 主 App 预写索引 + Extension 读取。

## Goals / Non-Goals

**Goals:**

- Imminent / Timing 锁屏与 Island：左事件图、中标题、右大字时间；无右箭头。
- Imminent：倒计时至 `nextAt`；到点显示「已过时」。
- Timing：右侧大字已计时；`startTime` 为 unix 秒（对端修复单位）。
- 推送只带 `eventId`（及既有时间字段）；logo/color 由客户端本地解析。
- 深色 LA tint 上事件色过深则提亮。

**Non-Goals:**

- 推送内嵌图片 URL / hex color。
- 改 register / MethodChannel / `Activity.request` 策略。
- 本仓实现 Go fanout（仅契约与联调说明）。
- Android Live Activity。

## Decisions

1. **视觉数据面：App Group 索引，而非推送字段。**  
   Flutter 在 catalog / home-widget enrich / LA 开通相关路径写入 UserDefaults（App Group）键（建议 `laEventVisuals`）：`{ "<eventId>": { "color": "#RRGGBB", "logoFile": "home_widget_logos/…" } }`，并确保 `widgetLogoFileForEvent` 已拷贝文件。Extension 用 `attributes.eventId`（字符串化）查找；缺失则 orb + 默认色或 BrandLogo。  
   *备选：从 `widgetPayload` 行里找 eventId — 行不全，Timing 易 miss；否决。*  
   *备选：推送带 color/logoFile — 产品明确不要；否决。*

2. **Timing Attributes 增加 `eventId`。**  
   与 Imminent 对齐，固定属性携带；ContentState 可不重复。对端 start 载荷 MUST 提供。旧推送缺省时 UI 走无图兜底。

3. **布局：HStack 左图 | 中 VStack 标题 | Spacer | 右大字时间；删除 chevron。**  
   深链仍靠整卡 `widgetURL`。Island compact trailing 显示时间/「已过时」。

4. **时间渲染。**  
   Timing：优先 `Text(timerInterval:countsDown: false)`（或等价）自 `startTime` 起算，`.font(.title3.monospacedDigit().weight(.semibold))`。  
   Imminent：TimelineView / timerInterval 倒计时至 `nextAt`；`now >= nextAt` 则固定文案「已过时」。  
   *`00:00` 根因归对端 `startTime` 单位（毫秒当秒 → 远未来 → 钳 0）；客户端不靠猜单位纠偏。*

5. **过深提亮。**  
   共用 `parseColor` 后算相对亮度；低于阈值向白插值，仅用于 LA 文案/时间路径；桌面小组件可继续用原色。

6. **抽取 Swift helper。**  
   新建 Extension 内共享文件（如 `WidgetVisualHelpers.swift`）：`loadLogoImage`、`eventLogo`、`parseColor`、`laAccentColor`（含提亮）、读 `laEventVisuals`。桌面与 LA 共用。

## Risks / Trade-offs

- [索引未写完就推送起 LA] → 兜底 BrandLogo/orb；在 catalog sync 与 `startIfEligible` 路径预热。  
- [eventId Int64 vs catalog 字符串 id 不一致] → 联调确认十进制字符串；索引 key 统一用字符串。  
- [对端未上 Timing eventId] → 本仓可解码缺省 0；UI 无图但布局仍正确。  
- [提亮过度发粉/发白] → 阈值与插值系数可调；真机对照事件色表。

## Migration Plan

1. 发版 App + Extension；用户需更新客户端。  
2. 对端先/同步发布 Timing `eventId` + unix 秒。  
3. 回滚：恢复旧 Views；索引键可留无害。

## Open Questions

- 无（探索阶段已定：无箭头、「已过时」、本地视觉、提亮）。
