## Context

`_onEventButtonTap` 在 `add` 下：`number` 已 sheet；`time`/`one` 仅当 `preferRecordSheet`（预测直点 `confirmDirectLeafBeforeAdd`）才 sheet，否则即时 now/开计时。喂养页与 picker 选叶后 `preferRecordSheet=false`，故深入后仍直落库。预测确认框在前序 change 已改为 sheet，但基线 v2.1.8 仍写「确认添加」；本变更统一为全局 sheet，并改写该 Requirement。

## Goals / Non-Goals

**Goals:**

- `add`：`time`/`one`/`number` 均先统一记录 sheet 再 `submitEventAdd`。
- 喂养格、多级 picker、预测直点/深入同一规则。
- 无「确认添加」闸；`time` 计时中仍 toast。

**Non-Goals:**

- 改 sheet 内字段/校验；改 supplement 流程；改 add HTTP 载荷映射表语义（sheet 确认后仍按 eventType 填）。
- 语音等非 `handleEventGridTap` 旁路（若存在另案扫）。

## Decisions

1. **单点收口**  
   在 `_onEventButtonTap` 的 `add` 分支对 `time`/`one` 与 `number` 同构：开 `showEventRecordCreateSheet`，取消即时提交。`preferRecordSheet` 可删或恒真后移除。

2. **调用方**  
   `confirmDirectLeafBeforeAdd` 可废弃（预测不必再传）；保留参数短期兼容亦可，但不得再驱动「仅预测才 sheet」。

3. **time 载荷**  
   Sheet 可返回进行中（end=0）或已结束；提交逻辑沿用现有 sheet→submit 分支。

## Risks / Trade-offs

- [喂养 time 多一步] → 产品已选，降低误触。  
- [语音旁路] → 本变更不扫则可能仍直写；可接受或后续补。

## Migration Plan

1. 改 `event_add_actions.dart`；清理无用 flag。  
2. 喂养/预测/多级各点 `time`/`one` 验 sheet。  
3. 回滚：恢复即时分支（不推荐）。

## Open Questions

- 无。
