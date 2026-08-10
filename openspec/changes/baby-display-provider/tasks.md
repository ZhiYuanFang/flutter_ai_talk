## 1. 快照模型与 Provider

- [x] 1.1 新增 `BabyDisplay`（`resolve` 委托 L1 `displayBaby*`），含 nickname/ageText/identityLine/babyId/sex/profile
- [x] 1.2 新增 `currentBabyProvider` 与 `babyDisplayProvider`（data 层不直接依赖 Riverpod；Provider 放 `providers/`）

## 2. 调用方迁移

- [x] 2.1 喂养沉浸头改为 `watch(babyDisplayProvider)`，去掉本地 `settingsBabyProvider`/`asData`/散落 L1
- [x] 2.2 预测身份顶栏改为 `watch(babyDisplayProvider)`
- [x] 2.3 喂养空历史昵称改为快照 `nickname`（可与顶栏共用同一 watch 或局部 watch）

## 3. 验收

- [x] 3.1 确认设置页仍用 `AsyncValue.when` 与「待设置」；身份快照未订阅 `predictionClockProvider`；`dart analyze` 相关文件无新增 error
