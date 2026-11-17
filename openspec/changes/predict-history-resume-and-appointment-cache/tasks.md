## 1. 统一池滚动 24h API

- [x] 1.1 在 `home_history_notifier`（或统一池入口）新增 `refreshRollingWindow`：`start=now−24h`、`end=now` 一次 filter，按 id 合并，保留 `startTime < start` 的本地行
- [x] 1.2 确认冷启 `seedSevenDay` / `bootstrap` 仍走近 7 日，且 resume / 下拉不再调用 force 7 日种子

## 2. Resume 与冷启去重

- [x] 2.1 主壳已登录 resume bundle：历史改为调用滚动 24h；保留 UCG unread；去掉预测 range force / care-alert full ensure（若代码仍残留）
- [x] 2.2 ColdStart 短窗去重：Gateway 完成 7 日种子后，HomeScreen 不再二次完整 ColdStart 历史（可仅补 catalog 空重试），或成功后 60s 内跳过历史种子
- [x] 2.3 确认 WS ready 不早退跳过 resume HTTP；短窗 resume single-flight / 去重仍有效

## 3. 预测卡上一次跟池

- [x] 3.1 调整 `smart_prediction_rows`（及 lastAt 解析）：`lastAt = 池内同桶最新 ?? tip`；去掉 latest-by-event 展示优先
- [x] 3.2 非预约同桶规则（有 `prediction.eventId` / 无 pred 用根）与点按编辑同桶保持不变
- [x] 3.3 （可选）post-mutation 管线停止或降级 latest-by-event 调用；不得再驱动卡面覆盖池内更新

## 4. 预约 next/last 磁盘缓存与静默刷新

- [x] 4.1 新增 prefs 持久化（按 `deviceNo`）：appointment next（nextAt+remark）、appointment last（at+remark）
- [x] 4.2 Provider/ensure：启动与进预测先 hydrate 再展示；`refreshSilent` 在内存已知时仍打网络（single-flight）；成功写回盘
- [x] 4.3 预约卡「上一次」展示只认 appointment last 缓存（不再池优先）；静默不限窗 filter 写回；MUST NOT 用 nextAt 当 last
- [x] 4.4 `wipe_account_local_state` / 切号 clearLocal：清除预约 next/last prefs
- [x] 4.5 prefetch / 静默刷新：`watch` deviceNo；dn 空不标网刷完成，dn 就绪后重跑
- [x] 4.6 主壳 resume bundle：并行 `refreshAllAppointmentNextSilent` + `refreshAllAppointmentLastSilent`（不依赖预测页 mount；失败不 toast）

## 5. 预测页下拉收窄

- [x] 5.1 `smart_prediction_screen` onRefresh：并行 `refreshRolling24h` + 预约 next 全量静默 + 预约 last 全量静默；去掉 force 7 日与必打 latest-by-event
- [x] 5.2 失败策略：历史失败 toast；仅预约失败不挡指示器、不强制失败 toast；失败保留上次成功 UI
- [x] 5.3 确认下拉不触 UCG unread / pending PUT / 支付解锁副作用

## 6. 验收

- [ ] 6.1 手动：冷启一次 7 日；后台回前台 24h 历史 + 预约静默刷；非预约上一次随池；预约 next/last 随缓存
- [ ] 6.2 手动：杀进程后预约 next/last 先出缓存再静默刷新；下拉 / resume 收窄行为符合 design
- [x] 6.3 本变更不改 `app/android/**`；无需额外 release/proguard 项
