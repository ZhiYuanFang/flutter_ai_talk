## 1. 开通中心底栏

- [x] 1.1 恢复 `bottomNavigationBar: _VipStickyBar`；`watch(vipProductProvider)`；接入 `kVipPurchaseEnabled` 与 `/vip/purchase`
- [x] 1.2 已 VIP：主标题改为 `VIP · ${featureRemainingDaysCopy(expireAt)}`；副文保留到期日（适用时）；无购买按钮
- [x] 1.3 未 VIP：保持开通引导文案与「去开通月卡」按钮

## 2. 值得留意清理

- [x] 2.1 删除 `prediction_care_alert_screen` 中 VIP CTA 注释块、`showVipCta` 及相关暂停注释
- [x] 2.2 移除因此未使用的 import，确认页仍可忽略/追问

## 3. 验收

- [x] 3.1 非 VIP：开通中心见底栏，点 CTA 进购买页
- [x] 3.2 已 VIP：标题为「VIP · 剩余 N 天」（或不足 1 天/永久），无开通按钮
- [x] 3.3 值得留意详情无任何 VIP 开通入口
