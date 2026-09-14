## 1. 共享弹窗确认钮跟色

- [x] 1.1 `invite_code_dialog.dart`：确认 FilledButton 背景改为 `widget.accent ?? scheme.primary`，前景保持 onPrimary
- [x] 1.2 `showGlassConfirmDialog`：确认钮背景改为 `eventAccent ?? scheme.primary`

## 2. 开通中心支付确认

- [x] 2.1 `_showFeaturePayConfirmDialog`：确认钮背景改用已有 `accent` 变量（勿再写死 scheme.primary）

## 3. 预测满额品牌入参

- [x] 3.1 `_requestForecastToggle` 满额分支：从 catalog 取 `prediction_unlock`，向 `showInviteCodeDialog` 传入 `logoUrl` 与 `resolveFeatureColor` 的 `eventAccent`

## 4. 开通中心卡内 CTA / 状态跟色

- [x] 4.1 `_FeatureUnlockCard`：CTA OutlinedButton 按卡用 accent 做 foreground / side；去掉对静态主题 style 的依赖
- [x] 4.2 激活徽章与已开通状态行字色改为 accent（未满徽章可降透明）；标题与介绍保持 onShell
- [x] 4.3 `_PayPerUnitLabel`：现价与「/个」跟 accent；删除线原价用 accent 降透明

## 5. 验收

- [ ] 5.1 手工：满额弹窗 logo/色与开通中心预测卡一致；确认钮为功能色
- [ ] 5.2 手工：Hub 邀请 / 支付 / 广告确认钮跟对应行功能色；未传 accent 的通用确认仍主题色
- [ ] 5.3 手工：Hub 各卡 CTA / 徽章 / 时效文案跟功能色；标题与介绍仍为中性色
