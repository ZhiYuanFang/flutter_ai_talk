## Context

当前落库飞入由 `HomeScreen` 独享：订阅 History `watchLatest`，仅在 `isNew || awaitingWsFly` 时启动 `HomeEventRecordFlyOverlay`，落点死绑 `HomeHistoryScroll` 的 `recordId` logo。默认着陆页为智能预测，飞入叠在喂养页 Stack 内，用户看不见。基线 `home-event-record-fly` 明确禁止普通 update / 停表 / 删除飞入。

预测页与喂养页同属 `/home` PageView（KeepAlive）；需在**当前可见页**用**同一套动画**、**不同 LandingTarget** 响应任意历史 WS 变动。

## Goals / Non-Goals

**Goals:**

- 一套飞入 Overlay（中心 pop → 落锚）；喂养 / 预测只提供 `prepare` + `measure`。
- History WS create / update / delete 均尝试飞；接受连播（最新 session 打断上一段）。
- 仅 `HomePagerPage.feeding` / `prediction` 可见时飞；其它页不飞。
- 喂养落点：历史行 logo；预测落点：对应 root 预测卡**当前展示** logo 槽（叶子/根换皮不换槽）。
- 测不到锚点 → **不飞**（删除自然不飞）。
- 预测卡离屏 → 先滚入可视再测锚再飞。

**Non-Goals:**

- 不改变 History WS 协议、upsert/remove 数据语义、按钮 HTTP 乐观插入。
- 不在 UCG 页播飞入；不要求离屏页预播。
- 不做同 id 冷却 / debounce（产品接受连播）。
- 不新建测试文件（除非用户另行要求）。

## Decisions

### 1. 共享 Overlay + LandingTarget，不复制动画

- **选择**：泛化现有 `HomeEventRecordFlyOverlay`（或抽 `HistoryEventFlyOverlay`），注入 `LandingTarget`：`Future<bool> prepare()`、`Offset? measureGlobalCenter()`、可选 `bool get isVisible`。
- **备选**：预测页复制一份 Overlay — 否决，违反「一套动画逻辑」。
- **备选**：壳层单一 Overlay + 全局坐标总线 — 可行但壳变胖；首版由可见页各自挂同一 Widget、读共享 FlyRequest 即可。

### 2. 触发编排与可见页门闸

- **选择**：在 WS payload 处理路径（可仍由 Home KeepAlive 订户调用共享函数）应用历史变更后，若当前 `pageIndex` 为 feeding/prediction，则 `requestFly(session++, event?, landingKey)`；页面 listen 后挂 Overlay。
- **落地 key**：喂养用 `recordId`；预测用 record 的 root `eventId`（与预测行 `row.eventId` 对齐）。delete 后若测不到锚点则跳过飞入，无需预缓存坐标。
- **移除门槛**：`_awaitingWsFlyIds` / `isNew` 不再作为是否飞的条件；HTTP 成功路径仍可不本地起飞（等 WS），与「WS 全变动飞」兼容。

### 3. 无锚点不飞；预测离屏先滚

- **选择**：`prepare` 失败或 `measure` 为 null → 立即 `onComplete` / 不启动 controller，禁止耗尽 retry 后落中心。
- 喂养 `prepare`：沿用滚底 + 等 record logo 可见。
- 预测 `prepare`：对卡 logo key `Scrollable.ensureVisible`（或列表/瀑布流等价滚入），可见后再 measure。

### 4. 预测卡锚点挂在「当前展示 logo」槽位

- **选择**：`_PredictionEventCard` 上单一 `GlobalKey` 包住标题旁 / 英雄位中**当前实际渲染的**那块 `EventLogo`（计时叶子与普通根图共用同一 key 槽）。飞入图标可用 `lookupEventForRecord`（叶子优先）以匹配视觉，落点仍是该槽中心。

## Risks / Trade-offs

- [连播打断 / 滚屏耗时] → 以 session 取消旧 Overlay；新请求 `prepare` 期间旧动画已卸。
- [瀑布流卡尚未 build，ensureVisible 失败] → 测不到则不飞；可有限次 endOfFrame 重试 prepare，仍失败则放弃。
- [Home 离屏仍 setFlyAnimationFrozen] → 仅可见喂养页在飞入期间冻结列表重排；预测页飞入时若无需冻历史列表可不设 frozen，或 frozen 仅 feeding Landing 使用。
- [BREAKING 相对旧「update 不飞」] → 产品已接受；收版更新基线文案。

## Migration Plan

- 纯客户端行为变更；无服务端迁移。
- 回滚：恢复 `isNew|awaiting` 门槛与仅喂养 Overlay 即可。

## Open Questions

- 无（产品边界已在 explore 对齐）。
