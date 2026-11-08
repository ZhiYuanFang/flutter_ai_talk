## 1. 契约模型（Attributes / ContentState）

- [x] 1.1 新增 `BabyLiveActivityAttributes`（固定字段 `activityId`/`deviceNo`；ContentState：`phase` + `items[]`；Item 含 `kind` 与 imminent/timing 展示字段；缺键兜底）
- [x] 1.2 从 Widget Bundle 移除对 `PredictImminentAttributes` / `PredictTimingAttributes` 的产品 ActivityConfiguration 注册；旧文件删除或改为仅被新行组件复用的私有视图
- [x] 1.3 更新 `LIVE_ACTIVITY.md`：单一 attributes-type、`items[]` 字段表、register 无 attributesKind/activityId、与 Go Refresh 对齐说明

## 2. 锁屏与灵动岛 UI

- [x] 2.1 抽出可复用 Imminent / Timing **行**视图（保持现有字号、expect −5pt、副行、已计时语义）
- [x] 2.2 统一锁屏：顶栏「胖宝」横向居中 + **产品主题主色**（非事件 accent）；其下按 `items` 纵向堆叠对应行
- [x] 2.3 Dynamic Island 仅绑定 `items.first`：imminent / timing 分支复用既有 Island 样式；空列表不依赖常驻 Island
- [x] 2.4 深链统一（或兼容映射）至预测页族；点击不本地 end

## 3. Token 监听与 register 单轨

- [x] 3.1 `PredictLiveActivityBridge`：仅观察统一 Attributes 的 Push-to-Start / activityUpdates；deliver / inbox 去重去掉 attributesKind/activityId
- [x] 3.2 `LiveActivityNativeRegister` 与 Dart `live_activity_registration_service`：POST body 仅 wxId/deviceKey/tokenKind/token；成功身份键收敛
- [x] 3.3 更新 `live_activity_registration_status` / 设置页：统一轨 PTS seen vs register ok；「已开通」不再要求双 attributesKind；诊断摘要与 `native_deliver_dart_miss` 文案跟单轨

## 4. 联调与收尾

- [ ] 4.1 与 Go `PUSH_LIVE_ACTIVITY_ENABLED` 联调：pending PUT、history CUD、MQ 到点 → 列表 upsert/end
- [ ] 4.2 真机核对：锁屏混排样式、胖宝居中主题色、Island 仅首条、register 无分槽字段
- [x] 4.3 清理过时双轨注释/文案；若新增 Debug 语义则按白名单三联改（通常可复用既有 liveActivity tag）
