# Design: 历史编辑 Sheet 支持修改日期

## Context

- 历史编辑入口：`showHomeHistoryEditSheet`（`home_history_edit_sheet.dart`），按 `eventNumber` 展示开始/结束时间与用量等字段。
- 时间交互：`HomeHistoryTimeField` + `showHomeHistoryTimePickerSheet`（`home_history_time_wheel.dart`）；时分滚轮在确认时用 `anchorDate` 拼合日历日，编辑页当前将 `anchorDate` 锚定在记录原始日期，等效于不可改日。
- 新建 number 事件使用独立的 `showHomeNumberEventSheet`，本次**不在范围**。
- 列表日期文案已有 `formatHistoryDaySectionLabel`；宝宝资料经 `settingsBabyProvider` 提供 `birthDate`。

## Goals / Non-Goals

**Goals:**

- 编辑 Sheet 内可对开始/结束时刻分别修改**自然日**与**时分**。
- 日期默认文字展示，点击后底部 Sheet + Cupertino 日期滚轮；与时间字段并排。
- 日期展示与列表一致（今天/昨天/…）；picker 范围：宝宝生日～今天。
- 保存、脏检测、`结束不能早于开始` 等现有校验继续基于完整 `DateTime` 工作。

**Non-Goals:**

- 统一新建与编辑 Sheet；改动 `home_screen` 的 time/one/number 创建流程。
- 修改 `HomeNumberEventSheet` 的「锁今天」行为。
- 限制「今天」内时分不得超过当前时刻（允许补录当天较早时刻）。

## Decisions

### 1. 组件拆分：`HomeHistoryDateTimeRow`

在同一 label（如「开始时间」）下用 `Row` 并排：

- 左：`HomeHistoryDateField` → `showHomeHistoryDatePickerSheet`
- 右：`HomeHistoryTimeField`（保留现有 API）

日期变更：`DateTime(d.y, d.m, d.d, value.hour, value.minute)`  
时间变更：`DateTime(value.y, value.m, value.d, t.hour, t.minute)`  
时间滚轮的 `anchorDate` 传**当前编辑值**的日历日（非记录原始 anchor）。

### 2. 日期滚轮实现

使用 `CupertinoDatePicker(mode: date)`，包在 `showGlassAdaptiveBottomSheet` 内，视觉 token 对齐现有时分 Sheet（`historyEditGlassTextColor` 等）。

`minimumDate` = `DateTime(baby.birthDate.year, month, day)`（来自 `settingsBabyProvider`）；`maximumDate` = 今天自然日。宝宝资料未就绪时可短暂禁用日期格，或 fallback 至 `DateTime(2000, 1, 1)`（与宝宝资料编辑一致）。

### 3. 文案复用

展示用 `formatHistoryDaySectionLabel(value, DateTime.now())`，与主页历史日期分块行规则一致。

### 4. 历史脏数据

若记录日期早于宝宝生日：展示原值；用户未改日期则保存不变；打开 picker 时 `initialDateTime` clamp 到 `minimumDate`。

### 5. 不重构 `HomeHistoryTimeField` 对外契约

`HomeNumberEventSheet` 仍传 `anchorDate: _todayAnchor`；仅编辑 Sheet 改为动态日历日。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 宝宝资料异步加载导致 picker 范围暂不可用 | 日期格 disabled 或 fallback min；保存路径已有 `settingsBabyProvider` 读取 |
| 跨天计时 `n==0` 结束早于开始 | 改开始日仅同步结束日历日；改开始时分且晚于结束时同步结束时刻；保存仍校验 |
| 与基线「不可改日期」冲突 | OpenSpec delta REMOVED + ADDED 明确取代 |

## Migration Plan

纯客户端 UI 变更；无数据迁移。发版后即生效；回滚仅需还原编辑 Sheet 与新增组件。

## Open Questions

（无——范围已在 explore 阶段确认：仅编辑 Sheet，不统一新建。）
