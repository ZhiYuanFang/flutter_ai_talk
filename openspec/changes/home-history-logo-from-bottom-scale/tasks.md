## 1. 动态 logo 尺寸

- [x] 1.1 `HomeHistoryTimelineTile`：由 `fromBottom` 计算 base `fontSize` 后推导 `logoSize`（`16 * fontSize / 13`，clamp ~10–16）；替换常量槽位与 `EventLogo(size:)`
- [x] 1.2 `timelineBadgeLeftInset` 等仍按最大 16（或文档化等价）估算；不改飞入/停止逻辑

## 2. 验收

- [ ] 2.1 手工：底行 logo 明显大于上滚旧行；行高与飞入落点正常
- [x] 2.2 不新建 `**/test/**`
