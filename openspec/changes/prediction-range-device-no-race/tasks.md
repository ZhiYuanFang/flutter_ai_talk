## 1. 空 deviceNo 失败语义

- [x] 1.1 `tryLoadHistoryFilter` / `tryLoadHistoryPageV2`：dn 空返回 `null`（失败），不得返回成功 `[]`
- [x] 1.2 确认 `fetchPredictionSevenDayHistory` 对 `null` 不写 ready（既有 fail 路径）

## 2. ensure 门控与自愈

- [x] 2.1 `ensureLoaded`：已登录且 dn 空时先 `deviceNo.refresh()`；仍无则不标 ready
- [x] 2.2 `ready && items.isEmpty && dn 可用` 时强制重拉（进页可自愈）
- [x] 2.3 必要时收紧 splash `ensureWidgetReadyFromRef` 与 ColdStart 时序（避免抢跑；以改动面小者为准）

## 3. 预测页空态

- [x] 3.1 `!ready || loading` 显示加载中；仅 ready 且 rows 空显示「暂无可用预测数据」

## 4. 验收

- [x] 4.1 冷启动后进预测页：应出现 filter HTTP 且有喂养数据时列表非空（logcat 无「无 filter 的 count=0 锁死」）
- [x] 4.2 模拟假空 ready 后进页：应触发重拉
