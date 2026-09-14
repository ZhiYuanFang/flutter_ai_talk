## Context

共享邀请码弹窗（`showInviteCodeDialog`）已支持可选 `eventAccent` / `logoUrl`，开通中心与 AI 分析 / 成长轨迹调用点已传入；预测满额闸门 `_requestForecastToggle` 未传。玻璃边与 `FeatureLogo` 已消费 accent，但确认 `FilledButton` 在邀请码弹窗、`showGlassConfirmDialog`、Hub 支付确认中仍写死 `scheme.primary`。

记事 sheet 等事件色路径已用 `backgroundColor: accent`，开通家族应对齐。

## Goals / Non-Goals

**Goals:**

- 预测满额弹窗与 catalog `prediction_unlock` 的 logo / 功能色一致
- 开通家族（邀请码、传了 accent 的玻璃确认、Hub 支付确认）确认钮背景跟功能色
- Hub 功能卡内 CTA / 状态文案跟该行功能色；标题与介绍保持 `onShell`
- 未传 accent 的通用确认框保持主题色

**Non-Goals:**

- 不改满额文案标题/正文（可继续「预测槽位已满」）
- 不引入按亮度自适应字色（弹窗确认前景继续 `onPrimary`）
- 不改兑换 / 空码 / 如何获取等业务流
- 不扫全 App 所有 FilledButton
- 不改 Hub AppBar / 空态等页级 chrome 颜色

## Decisions

1. **调用点补品牌入参，不改弹窗默认文案**  
   从 `featureCatalogStateProvider`（或等价已有 catalog 快照）查找 `kFeatureIdPredictionUnlock`，传 `logoUrl: item?.logo ?? ''`、`eventAccent: resolveFeatureColor(context, item)`。缺 catalog 时 `resolveFeatureColor(null)` 回退 `ColorScheme.primary`，与其它开通入口一致。

2. **确认钮统一 `accent ?? scheme.primary`，前景 `onPrimary`**  
   与 `event_record_sheet` 一致；不做对比度算法，避免扩大主题工具面。已知浅色 catalog 风险见 Risks。

3. **在三处落地，而非新抽象按钮组件**  
   - `_InviteCodeDialogBody` 的 FilledButton  
   - `showGlassConfirmDialog` 的 FilledButton  
   - Hub `_showFeaturePayConfirmDialog` 的 FilledButton（已有局部 `accent` 变量却未用于按钮）  
   改动面小，避免过早抽 `AccentFilledButton`。

4. **左键「获取邀请码」/「取消」保持 glassLabel**  
   次要操作不跟功能色，避免双强调。

5. **Hub 卡内：CTA / 状态跟 accent，标题与介绍保持 onShell**  
   - OutlinedButton：按卡构造 `foregroundColor` / `side` 为 accent（替换静态 `_kUnlockCtaButtonStyle` 的主题默认）。  
   - 徽章与已开通状态行：字色用 accent（未满徽章可用 `accent` 降透明区分层次）。  
   - `_PayPerUnitLabel`：现价与「/个」跟按钮 foreground；删除线原价用 accent 降透明。  
   - CTA 保持描边，不改为实心 Filled。

## Risks / Trade-offs

- [浅色 catalog 色 + onPrimary 对比不足] → 运营配色规避；后续若复现再加亮度选字色  
- [showGlassConfirmDialog 全局跟 accent] → 仅调用方显式传入时生效；未传仍主题色，风险可控  
- [catalog 未加载时满额弹窗无 logo] → 占位图标 + 主题/解析回退色，可接受  
- [浅色 accent 描边 CTA 在玻璃底上偏弱] → 运营配色；必要时再加 `side` alpha / 字重

## Migration Plan

纯客户端 UI；无需迁移或开关。回滚即还原上述文件改动。

## Open Questions

无（卡内跟色已定：描边 CTA + 状态跟 accent；标题/介绍除外）。
