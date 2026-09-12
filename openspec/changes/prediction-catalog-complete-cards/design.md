## Context

已绑定用户在 `buildSmartPredictionRows` 因 `byKey.isEmpty` 得到空列表后，热态落到 `AppEmptyStateGallery`（「回忆宝宝习惯」）；空库量身定做 Dialog 仍可按 `predictionRecallEmptyHistoryEligible` 自动弹出。假骨架曾覆盖「已绑定空历史」，但实现已改为仅未登录/未绑定走骨架，空库热态既无假倒计时也无真卡。

产品目标：主内容永远有目录非子全量卡；补齐走卡内 CTA；退役 Dialog；不引入「仅间隔」草稿契约。

约束：`PredictionRecallSeed` 仍要求 `lastAt`；回忆种子不得写喂养历史；不新建 `**/test/**`；主题色走 `AppColor` / 事件品牌色。

## Goals / Non-Goals

**Goals:**

- 热态行列表以 `rootEvents(catalog)` 为全集（含已关推演 root）。
- 去掉空历史缺省页与量身定做 Dialog 自动路径。
- 卡上补齐：无 `lastAt` + 推演开 → 心跳「补充上一次」（= `handleEventGridTap`）；有 `lastAt` + 无 pred + 推演开 → 既有间隔 CTA；推演关 → 两种 CTA 皆无，整卡不加事件。
- `_PredictionEventCard`（或抽出的原子卡）靠入参/派生 actions 渲染，避免分型 Widget。

**Non-Goals:**

- 不新增仅间隔草稿 / 可空 `lastAt` 种子。
- 不改推演算法与 VIP 可开槽位数规则。
- 不强制改未登录/未绑定假骨架（可保留）。
- 不恢复底栏 tip；不改 care-alert 昨日门闸。
- 不删除 `PredictionRecallOnboardingPanel` 全部源码亦可（先断入口；清理可作为同 change 任务或 follow-up）。

## Decisions

### D1：行构建 — 永远 catalog-complete

**选择**：`buildSmartPredictionRows`（或 provider 外包一层）对每个 `rootEvents` 根产出一行；`byKey` 无条目时 `lastAt`/`prediction`/`chartPoints` 为空，`forecastEnabled` 仍尊重 `disabledForecastIds`。

**理由**：空库与半记录同一模型；缺省页可删。

**备选**：仅空库特例塞全量 — 半记录仍少卡，弃用。

**排序**：有 `prediction` 的靠前（沿用现 rank）；无数据根按名称或目录序垫后。

### D2：量身定做 Dialog 退役

**选择**：热态不再根据 `emptyHistoryEligible` / gapRoots 自动 `showDialog`、软关再弹、空态 CTA 再开。相关 `predictionRecallDialogVisible` / session 启动 listen 拆除或恒 false。

**理由**：与卡内补齐统一心智。

**备选**：降级为可选顶栏入口 — 本 change 不做，避免双路径。

### D3：补充上一次 = 点卡

**选择**：CTA `onPressed` 与网格 `onCardTap` 同调 `handleEventGridTap(..., confirmDirectLeafBeforeAdd: true)`；视觉复用 `_HeartbeatAccentButton`（或等价心跳 FilledButton）。

**理由**：真历史进 timeline，与喂养一致；不写种子 lastAt。

### D4：无 lastAt 不展示间隔 CTA

**选择**：保持 `showIntervalRecall` 要求 `lastAt != null`；明确 `lastAt == null` MUST NOT 展示间隔钮。不存 interval-only。

**理由**：避免新契约；用户路径为先记一笔再补间隔。

### D5：关推演无补齐、无整卡加事件

**选择**：`forecastEnabled == false` 时不展示两种补齐 CTA，且 `onCardTap == null`（与补齐语义对齐）。开关仍可再开推演。

**理由**：与间隔 CTA 门闸一致；避免关推演仍诱导记账。

### D6：原子卡 chrome

**选择**：在 build 前派生 `CardFillAction?` / body kind（countdown | timing | sparse | chart…）；卡只渲染槽位。优先收敛 `_PredictionEventCard` 内分支，不必强行拆文件。

**理由**：满足「入参变化展示状态、避免每类型一次绘制」。

**备选**：新建公开 `PredictionEventCard` widget — 可做，非必须。

### D7：空态与 loading

**选择**：已绑定热态 `rows` 在 catalog 有根时不得为空列表（完备行）；仅 catalog 尚未有根且 range 仍 pending 时可保留「正在加载中」。不得再展示「回忆宝宝习惯」Gallery。

### D8：「上一次」进喂养编辑 Sheet（续写）

**选择**：热态卡展示「上一次…」且能从 home∪range **真历史**解析出该 root 最新 `HistoryRecord` 时，文案可点，调用与喂养页相同的 `showHomeHistoryEditSheet`；排除回忆种子伪记录。点按须独立命中、不触发整卡加事件。「暂无」不可点。本续写 **不**删除 OnboardingPanel / session provider 死代码。

**理由**：Dialog 退役后展示时刻语义为真喂养；复用同一 Sheet 避免双编辑器。

## Risks / Trade-offs

- **[Risk] 全量 root 卡变多** → 瀑布流既有；关推演半透明降低噪音。
- **[Risk] 只记一笔仍无 prediction** → 符合样本门闸；靠间隔 CTA 补种子，产品已接受。
- **[Risk] 残留 onboarding 代码死路径** → tasks 要求拆除入口；面板文件可后续删。
- **[Risk] 小组件 / tip 仍按有预测行** → 无 formal prediction 时 showcase FAB 等既有门闸保持。

## Migration Plan

1. 改行构建 → 空库即见全量卡。
2. 拆 Dialog / 空态入口 → 验证不再弹出。
3. 卡 CTA + 关推演整卡 → 手工路径验收。
4. 无需服务端迁移；本地若曾 finale dismissed 可忽略。

## Open Questions

- （无阻塞）未登录骨架是否也改为「灰态完备卡」——本 change 明确 Non-Goal，保持现状。
