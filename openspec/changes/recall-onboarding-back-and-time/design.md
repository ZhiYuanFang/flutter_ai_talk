## Context

量身定做浮卡在 `prediction_recall_onboarding_panel.dart`：PageView 禁手滑；底栏左「不记得了，跳过」、右「确认」；切页 `_resetCardDefaults()` 把上次时间打回此刻、间隔打回 180 分钟。思考盖层 `Positioned.fill` 播完约 400ms 自动下一张。上次时间走 `showHomeHistoryDatePickerSheet` 再 `showHomeHistoryTimePickerSheet` 两层。子事件用 Material `Chip` 只读展示。

未归档能力：`prediction-recall-onboarding`（跳过关推演）、`prediction-recall-card-ux`（子事件只读、思考自动跳）、`prediction-recall-pickers`（玻璃日期+时分）。基线 `v2.1.0` 尚未收录这些。

## Goals / Non-Goals

**Goals:**

- 按根缓存草稿；「上一步」只回上一张表单；第一张 / 思考中 / 收尾无上一步。
- 「跳过」与事件名同行、短文案；关推演语义不变；确认时重新 `setEnabled(true)`。
- 未改过默认快照则拦截确认并红字「请认真回忆事件」。
- 上次时间单层玻璃 Sheet：默认时分滚轮，左上角切换日期。
- 「该事件包含」：`EventLogo` + 名称，非 Chip/按钮。

**Non-Goals:**

- 不改添加事件表单的日期/时分双入口。
- 不改种子合成公式、真历史追上丢弃、空库才引导。
- 不把跳过做成撤销栈（队列仍在，仅关推演）。
- 不新建 `**/test/**`；不改 `app/android/**`。

## Decisions

1. **草稿按根 id 存，不随切页重置**  
   `Map<rootId, {lastAt, intervalMinutes}>`。某根首次进入才写入默认（此刻精确到分 + 180）。上一步 / 前进只恢复该 map，**不得**再 `_resetCardDefaults()` 覆盖已有草稿。  
   备选（弃）：PageView 每页独立 State — 邻页目前用占位值，且思考盖层与底栏在 PageView 外，按根 map 更简单。

2. **上一步只回表单**  
   `_goToPage(_pageIndex - 1)`，关思考盖层与打字机。不重播上一张思考。收尾与 `_showThinking` 时不渲染上一步。  
   备选（弃）：上一步先停思考盖层 — 产品已否。

3. **跳过在标题行**  
   `EventLogo` + `Expanded(事件名, overflow: ellipsis)` + `TextButton('跳过')`。思考盖层盖住整卡，播放中自然点不到跳过。语义仍 `_onSkip`。  
   确认路径补 `forecastDisabledIds.setEnabled(root.id, true)`，避免「先跳过 → 上一步 → 确认」后种子在、推演仍关。

4. **未改表单 = 相对首次默认快照**  
   另存每根 `baselineLastAt` / `baselineInterval`（仅首次进入写入）。`lastAt` 到分钟或 `intervalMinutes` 与 baseline 不同才算改过。打开选择器原样确定不算。拦截时不写种子、不播思考；红字贴在确认按钮上方（右列），色取 `ColorScheme.error`（经 Theme，禁止 `Colors.red` / 手写 hex）。改过后清提示。  
   备选（弃）：点第二次放行 — 仍可空过。

5. **单层时分/日期 Sheet**  
   新 API（如 `showHomeHistoryDateTimeToggleSheet`）包一层 `showGlassAdaptiveBottomSheet`：左上角展示当前模式值（默认 `HH:mm`，点一下切到日期文案如 `M月d日`，再点切回）；中部在现有时分双轮 / `CupertinoDatePickerMode.date` 间切换；底部「确定」合并为 `DateTime` 并 clamp ≤ now。未切换的那一半沿用进入 Sheet 时的值。量身定做 `_pickLastAt` 改调此 API；添加事件不迁。  
   备选（弃）：继续两层 Sheet — 产品已否。

6. **子事件展示**  
   `Wrap` 内每项 `EventLogo(kid, size: 20 左右)` + 名称；容器无 `InkWell` / `Chip` / `ChoiceChip`。无子则整区不展示。种子仍 `leafEventId = root.id`。

## Risks / Trade-offs

- [收尾无法回改最后一张] → 产品取舍；填错只能出引导后在预测开关处理。  
- [长事件名挤掉跳过] → 名称省略，跳过固定尾部不压缩。  
- [默认真是此刻+3 小时] → 须改一档才能确认；接受轻微摩擦。  
- [日期模式最大日=今天，时分可能超过现在] → 确定时 clamp，与现路径一致。

## Migration Plan

纯客户端 UI。回滚即恢复底栏跳过、两层时间 Sheet、Chip 叶子。无存储迁移（草稿仅会话内）。

## Open Questions

- （无；跳过短文案、上一步落表单、确认恢复推演、未改=相对首次快照均已定。）
