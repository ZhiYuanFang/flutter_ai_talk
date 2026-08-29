## 1. 支付确认弹窗

- [x] 1.1 将 `_openPaymentDialog` 改为 `showGlassDialog`，布局对齐现有 glass confirm（标题/说明/取消+确认）
- [x] 1.2 确认键：`去支付`（Web：`仅 App 可支付`）+ 右侧小字 `(priceLine)`；正文去掉「价格：」行
- [x] 1.3 保留确认后支付调用与 Web 拦截逻辑不变

## 2. 验收

- [x] 2.1 手工：预测/非预测确认键价形态正确；广告弹窗仍走原 confirm
- [x] 2.2 `openspec validate feature-pay-confirm-price-on-button --strict`
