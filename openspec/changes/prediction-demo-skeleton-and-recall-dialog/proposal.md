## Why

预测主页在未登录、未绑定或尚无喂养历史时缺少「页面能做什么」的直观预览；量身定做又占满主内容，与「先看懂功能、再补回忆」冲突。需要冷态骨架演示 + 假留意文案，并把已绑定无历史的采样引导改为可软关的 Dialog，同时把头像入口统一到设置总页。

## What Changes

- **冷态骨架预览**：未登录、未绑定、或已绑定且预测 range 真历史为空时，主内容展示**全量无父根事件**的预测事件骨架（倒计时落在未来 3 小时内）；**不得**用喂养页「立即绑定宝宝」全屏空态替代预测预览。
- **骨架随机策略**：同一「秒级 tick」内倒计时偏移**固定**；仅在**整页重建**（离开再进预测页或等价 remount）时重抽，避免 Riverpod/setState 微重建导致倒计时乱跳。
- **假留意卡**：上述冷态下「值得留意」**仍展示**，文案固定为宝宝很健康类正向文案；**MUST NOT** 请求 care-alert 日拉取接口。有任意真历史后才 `ensureLoaded` 真列表。
- **量身定做 → Dialog**：仅「已绑定 + range 真历史完全为空 + 未 finale」时弹出；Dialog 内为 PageView（一卡一页、禁手滑、逐卡思考等既有流程）；**底层仍是骨架**。点遮罩软关；软关后点击**除头像外**区域再弹；**采样走完后永久不再弹**。
- **头像导航（BREAKING 相对 prediction-as-home-hub）**：预测顶栏头像全局改为进入 `/settings`（设置总页），不再进 `/settings/baby`；未登录仍走既有登录门。
- 保留策略 B：有任意真历史则只靠真数据，不引导；种子合成策略 C 与真历史上后丢弃根种子不变。无子节点的根：卡上只显示根自身一钮。

## Capabilities

### New Capabilities

- `prediction-demo-skeleton`：冷态骨架行生成、秒级稳定随机、假留意展示与禁止副作用 HTTP。

### Modified Capabilities

- `prediction-recall-onboarding`：主表面改为预测页 Dialog；软关/再弹/finale 永久关闭；底层骨架而非占满主 Column。
- `smart-prediction-page`：冷态用骨架+假留意；头像进 `/settings`；有真历史才挂真留意拉取路径。
- `prediction-care-alert`：无真历史时不得 ensure 日拉取；冷态 UI 使用固定健康文案而非空/错态接口驱动。

## Impact

- **UI**：`smart_prediction_screen.dart`、`prediction_recall_onboarding_panel.dart`（Dialog 包装）、头像 `context.push`。
- **逻辑**：骨架 row 构建（可旁路 `smartPredictionRowsProvider`）、`UcgHomeShell` / care-alert `ensureLoaded` 门闸、`predictionRecall*` 会话与 dismissed 语义。
- **规格基线**：对照 `openspec/specs/v2.1.0.md`；行为增量相对未归档的 `prediction-recall-*`、`prediction-as-home-hub`、`llm-care-alert-daily`。
- **测试**：不新建 `**/test/**`；手工验收冷态骨架、假留意无网络、Dialog 软关再弹与 finale 永久关、头像进设置。
