## 1. 算法：排除 one 样本与模态

- [x] 1.1 为 `resolveWinningExpect` / `attachWinningExpect`（及 duration/amount 采点、`countableExpectKind`）接入目录叶子 `eventType` 解析（与 `predictAllUpcoming` 已有 catalog 对齐）
- [x] 1.2 amount 仅纳入 `eventType=number` 且 `eventNumber>0`；duration 排除 `eventType=one`；one 不参与最近可计量决胜
- [x] 1.3 确认仅 one 历史的根：`hasExpect==false`、pending 不带 expect 字段；number/time 混根行为不变

## 2. 布局：预计约贴倒计时

- [x] 2.1 从预测卡标题区移除 `expectLabel` 占位
- [x] 2.2 在倒计时区块内、倒计时文案正上方渲染「预计约…」（有大 logo 时位于 logo 与倒计时之间）
- [x] 2.3 无大 logo 但仍有倒计时时，expect 仍紧贴倒计时上方；无倒计时/计时中不强制展示

## 3. 手工验收

- [ ] 3.1 one 根（如换尿布）≥2 次真历史且有 `nextAt`：卡上无「预计约…」；本机变更后 pending 该项无 expect 字段
- [ ] 3.2 number 根（配方奶）有胜出 amount：文案在倒计时上方（大 logo 之下）
- [ ] 3.3 time 根（睡眠）有胜出 duration：文案在倒计时上方（大 logo 之下）
