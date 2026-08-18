## Context

主壳现为三页（喂养 | 预测 | UCG）；历史编辑有媒体时展示「同步广场」并可发帖；预测页「值得留意」常驻（含 loading/空/失败 VIP CTA/冷态假卡）；底栏 tip 跑马灯；`/vip/purchase` 可从留意失败态进入。产品要求临时关掉广场入口与同步副作用、VIP 购买可达性，并瘦身预测 chrome。仓库已有同类闸门先例：`kUcgTreasureEnabled = false`。

对照基线 `openspec/specs/v2.1.0.md` 与未归档 change（`prediction-as-home-hub`、`llm-care-alert-daily`、`care-alert-fail-vip-cta`、`prediction-tip-bottom-marquee`、`prediction-demo-skeleton-and-recall-dialog`）。

## Goals / Non-Goals

**Goals:**

- 用户无法进入 UCG 主壳页；无法通过编辑事件同步发帖/改帖/删帖。
- 预测页仅在有真实留意条目时展示「值得留意」；无底 tip 跑马灯。
- VIP 购买页与开通 CTA 不可达；Auth 滑动大卡改文案后保留。
- 用可翻转常量/flag 实现，便于下版恢复。

**Non-Goals:**

- 删除 `app/lib/ucg/**`、支付 SDK、care-alert HTTP 客户端。
- 改桌面小组件 tip 推送逻辑。
- 改 care-alert daily API / 后端契约。
- 关闭陪伴树洞、历史媒体本地选图（相册 UI 可继续复用 UCG 选择器代码路径）。

## Decisions

### D1：统一 pause 常量族（仿 `kUcgTreasureEnabled`）

- 新增（或集中）编译期/库内 `const` 闸门，例如：
  - `kUcgHomePagerEnabled = false` — 主壳是否含 UCG 页
  - `kHistorySquareSyncEnabled = false` — 同步广场 UI + UCG 副作用
  - `kVipPurchaseEnabled = false` — 购买路由与 CTA
- **为何不用远端配置**：本次是发版级临时关停，常量零依赖、与宝藏开关一致；远端开关另开 change。
- **备选**：单一 `kProductSurfacePause` 总开关 —— 也可，但分项更易单独翻回 tip/留意策略（留意显隐不走 flag，直接改 UI 规则为产品定稿）。

### D2：主壳两页，索引语义保持

```
暂停前:  feeding=0 | prediction=1 | ucg=2
暂停后:  feeding=0 | prediction=1     （count=2）
```

- `HomePagerPage.ucg` 常量可保留但 **MUST NOT** 作为合法 `itemCount` 目标；`requestPage(ucg)` 应 no-op 或落到 prediction。
- 懒挂载 `_ucgEverMounted` 路径在闸门关闭时永不触发。
- Android 返回：仅喂养 → 预测；去掉「从 UCG 回预测」分支（或保留死代码但不可达）。

### D3：同步广场 — UI + 副作用双掐

- Sheet：`if (kHistorySquareSyncEnabled && _media.isNotEmpty)` 才画开关；暂停期恒不展示。
- `_effectiveSyncToSquare` 在暂停期恒 `false`（忽略本地偏好 ON）。
- `runHistoryEventMediaSideEffects(..., syncToSquare: false)` → 仅本地媒体缓存；**不得** create/update/delete post。
- 曾有 `postId` 的记录：暂停期保存 **不得** 因「关同步」触发 `deletePost`（因用户无法操作开关；强制 false 且不跑删帖分支，或显式跳过删帖）。

### D4：值得留意 — 仅非空成功态

```
ready && !failed && !loading && items.isNotEmpty → 跑马灯卡片
其余（含冷态假卡、loading、空、失败、VIP CTA）→ shrink
```

- `_CareAlertDemoHealthyPanel` 不挂载。
- Auth 冷态仍用 `_PredictionSwipeGuideCard`，文案去掉广场。
- `ensureLoaded` 门闸可保留（有真历史仍可拉），失败只是不展示卡，不弹开通。

### D5：VIP 路由不可达

- `kVipPurchaseEnabled == false` 时：路由 redirect 到 `/home`（或 `context.pop` 等价）；所有 `push('/vip/purchase')` 调用点移除或 early-return。
- 详情 `showVipCta` 已 false，保持；删除/停用预测页失败态开通分支。

### D6：底 tip 跑马灯删除

- 移除 `showTip` 挂载与 `_BottomTipMarquee` 类；可停止 watch `widgetTipCardTextProvider`（若无其它用途）。
- 不改 `scheduleHomeWidgetSync` / 小组件写 tip。

### D7：引导大卡文案

- 保留动画大卡；副文案由「左滑进广场 · 右滑去喂养」改为仅喂养导向（如「右滑去喂养记账」/「左右滑动，看看别处」可保留主句，副句去掉广场）。

## Risks / Trade-offs

- [深链/旧 `requestPage(2)`] → 统一落到 prediction 或 ignore，避免空白页。
- [已同步帖子无法在 App 内取消同步] → 暂停期可接受；翻回后恢复开关。
- [VIP 用户 care-alert 失败时无刷新入口] → 有意为之（整卡隐藏）；翻回或另开调试入口。
- [规格与多份未归档 change 冲突] → 本 change delta 明确 REMOVED/MODIFIED；apply 以本 change 为准。

## Migration Plan

1. 落地 flag 默认 `false` / 留意与 tip 按新规则改 UI。
2. 发版验收：两页滑、加图无同步、无底 tip、无空/失败留意卡、购买深链不可达、大卡无广场文案。
3. 回滚：flag 改 `true` + 恢复留意常驻/失败 CTA/底 tip（或 revert 本 change）。

## Open Questions

- （无）探索已定：大卡改文案留下；小组件 tip 默认不动。
