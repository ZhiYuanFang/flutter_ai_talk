## 1. UI

- [x] 1.1 `FeedingEligibilityProgressText`：第一行已累计 X/N；第二行还需 Y 天（按 kind）；强调数字；钳负值为 0
- [x] 1.2 确认 UCG 浮层与值得留意卡仍挂该 Widget，无需改调用签名（若需换行/对齐则微调）

## 2. 验收

- [x] 2.1 `openspec validate feeding-eligibility-effective-days-copy --strict`
- [ ] 2.2 手工冒烟：未合格值得留意与 UCG 浮层均见两行进度
