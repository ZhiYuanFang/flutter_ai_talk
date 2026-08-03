## Context

- 小组件 tip：`resolveWidgetTip` → `FeedRepository.fetchWidgetFeedingTip` → `POST /device/history/api/chat`（固定 transcript「接下来需要注意什么？」），结果按自然日缓存在 prefs，经 `syncHomeWidgetFromRef` 推原生桌面。
- 首页 tip：SSE `/device/tip/generate`，进陪伴时由 `_onCompanionEntryActions` 注入 `isTipSource` 助手气泡并 `markConsumedForCompanion`。
- 陪伴列表权威在内存 `_items`；`PangbaoClinicSessionStore` 为全量快照。同步路径直接改 store 会与 persist 竞态（已否决 B1）。

## Goals / Non-Goals

**Goals:**

- 进陪伴时将当日未注入的小组件 tip 写入本地陪伴历史（与 tip 同形态）。
- 保留现有拉取与桌面 trim；陪伴用全文。
- 与首页 tip、「我来啦」协调：tip 优先；注入则跳过问候。

**Non-Goals:**

- 不改为 tip/generate 或 Clinic WS 拉文案。
- 不在 widget sync 成功时静默写会话 store。
- 不要求点小组件 deep link 才注入。
- 不新建 tip kind；不改原生小组件布局。
- 不新建自动化测试文件。

## Decisions

1. **B3 注入时机**  
   仅在 `_onCompanionEntryActions`（登录、已同意、有 deviceNo）中注入。  
   **备选**：B1 sync 写 store → 否决（`_items` 覆盖竞态）。  
   **备选**：B2 仅点小组件 → 否决（产品选进页即可）。

2. **缓存字段**  
   在 `widget_tip_cache`（或并列 prefs）保留：`day`、桌面用 `text`（trim）、`fullText`（未截断 reply）、`injected_day`。  
   刷新成功时同时写 trim 与 full；注入读 full，空则回退 trim。

3. **入口顺序**  
   ```
   tip.canInject → 注 tip → markConsumed → persist → markGreeted → return
   else widget pending（day 有文案且 injected_day != today）
     → 注 isTipSource → mark injected_day → persist → markGreeted → return
   else 「我来啦」当日首次
   ```

4. **幂等与清理**  
   `injected_day == today` 则不再注。清理陪伴记录不清除 `injected_day`（避免同日清完再进又注同一句）。

5. **形态**  
   仅助手气泡，`PangbaoClinicTurn.tip` / `isTipSource`；不代发用户问句。

6. **日志**  
   注入/跳过用既有 `AppDebugLog.pangbaoClinic` 或 `homeWidget`，禁止裸 `print`。

## Risks / Trade-offs

- [同日 tip 抢先] → 小组件 tip 延后到下次进页；可接受。  
- [prefs 仅有旧 trim 无 full] → 注入回退 trim；新刷新后有 full。  
- [未开过 sync 无缓存] → 不注入，走问候逻辑。  
- [keep-alive 多次进页] → injected_day 挡住重复。

## Migration Plan

- 纯客户端；旧安装无 `fullText`/`injected_day` 时按缺省处理。  
- 回滚：去掉入口分支即可，桌面 tip 不受影响。

## Open Questions

- （无）探索阶段已拍板：B3、tip 优先、清记录不复位 injected、全文进陪伴。
