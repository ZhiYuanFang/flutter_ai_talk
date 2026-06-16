# Proposal: 历史编辑 Sheet 支持修改日期

## Why

用户在补录或纠正喂养记录时，常需要把事件改到「昨天」或更早的日期；现网历史编辑 Sheet 仅能通过滚轮改时分，日历日锁定在记录原值，无法跨天修正。该能力仅影响「点击历史行」的编辑路径，不改变新建事件的交互。

## What Changes

- 在历史编辑 Sheet 中，为可编辑的开始/结束时刻增加**日期**字段：默认以文字展示（`今天` / `昨天` / `M月D日` / `Y年M月D日`，与列表日期分块规则一致）。
- 点击日期文字后，从底部弹出玻璃态 Sheet，使用 **Cupertino 日期滚轮**选择自然日；可选范围为**宝宝生日（自然日）至今天（自然日）**。
- 同一标签下**日期与时间并排**展示；点击时间仍使用现有时分滚轮 Sheet。
- 保存逻辑不变：仍提交 Unix 秒级 `startTime` / `endTime`；`eventNumber` 为 0/1/>1 的字段展示与网关语义保持不变。
- **不**改动 `showHomeNumberEventSheet`、time/one 秒开创建流程，**不**统一新建与编辑 Sheet。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `home-history-edit-sheet`：撤销「不可改日期」限制；新增日期滚轮、并排日期+时间展示与相关场景。

## Impact

- 新增或扩展 `app/lib/ui/home_history_time_wheel.dart`（或邻接文件）：`HomeHistoryDateField`、`showHomeHistoryDatePickerSheet`、`HomeHistoryDateTimeRow`。
- 修改 `app/lib/ui/home_history_edit_sheet.dart`：接入日期+时间行，从 `settingsBabyProvider` 读取生日作为 picker 下限。
- 复用 `app/lib/data/history_line_format.dart` 的 `formatHistoryDaySectionLabel`。
- 不新增外部依赖；不修改 `home_screen` 新建路径与 `home_number_event_sheet.dart`。
