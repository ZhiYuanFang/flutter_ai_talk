## 1. 拆除 update ack

- [x] 1.1 从 `BabyLiveActivityAttributes.ContentState` 移除 `ack` 字段与编解码
- [x] 1.2 从 `PredictLiveActivityBridge` 移除仅为 ack 的 `contentUpdates` / `handleContentAck` 路径（保留 push token 观察）
- [x] 1.3 从 `LiveActivityNativeRegister`（或并列 helper）删除 ack POST、进程内 ack 去重
- [x] 1.4 更新 `LIVE_ACTIVITY.md`：删除 ack 契约，改为 clear 契约说明

## 2. 本机 LA 查询桥

- [x] 2.1 原生提供「是否存在 `BabyLiveActivityAttributes` 活动中 LA」查询（供 MethodChannel）
- [x] 2.2 Dart 封装该查询；非 iOS 直接视为无 LA / 跳过（本变更不实现 Android LA）

## 3. 鉴权 clear

- [x] 3.1 Dart API：`POST /app/api/push/live-activity/activity/clear`，Bearer + `deviceKey`
- [x] 3.2 登录态冷启动就绪与 `resumed` 触发：无本机 LA → clear；有 LA → 跳过；未登录跳过
- [x] 3.3 登录成功后补跑一次检查
- [x] 3.4 落实副作用 HTTP：single-flight、短窗合并、失败 `AppDebugLog`/`ApiHttpLog`（新 tag 须三联改）

## 4. 联调与验收

- [x] 4.1 与 Go `live-activity-clear-activity-on-app-open` 同发：划掉 → 打开 App → clear → 下次推送 start
- [x] 4.2 确认不再请求 `…/live-activity/ack`；有 LA 时打开 App 不误 clear
- [x] 4.3 若 `live-activity-update-ack` 未合入：停止该方向实现；若已合入：确认本变更已回滚其 ack diff
