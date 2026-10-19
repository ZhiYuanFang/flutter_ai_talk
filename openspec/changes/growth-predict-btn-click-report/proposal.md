## Why

成长轨迹工作台只在进页时上报 `page_growth_show`。「轨迹预测」和「重新预测」点下去没有点击事件，运维看不出用户有没有按开始，也分不出第一次预测和再来一次。

## What Changes

- 已登录用户点击「轨迹预测」时立即上报 `growth_predict_btn_click`。未开通、只弹开通窗的那次点击也报，description 标明未开通。
- 已登录用户点击「重新预测」（已有结果，或提问中重来）时立即上报 `growth_predict_restart_click`。
- 上报发生在点击当下，不等 `startPredict` 成功；失败沿用既有静默丢弃。
- 不改喂养记录分析「AI智能分析」、进页展示、预测接口本身。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `client-usage-report`：新增成长轨迹主按钮点击即报（开始与重新预测分开 `featureId`）。

## Impact

- 代码：`ClientUsageEvents` 增加两条常量；`growth_trajectory_screen.dart` 在「轨迹预测」「重新预测」的点击路径调用 `clientUsageReporterProvider.reportEvent`。
- API：仍是 `POST /device/app/api/client-usage/report`（`featureId` + `description`，≤128，禁 `|`）。同账号约 3 秒限流丢点可接受。
- 未归档的 `client-usage-habits-voice-xiaozhi` 也在给 `client-usage-report` 加需求。本变更用新的 Requirement 标题，不改它已有条目。
- 无 Android 原生改动，无新测试文件。
