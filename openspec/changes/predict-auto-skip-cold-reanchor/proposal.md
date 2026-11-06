## Why

手工「跳过本次」依赖本机 `missAnchor`，无法随多端共享历史同步，且清锚与窗口 tip 不一致时会出现「跳成了又算回来」。预测应只由共享历史确定性推导：落冷区时由算法自动换亲和锚重估间隔并再落点一次，去掉本机跳过态。

## What Changes

- **BREAKING（相对未归档 miss-anchor）**：移除逾期「跳过本次」UI、本机 `missAnchor` 存储/provider/行注入/清锚逻辑。
- 非种子路径在 primary→gePrimary→crossDay **皆冷**之后：以冷点 `nextAt₀` 为亲和钟点锚重估 `interval₁`，落点 `nextAt₁ = 真 lastAt + interval₁`；**最多自动跳 1 次**。
- `nextAt₁` 热则采用且无软标；仍冷则保留 `nextAt₁` +「此刻把握不足」（与既有软标 UI 一致）。
- **种子 / 用户填写间隔**（冷启动 `usedSeed`）：MUST NOT 自动跳；冷则软留当前候选。
- 亲和 h、直方图阈值、预约根、7 日窗不变。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `event-interval-prediction`：皆冷后一次自动换锚重估；种子不自动跳；废止 missAnchor 加法语义（若仍存在于未归档 delta，以本 change 为准）。
- `smart-prediction-page`：移除逾期「跳过本次」；软标在触顶仍冷时保留。

## Impact

- `event_next_predictor.dart`：皆冷后一次 reanchor；去掉对 `missAnchor` 加法/亲和共用逻辑（或忽略入参并删除调用方）。
- 删除/停用：`prediction_miss_anchor_store`、`prediction_miss_anchor_provider`、卡上跳过按钮、wipe/widget 注入。
- 软标与时刻态 inline caption 保留。
- 不新建 `**/test/**`；手工验收。
