## Context

`baby-display-atoms`（L1）已落地；喂养/预测仍各写 `watch(settingsBabyProvider).asData?.value` 再调 `displayBaby*`。方案 B：Riverpod 展示快照，一次 watch 拿齐身份字段。

## Goals / Non-Goals

**Goals:**

- `BabyDisplay.resolve` + `currentBabyProvider` + `babyDisplayProvider`。
- 喂养顶栏、预测顶栏、空历史改用 `babyDisplayProvider`。
- 空态语义仍完全委托 L1。

**Non-Goals:**

- 不改 `settingsBabyProvider` 加载实现；不强迫设置/编辑页放弃 `AsyncValue.when`。
- 不做 L3 自 watch `BabyIdentityAvatar` / 共用 strip。
- 不把身份月龄绑到 `predictionClockProvider`（日历月龄，秒级 clock 无收益且会拖累喂养重建）。

## Decisions

1. **`BabyDisplay` 值对象**  
   字段：`profile`（可空）、`nickname`、`ageText`、`identityLine`、`babyId`、`sex`。工厂/`resolve` 内部只调 L1，保证与纯函数一致。

2. **双 Provider**  
   - `currentBabyProvider` → `BabyProfile?`（`asData?.value`）  
   - `babyDisplayProvider` → `BabyDisplay`（watch current + `DateTime.now()` resolve）  
   需要原始 profile 的调用方可只 watch `currentBabyProvider`。

3. **墙钟即可**  
   身份月龄按完整日历月；预测倒计时继续用自己的 clock。身份快照统一 `DateTime.now()`，避免 family(DateTime) 缓存抖动与喂养误订 clock。

4. **落点**  
   `BabyDisplay` 可放 `baby_age.dart` 旁或同文件；Provider 放 `providers/settings_baby.dart` 或新建 `baby_display_provider.dart`（避免 data 层依赖 riverpod）。

5. **首批迁移范围**  
   与 L1 首批相同三处；设置只读卡保持「待设置」+ 原 async.when。

## Risks / Trade-offs

- [loading 变空态] `asData` 把 loading 压成 null → 短暂「宝宝」空态；与现网喂养/预测行为一致，可接受。  
- [墙钟 vs 预测 clock] 跨午夜极短窗口月龄文案可能差一天 → 可忽略；若将来要测月龄切日再引入可选 now。

## Migration Plan

- 纯客户端重构。回滚：恢复页面内 watch + L1 直调。

## Open Questions

（无）
