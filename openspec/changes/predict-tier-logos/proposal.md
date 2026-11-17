## Why

免费/Pro 两档墙与「接下来3小时」卡目前几乎只靠文字区分档位；免费档在墙内甚至无图。产品要用本地 `assets/images/pre_basic.png` 作为免费版 logo，并在 3h 卡最左侧展示当前档 logo（Pro 用 catalog 图），让档位一眼可辨且图文垂直居中。

## What Changes

- 两档墙 **免费版** 卡顶部 MUST 展示本地资产 `assets/images/pre_basic.png`（非 catalog URL）。
- 「接下来3小时」卡最左侧 MUST 展示档位 logo：syncing / 免费 → `pre_basic.png`；Pro → catalog `predict_capability_pro.logo`；Pro 无有效 URL 时 MUST 用占位图标（不得塌成空白缺口）。
- 卡内布局 MUST 为左侧 logo + 右侧标题/正文列，`CrossAxisAlignment.center`，保证 logo 与文案块纵向居中。
- 不改整卡开墙、`Icons.upgrade`、试用/墙内付费语义。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-free-pro-chrome`：免费墙本地 logo；3h 左侧档位 logo 规则（含 syncing=免费图、Pro 无 URL 占位）。
- `smart-prediction-page`：接下来3小时卡布局改为左 logo + 右文，纵向居中。

## Impact

- 代码：`predict_capability_tier_wall.dart`、`smart_prediction_screen.dart`（`_NextThreeHoursTimeline`）；可复用/扩展 `FeatureLogo` 或薄封装；常量指向 `pre_basic.png`。
- 资产：`app/assets/images/pre_basic.png`（已在 `assets/images/` 目录下，pubspec 已声明目录）。
- 无新 HTTP / 原生 / R8。
