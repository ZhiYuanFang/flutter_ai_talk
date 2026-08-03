## Context

- hero = `predictAllUpcoming` 按 `nextAt` 排序后的 first；`recentLast` 为预测事件的 lastAt 列表（large 展示时再排除当前 hero）。
- 整卡点击目前一律 launch App；无 `registerInteractivityCallback`。
- 约束：`openspec/project.md`——小组件 native 不联网；Android 原生改动须 release 构建；副作用 HTTP 治理不适用于本本地 skip；Debug 用 `AppDebugLog`。

## Goals / Non-Goals

**Goals:**

- small/large hero 右侧「跳过」；点击后 S1 抑制该 `eventId` 仅影响 hero，下一未 skip 预测升为 hero；后续留意仍可展示已 skip 事件的上次记录。
- Android + iOS（iOS 在支持交互的系统版本上）。
- 该事件新历史记录后自动解除 skip；登出清空。

**Non-Goals:**

- medium 跳过按钮；App 内预测列表跟跳；后端 API；在 native 重写预测引擎；Web。

## Decisions

1. **S1 存储**  
   prefs 存 `eventId → baselineLastAt`（跳过瞬间该事件预测/历史上的 lastAt，或 ISO 时间戳）。解除：sync 时若该事件当前 `lastAt > baseline`（或出现更新记录）则移除。  
   **备选**：仅存 Set 无 baseline → 难区分「同一次预测周期」；否决。

2. **过滤点**  
   `forHero = filter(predictions, skipped)` → `buildWidgetHero`；`recentLast` 用未过滤的 `predictions`（产品：跳过≠从后续留意消失）。large native 仍排除当前 hero id 避免重复占槽。

3. **交互通道**  
   `home_widget` Interactive Widgets：URI 如 `pangbao-widget://skip?eventId=`。  
   - Android：skip 控件独立 PendingIntent（Background），其余区域仍 launch。  
   - iOS：`Button(intent:)` + 双 target `AppIntent` 调 `HomeWidgetBackgroundWorker`；必要时 `ForegroundContinuableIntent`；`#available` 包裹按钮。

4. **回调内重建**  
   entry-point 回调内：写 skip → 尽量用与 sync 相同的数据源重建 payload（ProviderContainer / 精简 bootstrap）→ `updateWidget`。避免依赖前台 UI。冷启后台须短路完整 splash/WS。

5. **空列表**  
   全部被 skip 或无预测：hero/recent 按现有 empty/noPrediction 文案路径处理。

6. **文案**  
   按钮固定「跳过」。

## Risks / Trade-offs

- [iOS Intent 不进 Dart] → Target Membership + ForegroundContinuableIntent；验收前台/后台/杀进程。  
- [后台跑完整 main] → background 启动检测，只跑 widget 重建。  
- [skip 后 hero 空但 recent 仍有项] → small 可能无 hero；large 仍可展示后续留意。  
- [Android R8] → release 构建验证；BackgroundReceiver 按需 keep。

## Migration Plan

- 纯客户端；无 skip prefs 时行为与现网一致。  
- 回滚：去掉按钮与过滤即可。

## Open Questions

- （无）文案「跳过」、skip 不进后续留意、S1、双端已拍板。
