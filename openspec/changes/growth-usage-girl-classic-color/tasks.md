## 1. 契约与 Go 用量字段

- [x] 1.1 更新 CONTRACT：`latest` / `result` 增加 `usedToday`、`dailyLimit`（账号 wxId 上海日）
- [x] 1.2 Go：`GrowthTrajectoryLatest` 与成功 result 写入用量字段（读现有 Redis + dailyLimit 配置）

## 2. Python 结果文案

- [x] 2.1 修改 `generate` 提示词：禁止按日拆分；整段 7 天变化/注意点；多 emoji
- [x] 2.2 同步 fallback Markdown 模板

## 3. Flutter 用量展示

- [x] 3.1 模型/provider 解析并保存 `usedToday`/`dailyLimit`；latest 与 result 后刷新
- [x] 3.2 AI 分析页 CTA 下方小字「今日已用 x/y 次」；用尽不灰按钮，超限 Toast

## 4. 女宝经典色

- [x] 4.1 `theme_preset.dart`：`sexPrimary(BabySex.female)` → `Color(0xFF2CB771)`

## 5. 验收

- [ ] 5.1 手工：用量展示、用尽 Toast、结果无「第N天」、女宝经典主题为绿
- [x] 5.2 `openspec validate growth-usage-girl-classic-color --strict` 通过

## 6. choice 手动输入与圆角

- [x] 6.1 choice：双按钮下「手动输入」；展开隐藏选项，收起恢复；提交走同一 `submitAnswer`
- [x] 6.2 choice `OutlinedButton` 圆角矩形（radius 8）；CTA 圆角不改
