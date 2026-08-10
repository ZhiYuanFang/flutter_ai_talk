## Why

L1 `displayBaby*` 已统一空态字面量，但各页仍重复 `watch(settingsBabyProvider)` + `asData?.value` 再逐字段调用原子。方案 B 提供展示快照 Provider，让身份展示一处 watch 即可拿齐昵称/月龄/头像入参。

## What Changes

- 新增不可变 `BabyDisplay`（由 L1 原子 `resolve`），字段含 `nickname`、`ageText`、`identityLine`、`babyId`、`sex`，以及可选原始 `profile`。
- 新增 `currentBabyProvider`（`BabyProfile?`，loading/error → null）与 `babyDisplayProvider`（基于当前宝宝 + 墙钟 `DateTime.now()` 解析快照）。
- 首批迁移：喂养沉浸头、预测身份顶栏、喂养空历史昵称插值，改为 `watch(babyDisplayProvider)`（或等价），去掉页面内重复的 watch/`asData`/散落 `displayBaby*`。
- 设置中心 / 宝宝编辑等需 `AsyncValue.when` 的加载态 UI **不**强制迁移；小组件截断 API 与「待设置」不变。
- 月龄按日历日变化，身份展示 **不** 绑定 `predictionClockProvider`（避免喂养头随秒级 clock 重建）。

## Capabilities

### New Capabilities

- `baby-display-provider`：宝宝身份展示快照 Provider（L2）及喂养/预测身份调用方迁移约定。

### Modified Capabilities

- `baby-display-atoms`：身份展示调用方在 watch 路径上 MUST 优先经展示快照 Provider，而非页面内重复 `settingsBabyProvider.asData` + 散落 L1 调用。

## Impact

- 代码：新建/扩展 provider（如 `settings_baby.dart` 或 `baby_display_provider.dart`）、`BabyDisplay` 可与 `baby_age.dart` 同域；改 `home_screen.dart`、`smart_prediction_screen.dart`。
- 依赖：既有 Riverpod + L1 原子；无原生/新包。
- 关联：承接已完成的 `baby-display-atoms`（L1）；不取代 `settingsBabyProvider` 的加载语义。
