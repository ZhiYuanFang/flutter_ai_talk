## Why

量身定做按「根事件缺口」触发时，用户已有部分喂养历史仍会进入全屏引导，与「冷启动补回忆」心智不符。同时当前引导用 AnimatedSwitcher 单卡切换，缺少「一页一悬浮卡」的 PageView 质感，且引导过程中仍露出值得留意 / 三小时 / 底部 tip，干扰专注填写。

## What Changes

- **触发收窄（策略 B）**：仅当喂养相关预测 range（及约定的真历史源）**完全无记录**时才展示量身定做；只要存在任意真历史，**不得**进入引导，只靠真数据推演。
- 引导进行中：**隐藏**值得留意、接下来 3 小时、底部 tip 跑马灯（身份顶栏可保留）。
- UI：主内容为**悬浮感卡片 PageView**（一根事件一页）；**禁止用户手指左右滑动**切卡，仅通过确认 / 跳过 / 思考「继续」等按钮由程序 `animateToPage` 前进。
- 仍复用既有种子合成、跳过关推演、逐卡思考、收尾 CTA 等能力（本 change 调整门闸与呈现）。

## Capabilities

### New Capabilities

- （无全新能力名；以修改既有回忆引导为准。）

### Modified Capabilities

- `prediction-recall-onboarding`：空库才触发；PageView 悬浮卡且禁手滑；引导时隐藏预测页附属 chrome。
- `smart-prediction-page`：引导层展示时不得同时展示留意 / 三小时 / 底 tip。

## Impact

- **逻辑**：`predictionRecallGapRootsProvider` / 会话启动条件改为「真历史为空」门闸。
- **UI**：`PredictionRecallOnboardingPanel`、`SmartPredictionScreen` 条件渲染。
- **测试**：不新建 `**/test/**`；手工验收有历史不进引导、空历史 PageView 禁滑、chrome 隐藏。
