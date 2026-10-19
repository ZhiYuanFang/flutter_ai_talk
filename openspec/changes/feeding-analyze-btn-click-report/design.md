## Context

喂养记录分析工作台在资格通过且可用时，正文下方放「AI智能分析」（`_FeedingBodyCta`）。点击进 `_onTapAnalyze`，再调 `refreshDailyManual`。分析进行中按钮仍在，再点由 provider 提示且不发第二次生成。未开通时正文是另一句「喂养记录已达标，点击开通智能分析」，打开开通窗，不是这颗按钮。

上报通道与成长轨迹点击相同：`ClientUsageReporter`，已登录才打接口，失败只写 `AppDebugLog.clientUsage`。

## Goals / Non-Goals

**Goals:**

- 每次点击「AI智能分析」立即上报 `feeding_analyze_btn_click`。
- 进行中的再点也报。
- 上报不挡住分析，也不等接口成功。

**Non-Goals:**

- 不报未开通正文那一句、不报条目点击进详情。
- 不使用 `growth_predict_btn_click` / `growth_predict_restart_click`。
- 不改 `page_feeding_analysis_show` 与分析接口。

## Decisions

### D1 一个 featureId

这颗按钮没有「重新分析」另一套文案。开始和进行中再点都是 `feeding_analyze_btn_click`，description 固定「点击AI智能分析」。进行中被拒的那次仍然是用户点了按钮，所以也报。

### D2 挂在 `_onTapAnalyze` 开头

`unawaited(reportEvent)` 之后再 `await refreshDailyManual`。未登录由 reporter 直接返回。

### D3 与成长轨迹点击需求并存

`growth-predict-btn-click-report` 禁止这颗按钮上报成长轨迹的两个 id。本变更只 ADDED 新 Requirement，不改那条正文。

## Risks / Trade-offs

- [进行中连点会多一条点击，但没有第二次生成] → 这是点击意愿，不是成功次数。3 秒限流可能丢掉紧接着的下一次。
- [未开通正文不报] → 开通意愿仍只靠进页。若要和「轨迹预测（未开通）」对齐，另开一条。

## Migration Plan

仅客户端多一次上报。回退即去掉这次 `reportEvent`。

## Open Questions

（无）
