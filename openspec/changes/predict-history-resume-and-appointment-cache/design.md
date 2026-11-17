## Context

统一池后：冷启 `seedSevenDayHistory(force)`；resume `bootstrap` 再 force 7 日；Gateway 与 HomeScreen 可连打两次 ColdStart。预测卡 `lastAt = latest-by-event ?? 窗内 ?? tip`。下拉 = 7 日 + latest-by-event。预约 next/last 仅内存，`isKnown` 跳过网络。

## Goals / Non-Goals

**Goals:**

- 冷启 7 日；resume / 预测下拉历史增量用滚动 24h 合并。
- 冷启短窗不双打 7 日。
- 非预约卡上一次以历史池同桶最新为准；预测继续 watch 池。
- 预约 next/last：展示只认专用缓存；进预测 / 下拉 / **resume** 静默 API 写回。
- 下拉：24h + 预约 last/next 静默；去掉 latest-by-event 展示主路径与下拉必打。
- 预约 prefs 按 deviceNo；wipe 清理；prefetch 等 deviceNo。

**Non-Goals:**

- 不改 Go API。
- 不改亲和算法门槛本身。
- 不恢复间隔回忆种子。
- 不强制删 `latest-by-event` 代码文件（可停展示/下拉调用；post-mutation 若仍调用可降级或保留后台）。

## Decisions

### D1：滚动 24h（非自然日今天）

- `start = now − 24h`，`end = now`，一次 `filter`，`preserveOlderOutsideWindow` 保留 `startTime < start` 的本地行。
- 弃用「仅今日 00:00」以避免跨夜漏记。

### D2：resume / 下拉共用 `refreshRollingWindow`；冷启仍 `seedSevenDay`

- `homeHistory.bootstrap()` 冷启路径保持 7 日；resume bundle 改调 24h API，不再 `bootstrap()` 整段 force 7 日。
- 预测下拉历史支路同 24h（与 resume 一致）。

### D2b：resume 包含预约静默刷新

```
resume HTTP bundle:
  并行：refreshRolling24h + ucgUnread + refreshAppointmentNextAll + refreshAppointmentLastAll
  预约失败不 toast、不清空缓存；不依赖预测页 mount
```

### D3：ColdStart 二次 run

- `ColdStartBackgroundSync`：成功后短窗（如 60s）内再 `run` 跳过历史种子；或 HomeScreen `_bootstrapHomeData` 在 gateway 已完成后不再二次 `run` 历史部分。优先：**gateway 完成后 HomeScreen 不再调用完整 ColdStart**，只补 catalog 空重试。

### D4：非预约上一次主源

```
非预约 lastAt = 窗内同桶最新真发生 ?? tip
（去掉 latest-by-event 优先）
```

- 有 `prediction.eventId` 仍同桶；无 pred 用根。

### D4b：预约 next/last 对称（只认缓存）

```
预约下一次展示 = appointmentNextCache（hydrate 先出）→ 静默 GET 写回
预约上一次展示 = appointmentLastCache（hydrate 先出）→ 静默不限窗 filter 写回
```

- 预约「上一次」MUST NOT 以统一历史池为展示主源（避免 7 日窗与不限窗双源）。
- MUST NOT 用 `appointment_next` 当 last。

### D5：预约持久化与 deviceNo

- prefs/json：`appointment_next_v1_{deviceNo}`、`appointment_last_v1_{deviceNo}`。
- 进预测：hydrate → 展示；再 `refreshSilent`（已知也打，single-flight）。
- prefetch FutureProvider MUST `watch` deviceNo（或等价）：dn 空时不标「网刷完成」，dn 就绪后重跑。
- wipe / clearLocal deviceNo：remove。

### D6：下拉包

```
onRefresh:
  并行：refreshRolling24h(history) + refreshAppointmentNextAll + refreshAppointmentLastAll
  await 后 RefreshIndicator 结束
  历史失败 → 失败 toast；预约单路失败不挡指示器、不强制失败 toast
```

预测重算：历史 / 预约 cache provider 更新后自动发生。

## Risks / Trade-offs

- **[Risk] 24h 扫不到更旧服务端删除** → Mitigation：WS + 冷启 7 日。
- **[Risk] 预约 last 与池双源** → Mitigation：**展示只认预约 last 缓存**（D4b）。
- **[Risk] prefetch 空 deviceNo 早退** → Mitigation：watch deviceNo 重跑。
- **[Risk] post-mutation 仍打 latest-by-event** → Mitigation：可保留后台同步但不驱动卡面。

## Migration Plan

- 旧 latest-by-event 缓存可忽略。
- 预约无旧盘文件则首次仍网拉。
- 回滚：resume/下拉恢复 bootstrap 7 日；last 恢复 API 优先。

## Open Questions

- （无阻塞）post-mutation 是否本变更内去掉 latest-by-event：默认**停止作为展示主源**；管线内调用可留，tasks 标明可选清理。
