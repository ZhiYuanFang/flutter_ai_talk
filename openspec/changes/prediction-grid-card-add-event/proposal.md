## Why

智能预测页网格（瀑布流）事件卡片目前只能开关推演，不能像喂养主页一样点一下就加事件；家长要记录时还得切回喂养页，打断「看预测 → 立刻记一笔」的节奏。

## What Changes

- 预测页 **仅网格/瀑布流**（`compact`）卡片支持整卡点击，行为对齐喂养主页 `_onEventGridTap`：有子事件则弹出目录选择叶子，再按 `time` / `one` / `number` 走同一套添加逻辑。
- 推演 Switch 仍独占手势，点击开关 **不得** 触发加事件。
- 添加成功后 **留在预测页**（不强制切回喂养）；历史写入仍走现有 `addHistoryEvent`，喂养时间线在切回时可见更新。
- 抽取与喂养主页共用的加事件入口，避免复制粘贴漂移；列表态卡片本变更 **不** 加整卡点击（非目标）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：网格事件卡片点击加事件（含子事件选择）及与喂养主页行为一致性。

## Impact

- Flutter：`smart_prediction_screen.dart`（网格卡 InkWell）；从 `home_screen.dart` 抽出共享加事件流程（picker + 三类型提交 + remote gate + usage 计数）；复用 `showEventCatalogPickerSheet`、`showHomeNumberEventSheet`、`feedRepository.addHistoryEvent`、`homeHistoryProvider` 乐观更新（若适用）。
- 不改服务端 API 契约；不自动新建测试文件。
