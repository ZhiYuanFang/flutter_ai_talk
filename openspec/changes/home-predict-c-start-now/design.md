## Context

喂养页最近预测玻璃卡三态（A 远距 / B 窗内 / C 逾期补记）由 `home_next_predict_prompt.dart` 划分。C 态 CTA 经 `_onNextPredictGlassCta` → `handleEventGridTap`，当前传入：

- `forceRecordSheet: true`（即使 `time` 也不直开计时）
- `initialStartTime: prediction.nextAt`

统一创建 sheet（`event_record_sheet.dart`）在 `initialStartTime == null` 时已默认 `DateTime.now()`（分钟精度）。产品决策改为「只改初值」：保留强制 sheet，去掉 `nextAt` 预填。

## Goals / Non-Goals

**Goals:**

- C 点「补记」打开 sheet 时，开始时间控件初值 ≈ 当下。
- C 仍强制走统一创建 sheet（不直开计时）。
- A/B、文案、三态窗、叶选择器 / 闸门链路不变。

**Non-Goals:**

- 不改智能预测页「补充上一次」路径（本已无 `initialStartTime`）。
- 不改历史列表刷新 / 局部插入策略。
- 不改结束时间、用量记忆、备注折叠等 sheet 内部行为。
- 不引入新 API 或 provider。

## Decisions

1. **只清 `initialStartTime`，保留 `forceRecordSheet`**
   - 在 `_onNextPredictGlassCta` 对 C 传 `initialStartTime: null`（或根本不传），不再 `prediction.nextAt`。
   - `forceRecordSheet: isC` 保留。
   - 备选「完全对齐 A/B」（C 也允许 time 直开）已否决：逾期补记仍应进 sheet 让用户确认时刻。

2. **依赖 sheet 缺省种子，不在 CTA 显式传 `DateTime.now()`**
   - 与 A/B、其它 add 入口一致，避免多处造「当下」时钟。
   - 若日后需注入测试时钟，仍可只改 sheet 缺省。

3. **规格：MODIFIED 原 Requirement，场景「C always sheets with predicted start」改为当下初值**
   - 标题可 RENAMED 去掉「predicted start」，避免基线文案误导。

## Risks / Trade-offs

- [Risk] 用户本意按预测时刻补记，需多拨一次滚轮 → Mitigation：产品已明确偏好当下；预测时刻仍在卡上「预计」小字可见，可作参照。
- [Risk] 其它调用方若单独传 `nextAt` → Mitigation：本次仅改玻璃卡 C 入口；全仓检索 `initialStartTime:` 确认无第二处 C 预填。

## Migration Plan

- 纯客户端行为变更；无数据迁移。
- 回滚：恢复 `initialStartTime: isC ? prediction.nextAt : null` 与旧 Scenario。

## Open Questions

（无）
