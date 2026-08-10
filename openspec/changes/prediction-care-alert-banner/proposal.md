## Why

智能预测页已有 tip 卡与事件推演列表，但缺少基于「自身近期节律 + 月龄期望」的轻量留意信号。家长需要在不制造医疗恐慌的前提下，看到最多一条值得关注的偏离，并能点进详情理解依据。

## What Changes

- 在智能预测页 **小贴士卡片与事件推演列表之间** 增加「值得留意」预警条：全事件扫描，最多展示 **1** 条（最高优先级）；无候选时 **整块隐藏**。
- 新增本地规则引擎（独立于 `event_next_predictor`）：输入为 7 日 range 历史 + 宝宝月龄；对比基准为 **自身 7 日基线** 与 **月龄期望表**。
- 规则类型与优先级（高→低）：**间隔拉长** > **进行中过久** > **突然消失**。
- 点预警进入 **新页面**，结构化展示触发原因（类型、自身基线、月龄期望、实际观测），而非仅一行文案。
- 首版语气固定为「值得留意」；不做医疗诊断文案；未知月龄时仅用自身 7 日基线。

## Capabilities

### New Capabilities

- `prediction-care-alert`：护理留意预警的规则引擎、Top1 选取、Banner 文案契约、详情页原因结构、月龄期望表默认档位与样本门槛。

### Modified Capabilities

- `smart-prediction-page`：在 tip 卡与推演列表之间插入预警条槽位；无预警时不占位；点击导航至预警详情路由。

## Impact

- UI：`app/lib/ui/smart_prediction_screen.dart`（插入 Banner）；新增预警详情屏。
- 路由：`app/lib/router/app_router.dart`（如 `/prediction/alert`）。
- 数据：复用 `prediction_range_history`（7 日）与 `babyAgeInMonths` / `isUsableBabyBirthDate`；新增本地期望表与评估模块（建议 `app/lib/data/` 下独立文件，不改推演核心公式）。
- Provider：新增只读评估 provider（无副作用 HTTP）；range ensure 仍走既有通道。
- 不改服务端 API；不改 companion / tip SSE；不自动新建测试文件。
