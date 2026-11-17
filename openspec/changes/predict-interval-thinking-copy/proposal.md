## Why

间隔 Sheet 确认后的逐字思考加粗脚注仍写「随着后续喂养节奏，我会**自动修改**预测时间」，在双轨（未 entitle 展示强制固定间隔）上线后，用户容易误以为设完间隔就会**自动切到算法预测展示**。需要润色叙事：诚实「先按刚设间隔推演」，保留「记录多了会更准」的温度，**弱化付费/开通**话术，也不承诺无门槛自动切轨。

## What Changes

- 修改 per-card「大概多久一次」思考态加粗脚注文案语义（及主段中易暗示「立刻智能算法」的措辞）。
- 更新 `prediction-interval-sheet-thinking` 规格中对加粗说明的 MUST 语义。
- **可选对齐**：量身定做收尾若仍有「本地算法…持续学习」类自动升级暗示，做同口径轻润色（不改流程）。
- **不**改双轨门闸、试用弹窗、能力卡、trial API、Sheet 交互时序。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `prediction-interval-sheet-thinking`：思考态加粗脚注（及主段相关）MUST NOT 暗示无门槛自动切到算法预测展示；MUST 表达先按用户确认间隔推演，并可用「喂养记录增多 → 更贴合」的软表述；MUST NOT 在该段强推开通/付费。

## Impact

- 代码：`app/lib/ui/prediction_recall_interval_picker.dart`（`_boldFooter`、确认后 `_mainFull`）；可选 `prediction_recall_onboarding_panel.dart` 收尾文案。
- 无 API / 无新依赖 / 无 Android 原生。
