## 1. 去浮层

- [x] 1.1 移除预测页列表/瀑布流的 `lockIfNeeded` / `FeatureLockOverlay` 包装

## 2. 开关闸

- [x] 2.1 开预测前计算 `enabledCount` vs `allowedCount`；VIP 跳过校验
- [x] 2.2 满额：拦截 `setEnabled(true)`，`showGlassConfirmDialog` 提示后确认 `push('/features/unlock')`
- [x] 2.3 关预测始终直接 `setEnabled(false)`

## 3. 验收

- [x] 3.1 手工：无浮层；满额开开关弹框进开通中心；VIP 可超永久条数开启；关开关释放名额
- [x] 3.2 `openspec validate prediction-toggle-slot-gate --strict`
