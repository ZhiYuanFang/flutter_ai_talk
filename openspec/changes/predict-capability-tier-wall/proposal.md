## Why

独立「预测能力状态卡」占纵向空间，且点击直跳开通中心，与「预测三档」心智不符。产品要把档位收进「接下来3小时」标题行，并用全屏三档墙（间隔/基础/Pro）浏览与试用，VIP 在标题上视为基础版、墙内 Pro 仍「暂未开放」。

## What Changes

- **移除** 预测页 3 小时与列表之间的 `PredictCapabilityStatusCard`。
- 「接下来3小时」标题后追加加粗同字号后缀：`· 间隔版` / `· 基础版` / `· Pro版`（syncing 时占位，不落最终档）。
- 3 小时卡：**整卡与正文不可点**；仅 **版本文案**（开墙）与 **AI分析** 可点（取消「点卡其余区域进喂养」）。
- 全屏三档墙：右上关闭；`carousel_slider` 中卡放大、两侧露出；上玻璃详情（图+文，能力色；间隔版无图）；下玻璃底栏按态「开通试用 / 已开通 / VIP已开通 / 暂未开放 / 当前节奏」等。
- 非 VIP 未开通基础：墙内直调 `trial/start(basic)`；Pro（含 VIP）未购人权益 →「暂未开放」。
- VIP：标题跟随 **基础版**；墙内间隔+基础底栏「VIP已开通」；Pro「暂未开放」。
- 依赖：新增 `carousel_slider`。
- Hub `/features/unlock` 保留。

## Capabilities

### New Capabilities

- `predict-capability-tier-wall`：三档标题后缀、全屏墙、底栏态与试用行为。

### Modified Capabilities

- `predict-capability-status-card`：撤销独立状态卡（及挂在其上的 syncing 文案要求）；档位展示迁到三档墙/3h 后缀。
- `smart-prediction-page`：修改「接下来3小时」手势——取消整卡进喂养；保留 AI分析；增加版本文案热区开墙。

## Impact

- UI：`smart_prediction_screen.dart`（`_NextThreeHoursTimeline`）、删除/停用 `predict_capability_status_card.dart` 挂载；新建全屏墙组件。
- 依赖：`app/pubspec.yaml` → `carousel_slider`。
- 复用：`featureCatalog` logo/color、`startFeatureTrial`、settle phase、VIP settle。
- 规格：与 `predict-capability-client` / `settle-gate` 中状态卡 delta 冲突处以本变更 supersede。
