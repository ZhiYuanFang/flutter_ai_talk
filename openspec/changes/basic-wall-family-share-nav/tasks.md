## 1. 基础版墙导航

- [x] 1.1 在 `predict_capability_tier_wall.dart` 的 `_onBasicFeatureTap` 中将 `familyShare` 从与 `nextEstimate` 合并的 `break` 拆出，关墙后 `router.push('/settings/baby-share')`
- [x] 1.2 确认 `nextEstimate` 仍仅关墙；其它 kind 行为不变

## 2. 验收

- [ ] 2.1 真机：打开基础版能力墙 → 点「家庭全员共享」→ 墙关闭且进入「邀请家人」页（已绑定出示码 / 未绑定见空态文案均可）
- [ ] 2.2 真机：从设置「邀请家人」进入同一页，确认与墙入口一致
