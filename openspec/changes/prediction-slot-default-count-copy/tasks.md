## 1. Go：catalog 下发 defaultCount（先于 Flutter）

- [x] 1.1 在 `go_ai_talk` 的 `FeatureCatalogItem` / `v1.CashFeatureCatalogItem` 增加 `defaultCount`（json），预测项赋值为定义表 `DefaultAllowedCount`
- [x] 1.2 `CashFeatureController.Catalog` 映射带出该字段；确认不改 `allowedCount` 合成
- [x] 1.3 联调环境验证 catalog 响应含 `defaultCount` 后再开始 Flutter

## 2. Flutter：解析与弹框文案

- [x] 2.1 `FeatureCatalogItem` 解析可选 `defaultCount`；经 provider 暴露给预测页（缺省为 null）
- [x] 2.2 `_requestForecastToggle` 满额文案：`defaultCount != null && >0 && enabledCount==defaultCount` →「默认已开启…」；**缺 defaultCount 时文案不得含「默认」**；`allowedCount<=0` 保持零槽位文案
- [x] 2.3 确认闸门 / 槽位对齐仍只使用 `allowedCount`

## 3. 手工验收

- [ ] 3.1 默认额度顶满：文案含「默认已开启」
- [ ] 3.2 旧服无字段或加购后顶满且 enabled≠default：文案不含「默认」
- [ ] 3.3 满额仍拦截并进开通中心
