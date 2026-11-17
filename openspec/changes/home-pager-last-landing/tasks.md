## 1. 持久化

- [x] 1.1 新增 `HomePagerLastLandingStore`（prefs 键如 `home_pager_last_page_v1`）：读写 feeding|prediction；非法回落 null
- [x] 1.2 确认 wipe/登出默认**不清除**该键（与 design D2 一致）

## 2. 主壳着陆与写入

- [x] 2.1 `UcgHomeShell`：构造 `PageController` 前同步读 lastPage；合法则作 `initialPage`，否则 prediction
- [x] 2.2 `_predictionEverMounted` / 懒挂载标志与真实 initialPage 对齐（冷启落喂养时不要假定预测已挂）
- [x] 2.3 `_onPageChanged`（及等价切页完成路径）：仅 feeding/prediction 写盘；UCG 不写

## 3. Usage 与显式请求

- [x] 3.1 冷启对实际着陆页补报 page-show（喂养或预测）；`onPageChanged` 未触发时仍报
- [x] 3.2 确认深链 / `homePagerRequestProvider.requestPage` 仍可覆盖记忆着陆

## 4. 验收

- [ ] 4.1 手动：停喂养→杀进程→冷启落喂养；停预测→冷启落预测；进 UCG 再杀→冷启回到进 UCG 前的喂养/预测
- [x] 4.2 本变更不改 `app/android/**`；无需 release/proguard 项
