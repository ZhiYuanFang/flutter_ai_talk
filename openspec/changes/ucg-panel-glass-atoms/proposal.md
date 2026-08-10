## Why

`theme-panel-glass-atoms` 已为预测页提供 `panelGlass*`，但 UCG 广场假玻璃仍挂近白 `contentCard`，辩论 VS / 马卡龙等仍散落 `Color(0x…)` / `Colors.white`。夜空下广场白卡与预测 chrome 割裂，且模块取色绕过 `AppColor` 契约。需把广场与辩论卡统一到 panelGlass，并把辩论左右侧等「类别色」升为原子，消灭业务硬编码。

## What Changes

- **广场 + 辩论卡外壳**：`UcgFeedFakeGlassPanel`（及辩论 Feed 卡、分享卡）改挂 `AppColor.panelGlassGradient` + `textOnPanelGlass*`；暗壳 MUST NOT 再以近白 `contentCard` 起笔（夜空不白卡）。
- **辩论类别色原子化**：左右马卡龙渐变、标签/百分比字色、VS 条边与中心钮等，从 widget 内硬编码迁入主题原子（`AppColor` / `AppVisualTokens` 或等价辩论角色），业务只选角色。
- **UCG 取色契约**：壳上/卡内正文优先 `AppColor.*`；`UcgTheme` 仅允许转发原子，不得另起色源。扫清 `tokens?.onShell` / `onRecordsCard` 直读与硬编码白边/白底（媒体沉浸 scrim 若保留，亦须原子入口 + 注释例外）。
- **文档**：`project.md` / `AppColor` 注明 UCG 广场与辩论挂 panelGlass；类别色走原子。
- 不新建 `**/test/**`；不改主页历史日卡的 `contentCard` 浅卡策略（非 UCG 广场）。

## Capabilities

### New Capabilities

- `ucg-theme-panel-glass`：UCG 广场/辩论卡挂 panelGlass、夜空不白卡、辩论类别色原子、UCG 取色契约与硬编码清扫验收。

### Modified Capabilities

- `theme-panel-glass`：消费方从「仅预测页」扩展为含 UCG 广场与辩论 chrome（原子本身不变，义务扩展）。

## Impact

- **UI**：`ucg_feed_fake_glass_panel.dart`、`ucg_debate_feed_card.dart`、`ucg_debate_vs_bar.dart`、`ucg_debate_arguments_block.dart`、`ucg_debate_share.dart`、masonry/moments 相关卡、`ucg_theme.dart` 及 UCG 内仍直读 tokens / `Colors.*` 的壳文案路径。
- **主题**：必要时扩展 `AppVisualTokens` / `AppColor`（辩论侧角色）；`theme_preset.toTokens` 派生。
- **文档**：`openspec/project.md` 主题约定一行；不改 Feed 历史 `contentCard` 全局公式。
- **验证**：夜空主题下广场/辩论卡为暗主题浮层且正文可读；经典浅壳可读；无 widget 内硬编码类别色；VS/马卡龙经原子仍可识别左右侧。
