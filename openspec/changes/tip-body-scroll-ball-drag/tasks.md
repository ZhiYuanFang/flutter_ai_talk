## 1. 展开手势与滚动

- [x] 1.1 去掉展开态 pan / `_dragOffset` 过半贴边路径；卡位固定居中
- [x] 1.2 正文可竖向滚动；tip 场景关闭 Markdown 选区（或等价）以免抢 tap
- [x] 1.3 正文 tap：`done`+可注入进陪伴；顶标仅折叠；指针占用锁滑保留

## 2. 球态与验收

- [x] 2.1 确认仅球态可拖贴边/拉出/点开（EdgeDockShell）
- [ ] 2.2 手工：滚文案、点进陪伴、streaming 不跳、折叠后拖球贴边
- [x] 2.3 未改 `app/android/**` 则无需 release APK
