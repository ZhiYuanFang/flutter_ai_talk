## Context

`pickRecallIntervalMinutes` 现经通用 `showGlassSingleWheelPickerSheet` 返回 index，卡片 `_onPickIntervalRecall` 再 upsert 种子并 toast。量身定做 `PredictionRecallOnboardingPanel` 在写种子后用 ~42ms 打字机展示叙事，播完自动前进；per-card 无等价仪式。

产品要求：确认间隔后同 Sheet 内思考；按钮策略 **A**（跳过动画 → 关闭）。

## Goals / Non-Goals

**Goals:**

- 专用间隔 Sheet：`picking` / `thinking` 两态。
- 确认：校验间隔 → upsert 种子（可回调父级或 Sheet 内写）→ 切 thinking；标题「大概 {formatRecallIntervalMinutes} 一次」。
- 思考文案：对齐量身定做叙事风格 + 加粗自适应说明行。
- 按钮 A：未播完「跳过动画」；播完「关闭」pop。

**Non-Goals:**

- 不改通用玻璃单滚轮 API。
- 不删 OnboardingPanel 文件（可抽共用 typewriter helper）。
- 不引入仅间隔草稿；不改推演算法。

## Decisions

### D1：专用 Sheet，不改通用 picker

**选择**：`pickRecallIntervalMinutes` 改为自建 glass bottom sheet body（或 `showGlassAdaptiveBottomSheet` + 私有 Stateful body）。

**理由**：思考态与确认回调耦合 recall 种子，通用 picker 无此语义。

### D2：种子在切 thinking 前写入

**选择**：点确定即 upsert（与 onboarding `_onConfirm` 同序）；关闭不撤销。

**理由**：思考期间卡片可出现 countdown；与「认真记下了」心智一致。

**备选**：关闭才写 — 关中途无种子，弃用。

### D3：按钮策略 A

**选择**：thinking 中 `跳过动画` 拉满可见字；满文后主按钮改 `关闭` → `Navigator.pop`（返回已选分钟或 true，供父级 toast 可选）。

**理由**：用户已确认 A。

### D4：文案

**选择**：主段示意：

`好的，我记下了「{eventName}」大概每 {intervalLabel} 一次。正在按你的节奏合成推演样本，为「{eventName}」量身定做智能预测…`

加粗另起行：

`随着后续的喂养节奏，我会自动修改预测时间；当前只是为了适应还没有足够喂养信息的时候。`

打字机可整段含加粗行，或主段打完再展示加粗行；默认 **主段打完后展示加粗行**（结果感更强）。

### D5：打字机复用

**选择**：抽出轻量 helper/widget（全文、visibleLen、42ms Timer、skip）；onboarding 可后续迁入，本 change 至少 per-card 使用；不必一次大拆 Panel。

### D6：思考完毕状态行与重选（续写）

**选择**：`_thinkingComplete` 后状态行改为「思考完毕 · 下一次{eventName}：{formatWidgetLastAt(lastAt+interval, now)}发生」；点按同层回 picking（滚轮初值为刚提交分钟）。未完成时保持「正在思考…」。

**理由**：给用户即时「下次何时」反馈，并允许改间隔而不关 Sheet。

## Risks / Trade-offs

- **[Risk] Sheet 内写种子需 Ref/回调** → body 用 ConsumerStatefulWidget 或由 `pickRecallIntervalMinutes` 传入 `onConfirmed(minutes)` Future。
- **[Risk] 遮罩滑关中途** → 种子可能已写（可接受）；thinking 未完也允许 barrier dismiss 时 pop。

## Migration Plan

无数据迁移。旧 Dialog 种子路径不变。

## Open Questions

- （无）按钮 A、加粗行文案已定。
