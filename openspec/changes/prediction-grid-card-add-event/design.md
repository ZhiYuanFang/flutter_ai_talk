## Context

喂养主页 `HomeScreen._onEventGridTap` 已实现：父事件 → `showEventCatalogPickerSheet` → `_onEventButtonTap`（time/one/number + remote gate + `addHistoryEvent` + 历史乐观更新 + usage 计数）。预测页网格 `_PredictionEventCard(compact: true)` 仅有推演开关，无加事件入口。

## Goals / Non-Goals

**Goals:**

- 网格卡整卡点击 = 喂养同款加事件（含子选择与三类型）。
- Switch 不误触加事件。
- 成功后留在预测页；抽取共享逻辑供 Home 与 Prediction 调用。

**Non-Goals:**

- 列表态（非 compact）整卡加事件。
- 改服务端事件 API。
- 加完后强制切喂养页或做飞入动画（可选后续）。

## Decisions

1. **范围仅 `compact: true`**  
   与产品「网格态」一致；列表卡保留图表/开关，不加整卡 InkWell。

2. **抽取共享入口（建议模块名）**  
   例如 `app/lib/ui/event_add_actions.dart`（或等价）暴露：
   - `Future<void> handleEventGridTap({required BuildContext context, required WidgetRef ref, required EventDefinition event, ...})`  
   内聚：`hasChildren` → picker → 按 `parsedEventType` 提交；复用 `_ensureRemoteGate` 等价逻辑、`showHomeNumberEventSheet`、`buildEventAddBody`、`feed.addHistoryEvent`、成功后 `homeHistoryProvider` 乐观插入（与 Home 一致，便于切回喂养可见）、`EventButtonUsageStore.increment`、进行中计时重复校验。  
   `HomeScreen` 改为调用该入口；预测页网格卡 `onTap` 同样调用。  
   **替代**：预测页复制一份——否决（易与 Home 漂移）。

3. **手势**  
   卡片外层 `InkWell`/`GestureDetector`；`Switch` 保持独立 `onChanged`。禁用推演的卡片仍可加事件（加事件与推演开关正交）。

4. **完成后导航**  
   不 `requestPage(feeding)`；Toast 沿用 repository / 现有失败提示。

5. **定义缺失**  
   `lookupEventById` 为空或 `!hasValidEventType` 则 no-op（或 Toast），与 Home 叶子无效类型行为对齐。

6. **预测网格叶子确认（仅预测）**  
   `handleEventGridTap(confirmDirectLeafBeforeAdd: true)`：仅当点击目标本身是叶子（未走 picker）且类型非 `number` 时，`showGlassConfirmDialog`；picker 选出的叶子、`number`、喂养主页（默认 false）均不确认。

## Risks / Trade-offs

- [抽取时漏飞入/提醒逻辑] → 首版对齐提交与历史 upsert；Home 专属飞入动画可仍留在 Home 路径或后续接。  
- [预测页无 `_eventAddInFlight` 局部锁] → 共享层用模块级/notifier 单飞，防连点。  
- [未绑定 deviceNo] → 沿用 Home remote gate，不新造规则。

## Migration Plan

- 纯客户端；热重载验证网格点卡。

## Open Questions

- （无）范围、留页、抽取共用已按探索「按建议」冻结。
