## 1. 调整锚点

- [x] 1.1 `HomeHistoryTimelineTile.logoSizeMax` 改为 24；`logoSizeForFromBottom` 用 `24 * fontSize / 13`，clamp 10–24
- [x] 1.2 确认飞入 / badge inset 使用 `logoSizeMax`（随 24）

## 2. 验收

- [ ] 2.1 手工：底行约 24，上滚渐小，不低于约 10；行高与飞入正常
- [x] 2.2 不新建 `**/test/**`
