## Context

`UcgHomeShell` 今日写死 `PageController(initialPage: HomePagerPage.prediction)`，且 `_predictionEverMounted = true`。基线多处称「默认着陆预测」。用户希望记忆喂养/预测习惯页；**UCG 不记**。

## Goals / Non-Goals

**Goals:**

- 在喂养↔预测切换时持久化 lastPage。
- 冷启 `/home` 用记忆页作 `initialPage`；无记忆回落预测。
- UCG 不写、不作为冷启着陆。
- 显式 `requestPage` / 深链优先于记忆。
- 冷启 page-show 跟真实着陆页。

**Non-Goals:**

- 不记忆 UCG Tab 内子页。
- 不改 pager 页序/数量。
- 不把本能力并进 `predict-history-resume-and-appointment-cache`。

## Decisions

### D1：只记 feeding | prediction

- 合法值：`0` / `1`（或字符串 `feeding` / `prediction`）。
- 进入 UCG：**不写** lastPage（保留进入 UCG 前的喂养/预测记忆）。
- 冷启若读到非法或 UCG：回落 prediction。

### D2：本机全局 prefs（不按 deviceNo）

- 键如 `home_pager_last_page_v1`。
- 理由：着陆习惯偏本机 UI，与宝宝切换弱相关；实现简单。
- wipe/登出：**可不清除**（换号仍可沿用本机习惯）；若产品后续要按账号隔离再升版本键。

### D3：同步读，避免闪页

- 壳构造 `PageController` 前用 `SharedPreferences.getInstance()` 已缓存实例同步 `getInt`/`getString`；若首启 prefs 未就绪，允许默认 prediction（可接受一次）。
- **禁止**先以 prediction 建 controller 再 `jumpToPage` 喂养（闪一下）。

### D4：写入时机

- `_onPageChanged` 当 index 为 feeding 或 prediction 时写盘（可 fire-and-forget）。
- `animateToPage` 完成后的 index 同步路径同样覆盖。

### D5：与 requestPage / 深链

- 冷启仅决定 **无待处理请求时的 initialPage**。
- 挂载后若存在 `homePagerRequestProvider` 或路由深链请求，仍按现网 listen 切页，可覆盖记忆着陆。

### D6：usage

- 冷启后若 `onPageChanged` 未因 initial 触发，壳 MUST 对实际 `initialPage` 补报对应 show（喂养或预测），与今日「冷启落预测也要报」同构、泛化到着陆页。

## Risks / Trade-offs

- **[Risk] 首启 prefs 未 ready** → Mitigation：回落 prediction。
- **[Risk] 停在 UCG 杀进程** → Mitigation：不记 UCG，冷启回到进入 UCG 前的喂养/预测。
- **[Risk] 换号沿用他人习惯** → Mitigation：本机全局可接受；必要时后续按账号键。

## Migration Plan

- 无旧键：行为等于今日默认预测。
- 回滚：删 store 读，写死 prediction。

## Open Questions

- （无阻塞）wipe 是否清 lastPage：默认**不清**。
