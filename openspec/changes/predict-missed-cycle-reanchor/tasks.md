## 1. 核算法

- [x] 1.1 在 `event_next_predictor` 增加漏记追赶（常量 2h / 最多 3 步；每步 tip=预测点 + 重采亲和；失败或仍超 → null）；默认关闭
- [x] 1.2 live：`predictNextForEventKey` / `predictAllUpcoming`（及 Widget 同源入口）启用追赶；顺序在既有 TOD autoSkip 之后
- [x] 1.3 `buildHistoryExpectAnchorPatches` 显式关闭追赶

## 2. 消费面与打戳

- [x] 2.1 确认智能预测 / 3h / Widget 走同一 live 结果；展示 lastAt 仍真记录
- [x] 2.2 无 nextAt 时喂养下一次卡不展示；活记事不打 expect*（pred null → fromPrediction 不打；锚点链关 chase）
- [x] 2.3 Debug：复用既有 `AppDebugLog.predictInterval`（`missedChase` 前缀），无新 tag

## 3. 校验（追赶核）

- [x] 3.1 `dart analyze` 相关文件无新增 error
- [ ] 3.2 手测：过期>2h 追赶；满 3 次无预测；中间插入 expect 链不被墙钟追坏；Widget/3h 与页一致
- [x] 3.3 Android 原生未改：**N/A** release APK / proguard

## 4. 漏记 tip 保留与竖屏卡展示

- [x] 4.1 `EventNextPrediction`（及 `copyWith` / chase 返回）携带有序 `missedTips`；`applyMissedCycleChase` 每步 append 滚过 tip，成功挂列表，未追赶为空
- [x] 4.2 竖屏热态非预约智能预测卡：有 tip 时在「上一次」与倒计时之间只读渲染 `可能漏记：` + 相对自然日时分（` · ` 连接）；弱样式、不可点
- [x] 4.3 横屏 / 对照卡 / 预约 / 玻璃卡 / 3h / Widget：**不**渲染该行
- [x] 4.4 `dart analyze` 相关文件无新增 error；手测竖屏有 tip、横屏无行、无 tip 不占位
