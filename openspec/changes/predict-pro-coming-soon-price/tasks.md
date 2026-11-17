## 1. 价格文案

- [x] 1.1 从 `FeatureCatalogItem.defaultProduct.priceFen` 拼 `¥{yuan}/月`（整数可去小数；`/月` 写死）；`priceFen<=0` 或无 product 返回空
- [x] 1.2 确认不读 `durationDays`、不本地硬编码具体金额

## 2. 脚 UI

- [x] 2.1 `_FooterStatusLabel` 支持可选同行小字 `priceHint`（更小字号、onSurface 略淡）
- [x] 2.2 仅 Pro + `comingSoon` 且 hint 非空时传入；「正在使用」/基础版不传
- [x] 2.3 保持浅灰底、不可点、非按钮 chrome

## 3. 验收

- [x] 3.1 有 catalog 价：Pro 未开通脚为「敬请期待 ¥x/月」同行
- [x] 3.2 无价：仅「敬请期待」；已开通仅「正在使用」
- [x] 3.3 点击脚不得发起支付/试用
