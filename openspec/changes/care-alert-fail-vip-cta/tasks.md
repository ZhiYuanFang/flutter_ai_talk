## 1. 失败态分流 UI

- [x] 1.1 `_CareAlertPanel`：`failed && !loading` 时按 VIP 分流；非 VIP 展示「开通会员查看每日提醒」+ chevron、无刷新；VIP 保留「接口异常」+ 刷新
- [x] 1.2 调用方传入 `onOpenVip`（或等价）；watch `vipStatusProvider`（`isVip` 真才走异常分支，未知当非 VIP）
- [x] 1.3 Web：开通点击走既有 Toast，不 push 购买页

## 2. 购买回流

- [x] 2.1 非 Web：`push('/vip/purchase')` 返回后 `vipStatusProvider.refresh()`
- [x] 2.2 刷新后若 `isVip`，则 `predictionCareAlertStateProvider.ensureLoaded(force: true)`；仍非 VIP 不强制重拉

## 3. 校验

- [x] 3.1 `dart analyze` 触及文件无新增 error
- [x] 3.2 手工：非 VIP 失败 → 开通文案 → 购买页；VIP 失败 → 异常+刷新；开通成功返回 → 重拉
