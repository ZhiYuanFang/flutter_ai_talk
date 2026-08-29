## Why

预测页用 `FeatureLockOverlay` 按排序下标锁整卡，与卡片上「开启/关闭预测」开关两套入口冲突，且下标槽与「按次购买可开条数」心智不符。产品改为：去掉浮层；以开关为唯一闸门；永久槽位按**当前已开启预测条数**计数；不足时弹框引导开通中心；VIP 开开关全放行。

## What Changes

- 预测列表/瀑布流：**移除**事件卡上的 `FeatureLockOverlay`（及 `lockIfNeeded` 下标锁路径）。
- 用户将预测开关从关拨到开时：若非 VIP 且已开启数 ≥ 永久 `allowedCount`，则**不**写入开启，弹出确认框；确定 → `/features/unlock`；取消保持关闭。
- 关闭开关始终允许（释放名额）。
- VIP：开开关不弹框、不受永久条数限制（仍不增加 Hub 永久库存展示）。
- **BREAKING（相对客户端既有锁语义）**：废止「当前排序前 N 行可用」的预测页锁模型，改为「最多同时开启 N 条预测」。

## Capabilities

### New Capabilities

- `prediction-toggle-slot-gate`：预测开关占用永久槽位、满额弹框进开通中心、VIP 放行。

### Modified Capabilities

- `prediction-vip-overlay-client`：去掉「display index + overlay」可用性要求，改为与开关闸对齐（或标注由本 change 取代锁浮层场景）。

## Impact

- Flutter：`smart_prediction_screen.dart`（去浮层、开关拦截）；可能复用 `showGlassConfirmDialog`。
- 叠加/废止 `prediction-lock-index-vs-nonleaf-total` 中「下标槽」预测页语义；Hub「已激活 N / 已全部激活」仍用永久 `allowedCount` vs 非叶子 total，不变。
- UCG 等其它 `FeatureLockOverlay` 用途不改。
- 不新建测试文件。
