## Why

喂养记录分析工作台仍包在玻璃能力卡内，与成长轨迹工作台「无卡片 + AppBar CTA + 页底功能色渐变」不一致；同属 AI 分析子页却两种壳。按成长页方案 B 拉齐结构，并把「每日仅支持分析一次」挂到 AppBar CTA 下方（对齐成长用量小字）。

## What Changes

- 喂养工作台移除玻璃卡外壳（`ClipRRect` / `BackdropFilter` / `panelGlassGradient`）；页内仅 blurb + body（资格/开通/思考/列表）平铺。
- 页壳对齐成长：`pageBg` → 功能色 lerp 渐变、`extendBodyBehindAppBar`、透明 AppBar；标题跟 care-alert accent。
- 「AI智能分析」CTA 挪到 AppBar `actions`（合格且已开通、非请求中时）；请求中仍页内「正在思考中」。
- 「每日仅支持分析一次」挂在 AppBar CTA 正下方小字（与成长 `usageCopy` 同构）；不再放在原卡内标题下。
- 删除卡内重复 logo+标题行；列表保持扁平 ListTile + 分割线，不加回卡片壳。
- Hub 喂养入口卡、开通业务、daily 拉取规则不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `ai-analysis-page`：喂养工作台布局 MUST 与成长工作台同构（无卡、渐变、AppBar CTA）；「每日一次」MUST 挂 AppBar CTA 下
- `prediction-care-alert`：喂养工作台「AI智能分析」控件 MUST 位于 AppBar（业务语义不变）

## Impact

- 客户端：`feeding_analysis_screen.dart`（可轻参考 `growth_trajectory_screen.dart` AppBar CTA 结构）
- 与 `feature-accent-text-parity`（字色）兼容：字色政策保留，壳从卡内改为页级
- 触及既有「每日一次」展示位置 Requirement（工作台侧改挂点）
- 无服务端 / **BREAKING** API
