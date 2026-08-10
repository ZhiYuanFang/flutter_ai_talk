## Context

当前智能预测冷态要么空文案，要么全屏量身定做（`PredictionRecallOnboardingPanel` 占主 Column 并隐藏留意/三小时/tip）。`prediction-as-home-hub` 规定头像进 `/settings/baby`。Care-alert 在预测页可见时由 shell `ensureLoaded`，与是否有真历史无关。产品改为：冷态用骨架演示功能；已绑定无历史用 Dialog 采样；头像进设置总页；无真历史不打留意接口但展示固定健康文案。

## Goals / Non-Goals

**Goals:**

- 未登录 / 未绑定 / 已绑定无真历史：主列表为全量 `parentId == null` 根事件骨架，`nextAt` 落在 `(now, now+3h]`。
- 骨架随机：同一秒级 wall-clock tick 内偏移稳定；仅整页 remount 重抽。
- 冷态展示固定健康「值得留意」；禁止 care-alert HTTP。
- 已绑定 + range 空 + 未 finale：Dialog + 禁滑 PageView 采样；底层骨架；遮罩软关；非头像点击再弹；走完永久关。
- 头像全局 → `/settings`。

**Non-Goals:**

- 不改种子策略 C、真历史上后丢弃、策略 B 门闸语义。
- 不新建 `**/test/**`。
- 不改喂养页绑定空态；不在此 change 做 VIP/真留意文案运营配置后台。
- 骨架卡不要求走「点卡记账」真提交流（可禁用或点后引导登录/绑定，实现选简单路径：冷态卡可不触发 add）。

## Decisions

### D1：冷态判定与行数据源

- **判定** `useDemoSkeleton`：`!loggedIn` **或** 无可用 `deviceNo` **或**（已登录且绑定且 `predictionRecallEmptyHistoryEligible`：range ready && items empty）。
- **行**：`buildPredictionDemoSkeletonRows(catalog, nowTickSecond)` → `List<SmartPredictionRow>`，覆盖 `rootEvents(catalog)`；不写 history、不写 seed。
- **展示**：`SmartPredictionScreen` 在 `useDemoSkeleton` 时用骨架行替换 `smartPredictionRowsProvider` 结果（真历史非空时仍用真行）。

备选：改 provider 内部合并 — 否决，避免污染真预测合并路径。

### D2：秒级稳定随机

- 用 `now` 的 **Unix 秒**（或 `DateTime` 截断到秒）作为 RNG seed 的一部分，配合根 `eventId` hash，生成 `[1s, 3h]` 内偏移。
- Provider/build 在同一秒内多次调用 → 同一 `nextAt`；跨秒的倒计时 **只减显示**，不重抽偏移（偏移绑在「本页 session 的 seedEpochSecond」或「根 id + pageMountId」）。
- **整页重建重抽**：`SmartPredictionScreen`（或壳）在 `initState`/`State` 生命周期生成 `pageMountNonce`（或记录 `mountEpochMs`）；RNG = `hash(pageMountNonce, rootId)`，与秒无关但 mount 变则变。用户要求「每秒 tick 内固定、仅整页重建重抽」→ 采用 **mountNonce 固定偏移**；秒级 tick 仅驱动倒计时 UI 刷新，不改 `nextAt`。若仅用「当前秒」做 seed，每秒都会重抽，与「仅整页重建重抽」矛盾，故 **以 mountNonce 为准**，秒 tick 只刷新相对文案。

### D3：假留意与 ensure 门闸

- UI：冷态渲染占位值得留意（固定文案，如「宝宝很健康」类），无跑马灯条目、无详情跳转副作用（或禁用点进详情）。
- Shell：`_ensureCareAlertOnPredictionVisible` **仅当** 已登录、有 deviceNo、且 range 真历史非空时调用 `ensureLoaded`。
- 有真历史后恢复现网留意卡片逻辑。

### D4：量身定做 Dialog

- 触发条件不变（策略 B + 会话 flags）；呈现改为 `showDialog` / 页内 `Dialog`+barrier，内容复用 PageView 面板。
- `barrierDismissible: true`；软关只清「dialog 可见」，**不清** finale dismissed。
- 软关后：预测页主体（除头像）包一层 `Listener`/`GestureDetector`，点击再 `show` Dialog；头像 hit test 优先，进 `/settings`。
- Finale / 收尾完成 → `predictionRecallFinaleDismissedProvider = true`，永久不再自动/再弹（直至策略允许的空库再入，若现有 listen 会复位 dismissed，可保留「再次变空库可再引导」或按现 empty-only 行为）。
- Dialog 打开时底层骨架+假留意仍可见（透过遮罩）；**撤销** empty-only「引导时隐藏三块 chrome」——改为 Dialog 遮罩层，底下冷态 chrome 保留。

### D5：头像 → `/settings`

- `openBabyEditor` 改名为设置入口：已登录 `context.push('/settings')`；未登录仍 `/login`（或与设置总页同一门闸）。
- 覆盖 `prediction-as-home-hub` 头像进宝宝编辑的要求。

### D6：无子根一钮

- 量身定做卡片：叶子选择若仅有根自身（无子），只显示根一钮（沿用 onboarding 既有方向，实现时确认 `_leafChoices`）。

## Risks / Trade-offs

- [软关后再弹热区过宽] → 布局切换/陪伴/假留意都会再开 Dialog；按产品字面接受，头像除外。
- [骨架卡可点记账] → 冷态禁用 add 或点后引导登录/绑定，避免脏数据。
- [Dialog 与 PageView 状态] → 软关再开应恢复队列进度（State 上提 provider/notifier），避免从第一卡重来；设计采用会话级 pageIndex/queue 状态。
- [假留意与真空态文案混淆] → 冷态固定文案与「真棒」真空态区分文案或同一正向语气但路径不同（无 HTTP）。

## Migration Plan

- 纯客户端；无后端迁移。
- 回滚：恢复内嵌 Panel、头像 `/settings/baby`、可见即 ensure。

## Open Questions

- （无）秒级/整页随机已按 D2 收口为 mountNonce。
