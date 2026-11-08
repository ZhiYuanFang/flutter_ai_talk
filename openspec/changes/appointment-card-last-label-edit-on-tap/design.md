## Context

预约瀑布/compact 卡已用不限窗 `filter`（`ignoreTimeRange`）展示上次时间与 history remark，格式仍为 `上一次{事件名}：…`，与标题重复。点按编辑走 `latestRealHistoryRecordForRootFromSources(home∪range)`，不限窗有展示但近窗无 record 时不可点。用户选择：**点按时再 filter/get**，不在缓存里长期挂整条 `HistoryRecord`。

## Goals / Non-Goals

**Goals:**

- 预约卡上次行去掉「上一次{事件名}」前缀，保留 `{相对时间}[ · {remark}]`。
- 有可展示上次数据时行可点；点按 → 不限窗 filter（`limit=1`）→ 成功开 `showHomeHistoryEditSheet`。
- 明确预约例外于基线「仅缓存不开放编辑」。

**Non-Goals:**

- 不改非预约卡「上一次{名}」文案与仅近窗可编辑规则。
- 不把完整 record 写入 `AppointmentLastOccurrence` 常驻缓存。
- 不改预约 next 备注、倒计时改约、竖列表准确率 chrome。
- 不新增 Go API。

## Decisions

1. **短文案仅预约**  
   `formatPredictionLastOccurrenceLabel` 增加开关（如 `includeEventNamePrefix`），预约传 `false` → `{formatWidgetLastAt}[ · remark]`。非预约默认仍带「上一次{名}：」。

2. **点按再拉，不扩展示缓存**  
   预约 `onEditLastOccurrence`：single-flight 调既有 filter（根及子 `eventIds`、`limit=1`、`ignoreTimeRange`）；取首条真记录开编辑 sheet；空/失败 toast，不打开空 sheet。展示仍用现有 `appointmentLastCacheProvider`（at+remark）。

3. **可点条件**  
   预约：只要卡上展示了上次行（`displayLastAt != null`）即提供点按（可先显示可点样式，点后再拉）。不再要求近窗已有 `HistoryRecord`。非预约保持现逻辑。

4. **基线例外落点**  
   在 `event-interval-prediction` 的「仅缓存不开放编辑」场景上注明：非预约仍 MUST NOT；预约 MUST 走本 change 的点按再拉路径。

## Risks / Trade-offs

- [点按多一次网络] → 可接受；single-flight + 失败提示；成功路径与展示同源 filter。  
- [展示与编辑瞬间不一致] → 编辑以点按当次 filter 为准；可选成功后回写 last 缓存。  
- [无备注时只剩短时间串] → 靠位置与下划线表达「上次」；用户明确不要前缀。

## Migration Plan

纯客户端；无数据迁移。回滚恢复前缀与近窗-only 编辑即可。

## Open Questions

（无；点按再拉已由产品选定。）
