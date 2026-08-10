## 1. tip 展示与小组件对齐

- [x] 1.1 修改 `peekWidgetTipDisplayText`：仅以 `kWidgetTipTextKey` trim 非空决定返回值，去掉对 `kWidgetTipDayKey` 当日匹配的隐藏条件
- [x] 1.2 确认 `peekWidgetTipInjectText` / `isWidgetTipInjectedToday` 等陪伴注入路径仍按日，未误改

## 2. tip 写入后刷新预测页

- [x] 2.1 在小组件 sync / `resolveWidgetTip` 写入非空 tip 文案后，`invalidate`（或等价）`widgetTipCardTextProvider`，使已打开的预测页可重 peek
- [x] 2.2 核对 `widgetTipCardTextProvider` 仍向预测页提供非空文案时底栏可见

## 3. 跑马灯速度

- [x] 3.1 将 `_BottomTipMarquee` 的 `_pxPerSec` 从 `36` 调整为约 `18`（速度减半）；短文不溢出仍静止

## 4. 验证

- [ ] 4.1 手工：小组件已有 tip、dayKey 非今日或缺失时，预测页底栏仍显示同一正文跑马灯
- [ ] 4.2 手工：先进预测页（无 tip）再等 sync 写入 tip，底栏应出现而无需杀进程
- [ ] 4.3 手工：溢出文案滚动明显慢于改前；短文静止；点击仍进陪伴
