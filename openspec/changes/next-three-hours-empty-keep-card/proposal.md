## Why

已绑定用户在「接下来 3 小时」无窗内预测事项时，整块时间线卡（含「AI分析」入口）被隐藏，导致 AI 分析难以从预测首页到达。空窗应仍展示卡片，并用空态文案提示无事可做，保证入口常显。

## What Changes

- 非 Auth 冷态（已登录且已绑定）下，「接下来 3 小时」卡 **始终展示**（有窗内事项或空窗皆然）。
- 空窗正文固定为：`接下来 3 小时暂无事项，享受属于自己的时光吧。`
- 有窗内事项时仍用既有「HH:mm 左右{名} → …」拼接文案。
- 手势不变：主区进喂养；「AI分析」进 `/prediction/ai-analysis`。
- Auth 冷态（未登录/未绑定）仍不展示该卡。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `smart-prediction-page`：三小时卡空窗常显 + 指定空态文案；废止「无段落则整块隐藏」

## Impact

- 客户端：`smart_prediction_screen.dart`（展示条件）、可选 `smart_prediction_rows.dart`（空文案常量 / builder）
- 无服务端 / **BREAKING** API；行为上相对旧规格「空窗隐藏」为产品向变更
