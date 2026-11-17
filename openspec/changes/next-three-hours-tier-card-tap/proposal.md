## Why

「接下来3小时」卡当前仅版本文案下划线热区可开免费/Pro 两档墙，整卡其余区域不可点，免费档也缺少显式升级暗示。用户期望：免费档在档位文案旁展示 `Icons.upgrade`；且无论当前是免费版还是 Pro 版，在非同步占位时整卡点击均可打开两档墙（便于浏览/对比，而非仅免费可点）。

## What Changes

- 3h 卡在 settle 非 syncing 时：**整卡**（含标题「接下来3小时」、档位后缀、正文）均可点，打开既有免费/Pro 两档墙；`initialTier` 仍对应当前后缀档。
- settle **syncing**（或等价不可结案后缀）时：整卡与后缀均 **不得** 开墙。
- 当前为 **免费版** 时：档位后缀文案旁 **必须** 展示 Material `Icons.upgrade`（同色系、紧挨文案）；**Pro 版** 与 syncing **不得** 展示该图标。
- 取消「仅后缀可点 + 下划线暗示」为唯一热区的要求；后缀本身仍展示档位文案，但热区扩大到整卡。
- 既有约束保留：整卡 **不得** 因此进喂养；**不得** 恢复「AI分析」入口（与 `align-go-free-predict-retire` 一致）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `predict-free-pro-chrome`：免费档后缀旁 `Icons.upgrade`；开墙触发面从「仅后缀」改为「整卡（含 Pro）」；syncing 仍不可开墙。
- `smart-prediction-page`：修改「接下来3小时」手势——非 syncing 时整卡开两档墙；免费档升级图标；仍不得进喂养、不得出 AI分析。

## Impact

- 代码：`app/lib/ui/smart_prediction_screen.dart`（`_NextThreeHoursTimeline`）为主；开墙仍复用 `showPredictCapabilityTierWall` / `predict_capability_tier_wall.dart`，墙内交互不变。
- 规格：相对 `align-go-free-predict-retire` 中「ONLY suffix MAY be tappable」与 `predict-free-pro-chrome`「Tapping the suffix」条款做 delta supersede。
- 无新依赖、无 Android 原生/R8、无新 HTTP。
