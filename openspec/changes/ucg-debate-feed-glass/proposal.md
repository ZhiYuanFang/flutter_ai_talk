## Why

UCG 辩论 pivot（`ucg-debate-pivot`）已将广场/关注 Feed 切换为辩论帖，但卡片仍沿用 `UcgSurfaceCard` 纯色轻表面，而 VS 条已部分玻璃化，视觉层级不一致；投票组件气质偏竞技、对目标用户「宝妈」不够友好。产品决定采用**折中假玻璃**统一推荐/关注列表风格，并将 `UcgDebateVsBar` 升级为**软糖马卡龙 + emoji 中心徽章**的可爱态，且详情页、分享截图与 Feed 保持同一视觉语言（无 `BackdropFilter`，Web 与离屏截图路径天然降级）。

## What Changes

- **新增 `UcgFeedFakeGlassCard`**（或等价共享 panel）：半透明白底 + 细白边 + primary 轻渐变 + 可选极浅阴影；**禁止** `BackdropFilter`。
- **广场推荐/关注辩论卡**：`UcgDebateFeedCard` 由 `UcgSurfaceCard` 迁移至假玻璃容器；内联论点区使用轻 tint pill（无 blur）。
- **`UcgDebateVsBar` 视觉升级**：去掉 `BackdropFilter`；左右色带改为马卡龙雾蓝/珊瑚渐变；大圆角软糖条；中心 **emoji** 徽章（默认 `✨`，可配置）；保留百分比-only、0 票对称无数字、`minDisplayRatio=0.12`、色带宽度对齐点击热区。
- **详情 / 个人时间线 / 分享离屏布局**：共用同一 `UcgDebateVsBar` 可爱态；`UcgDebateShareLayout` 外包假玻璃卡，分享 PNG 与 App 内卡片视觉一致。
- **小程序**：不在本变更范围（已有 flex 分栏投票；可选后续对齐马卡龙色值）。
- **规格**：修订 `ucg-square-feed` 轻表面条款为假玻璃；扩展 `ucg-debate-vs-bar` 与 `ucg-debate-share` 视觉验收。

## Capabilities

### New Capabilities

- `ucg-feed-fake-glass`：Feed 假玻璃 panel/token 规范（无 blur、圆角、边框、渐变、阴影上限）；与 compose 真玻璃 `UcgComposeLightGlassPanel` 的职责边界。

### Modified Capabilities

- `ucg-square-feed`：广场辩论卡容器由纯色轻表面改为假玻璃；论点区轻 tint 样式与 Feed 统一。
- `ucg-debate-vs-bar`：马卡龙色带、emoji 中心徽章、禁止 blur、软糖形态与选中态；热区与色带宽度一致（延续 pivot 修正）。
- `ucg-debate-share`：离屏分享布局 MUST 使用与 Feed 一致的假玻璃卡 + 可爱 VS 条，不得使用孤立白底黑字样式。

## Impact

- **flutter_ai_talk（本仓）**：`app/lib/ucg/ui/widgets/` 新增假玻璃 panel；改 `ucg_debate_feed_card.dart`、`ucg_debate_vs_bar.dart`、`ucg_debate_arguments_block.dart`、`ucg_debate_share.dart`；详情/个人时间线自动继承 VS 条变更。
- **go_ai_talk / wx_ai_talk**：无 API 变更。
- **基线对照**：MODIFIED 能力在 v2.0.3 / `ucg-debate-pivot` delta 之上叠加；归档时合并进版本基线。
- **性能**：列表滚动不引入 per-item `BackdropFilter`；Web 与分享截图与原生 App 同假玻璃路径。
