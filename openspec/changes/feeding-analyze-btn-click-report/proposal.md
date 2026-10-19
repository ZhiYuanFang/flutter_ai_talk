## Why

喂养记录分析进页只上报 `page_feeding_analysis_show`。正文下方的「AI智能分析」点下去没有点击事件，看不出用户有没有发起分析。

## What Changes

- 已登录用户点击「AI智能分析」时立即上报 `feeding_analyze_btn_click`，description 为「点击AI智能分析」。
- 分析进行中再点（由现有逻辑提示且不发第二次生成）也上报这一次点击。
- 上报不等 `refreshDailyManual` 成功，失败静默、不挡分析。
- 不上报成长轨迹的 `growth_predict_*`。正文「喂养记录已达标，点击开通智能分析」不是这颗按钮，不报。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `client-usage-report`：新增喂养记录分析「AI智能分析」按钮点击即报。

## Impact

- 代码：`ClientUsageEvents` 增加常量；`feeding_analysis_screen.dart` 的 `_onTapAnalyze` 开头异步 `reportEvent`。
- API：仍是 `POST /device/app/api/client-usage/report`。同账号约 3 秒限流丢点可接受。
- 未归档的 `growth-predict-btn-click-report` 要求这颗按钮不得使用成长轨迹那两个 `featureId`。本变更用新 id，两条需求可以同时成立。
- 无 Android 原生改动，无新测试文件。
