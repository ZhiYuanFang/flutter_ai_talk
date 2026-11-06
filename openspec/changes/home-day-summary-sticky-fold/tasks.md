## 1. 折叠 UI

- [x] 1.1 日期吸顶：默认一行裁切 chip；超过一行时日期右侧「展开」/「收起」；按日 `isExpanded` 状态
- [x] 1.2 chip 点击与展开控件分离（开图逻辑不变）

## 2. 实测高度

- [x] 2.1 收起/展开态 Offstage 或 post-frame 测真高，写回 `SliverPersistentHeader` extent；去掉稳态对偏大估高的依赖
- [x] 2.2 同日 totals/展开态不变时避免无意义 setState 抖高

## 3. 验收

- [ ] 3.1 手工：无底部大空白；默认一行；展开/收起；chip 仍开图；跨日展开独立
- [x] 3.2 不新建 `**/test/**`
