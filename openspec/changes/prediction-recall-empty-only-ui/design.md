## Context

`prediction-recall-onboarding` 已实现按根缺口排队；现网反馈「有历史仍引导」不符合冷启动定位。UI 为相位切换而非 PageView。用户选定策略 B + 悬浮卡 PageView 禁手滑 + 引导时藏 chrome。

## Goals / Non-Goals

**Goals:**

- 仅空真历史进入量身定做。
- PageView 一卡一页、悬浮感、程序切页、用户不可横滑。
- 引导中隐藏留意 / 三小时 / 底 tip。

**Non-Goals:**

- 不改种子合成公式与「不进喂养」边界。
- 不恢复「有历史仍按根补洞」的全屏引导（弱提示另议）。
- 不新建测试文件。

## Decisions

1. **空库门闸**  
   以 `predictionRangeHistoryProvider.items` 为准（与预测同源）；`items.isEmpty`（且 range ready、非加载中误判）才允许启动回忆会话。可选同时要求 `homeHistory` 空——默认 **仅 range 空** 即可（与预测数据源一致）；若冷启动 range 未 ready，不得误开引导（等 ensure 完成后再判）。  
   一旦有任意真历史：强制 `sessionActive=false`、不入队、不展示面板。

2. **队列内容**  
   空库时仍对全部 `parentId==null` 根建卡（跳过关推演者除外）；有历史后整段引导不再出现。

3. **PageView**  
   `PageController` + `NeverScrollableScrollPhysics`；页序含：各根 card、（确认后）thinking 可作为同根叠加页或独立页、最终 finale。推荐：`[card0, think0?, card1, think1?, …, finale]` 或简化为程序控制 index：card→think→next card→…→finale，视觉仍用 PageView + 悬浮卡装饰。切页仅 `animateToPage` / `jumpToPage`。

4. **Chrome**  
   `showRecallOnboarding == true` 时不 build：`_CareAlertPanel`、`_NextThreeHoursTimeline`、`_BottomTipMarquee`。

## Risks / Trade-offs

- **[Risk] range 未加载完被当成空** → ready 前不启动引导。  
- **[Risk] 仅 range 空但 home 有分页缓存** → 以 range 为准；若产品要双空，实现时 OR/AND 可调（默认 range）。  
- **[Trade-off] 有少量历史的用户无法用引导补洞** → 产品明确接受 B。

## Migration Plan

- 无服务端。已有种子在「之后产生真历史」时仍按旧逻辑 GC。

## Open Questions

- （默认）空库判定看 prediction range items；home 仅作辅助可不看。
