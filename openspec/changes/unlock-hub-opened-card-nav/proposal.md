## Why

开通中心已开通的「智能分析」「成长轨迹」卡片目前只展示状态文案，无法进入对应业务页；用户需绕道预测页 AI 分析 Hub。已开通态应能一键直达详情，缩短路径。

## What Changes

- 当 catalog 行 `care_alert_smart_remind` 或 `growth_trajectory_predict` 处于有效开通（含 VIP 覆盖）时，整卡可点，分别 `push` 到 `/prediction/ai-analysis/feeding` 与 `/prediction/ai-analysis/growth`。
- 未开通行保持现状：整卡不可点进详情；CTA（支付/广告/邀请）照旧。
- 预测槽位等其它功能卡不增加详情跳转。
- **不**增加箭头 / 「查看」等额外可点暗示 UI。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `feature-unlock-hub`：已开通的智能分析 / 成长轨迹卡 MUST 可点直达对应详情子页

## Impact

- 客户端：`feature_unlock_hub_screen.dart`（卡点击与路由）
- 复用既有路由与 `isFeatureEffectivelyUnlocked`；无服务端 / **BREAKING** 变更
- 与进行中的 `feature-unlock-dialog-brand-accent`（品牌色）正交，可并存
