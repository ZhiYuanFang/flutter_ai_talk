## 1. 算法：皆冷一次换锚

- [x] 1.1 `predictNextForEventKey`：非种子皆冷后以 `nextAt₀` 为亲和锚重估 `interval₁`，`nextAt₁ = lastAt + interval₁`；热则采用，仍冷软留；最多 1 次
- [x] 1.2 种子路径不自动跳；`[PredictInterval]` 记录 `autoSkip`

## 2. 拆除手工 missAnchor

- [x] 2.1 移除卡上「跳过本次」及相关 busy 逻辑
- [x] 2.2 删除/停用 store、provider、rows/widget/wipe 注入与 clearStale；predictor 去掉 miss 参数或调用方

## 3. 验收

- [x] 3.1 手工：皆冷可换锚；种子冷无连跳；无跳过按钮；不新建 `**/test/**`
