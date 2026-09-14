## 1. 拆卡与页壳

- [x] 1.1 `feeding_analysis_screen.dart`：移除玻璃卡外壳；`ListView` 平铺 blurb + body；去掉卡内 logo/标题行
- [x] 1.2 对齐成长：`pageBg`→accent 渐变、`extendBodyBehindAppBar`、透明 AppBar；标题跟 accent

## 2. AppBar CTA 与每日一次

- [x] 2.1 「AI智能分析」挪到 AppBar `actions`（合格已开通且非 loading）；可抽 `_FeedingAppBarCta`
- [x] 2.2 「每日仅支持分析一次」挂在该 CTA 正下方小字；卡内副文案删除

## 3. 清理与验收

- [x] 3.1 去掉仅服务于玻璃卡的无用 import（如 `dart:ui` BackdropFilter）；保留字色/加深策略
- [ ] 3.2 手工：无玻璃卡、渐变底、AppBar CTA+每日一次；资格/开通/列表/思考业务正常
