## Why

AI 分析 Hub 能力卡已统一「卡内文案跟功能色」；开通中心卡标题/介绍仍用中性 `onShell`，喂养分析与成长轨迹详情页标题/提示/介绍仍用 `onGlass` / `onShell`。同能力族视觉分裂，且与进行中的 `feature-unlock-dialog-brand-accent`「标题不得跟色」约定冲突。先做字色对齐（方案 A），不改玻璃壳配方与页结构。

## What Changes

- 开通中心每张功能卡：标题与介绍文案改跟该行 `resolveFeatureColor`（可降透）；CTA / 状态文案继续跟 accent（既有）。
- 喂养记录分析工作台：卡内标题、副文案、muted 提示、介绍 blurb、开通引导字色改跟 care-alert 功能色（加深或全色，避免浅底发灰）；玻璃壳与列表结构不变。
- 成长轨迹工作台：介绍 blurb、muted / 思考 / 问答主文案等页内文案改跟成长功能色；AppBar / 整页渐变壳与交互结构不变。
- **不**切换 `SettingsGlassPanel` ↔ `panelGlassGradient`；**不**把成长页改成 Hub 式玻璃卡；**不**在详情页引入 Hub 模拟样张角标。
- 规格上推翻开通中心「标题/介绍不得跟功能色」：改为必须跟色。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `feature-unlock-hub`：功能卡标题与介绍 MUST 跟行功能色（修订 brand-accent 相反约束）
- `ai-analysis-page`：喂养 / 成长工作台页内文案 MUST 跟对应功能色（与 Hub 字色政策对齐）
- `growth-trajectory-predict`：成长工作台会话文案 MUST 跟成长功能色（壳结构不变）

## Impact

- 客户端：`feature_unlock_hub_screen.dart`、`feeding_analysis_screen.dart`、`growth_trajectory_screen.dart`
- 与 `feature-unlock-dialog-brand-accent`（标题不跟色）冲突处由本 change 规格覆盖；与 `ai-analysis-hub-mock-preview`（Hub 已跟色）正交
- 无服务端 / **BREAKING** API
