## Context

成长轨迹工作台主按钮在 `growth_trajectory_screen.dart`。未开通时文案是「轨迹预测」，点击只打开开通窗。已开通且还没有结果时，同一文案走 `_onPredict(restart: false)` → `startPredict`。已有结果，或提问阶段，文案是「重新预测」，走 `_onPredict(restart: true)`。思考流和加载历史不放这颗按钮。

上报通道已有：`ClientUsageReporter.reportEvent`，已登录才打 `POST /device/app/api/client-usage/report`，失败只打 `AppDebugLog.clientUsage`，用户无感知。进页已有 `page_growth_show`。小智漏斗是「点击即报、不等成功」。

## Goals / Non-Goals

**Goals:**

- 点「轨迹预测」立即上报 `growth_predict_btn_click`。
- 点「重新预测」立即上报 `growth_predict_restart_click`。
- 未开通那次点击用同一 `featureId`，description 写成「点击轨迹预测（未开通）」。
- 上报不阻塞 `startPredict` 或开通窗。

**Non-Goals:**

- 不报喂养「AI智能分析」。
- 不改 `page_growth_show`、不改预测接口、不等分析成功才报。
- 不对抗服务端约 3 秒限流。

## Decisions

### D1 两个 featureId

开始与重来分开计数。未开通与真正开始共用 `growth_predict_btn_click`，用 description 区分，避免再造第三个 id。常量放在 `ClientUsageEvents`。

### D2 挂在点击路径，不等结果

已开通：在 `_onPredict` 开头 `unawaited(reportEvent)`，再 `await startPredict`。未开通：在打开开通窗的 `onTap` 里同样 `unawaited` 上报。失败沿用 repository 静默丢弃。未登录由 reporter 直接返回，不打接口。

### D3 与习惯埋点变更互不改写

`client-usage-habits-voice-xiaozhi` 已为 `client-usage-report` 新增语音、小智、通知等 Requirement。本变更只 ADDED 一条新标题，不改那些正文。

## Risks / Trade-offs

- [3 秒内连点两次，第二次被服务端丢掉] → 与现有点击埋点相同，接受丢点。
- [未开通与真正开始共用一个 featureId] → 看 description 才能拆开；聚合计数会把意愿和实点加在一起。需要硬拆时再加 id。

## Migration Plan

仅客户端多一次上报。回退即去掉这两次 `reportEvent`。

## Open Questions

（无）
