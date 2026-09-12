## Context

`vipStatusProvider` 为 `AsyncNotifier`：首次 `watch`/`build` 才拉 `GET /cash/app/api/vip/status`。消费方普遍 `valueOrNull?.isVip == true`，loading/失败 → 假非 VIP。care-alert ensure 在 VIP 未就绪时按未开通 skip daily，无「VIP 变真再 ensure」。预测页 build 内 `featureCatalog.ensureLoaded()` 同步写 state，Riverpod debug 断言失败。探索结论：不得用 Splash await 拉长启动；不得只在预测页生命周期抄 await（后续功能会再复制一套）；应 **共享 settle API + 副作用门闸约定**。

约束：`openspec/project.md` 副作用 HTTP（single-flight、create 不乱打）、Splash 不堵远端业务、`commercial-ucg-feature-unlock` 的 `unlocked || isVip` 模型不变。

## Goals / Non-Goals

**Goals:**

- 一处 `ensureVipSettled`（single-flight），凡副作用路径读 `isVip` 并分支 HTTP/跳过前 MUST await。
- 后续新增 VIP 相关判断 **MUST** 遵循同一规则（写入规格，便于实现与评审）。
- care-alert ensure 接入该规则；删预测页 build 内 catalog ensure。
- 可选登录 Gate 预热 VIP，缩短进预测时的 await。
- 启动遮罩时长不因 VIP 增加。

**Non-Goals:**

- 不改 VIP HTTP 契约；不引入 `cash/internal/.../access`。
- 不把 UCG 入场改为受 `isVip` 覆盖。
- 不在本期强制落地完整三态 UI（unknown/vip/nonVip）展示体系（可选后续）；本期以 settle await + fail-closed（失败仍非 VIP）为主。
- 不新建 `**/test/**`。
- 不把 VIP await 绑进 `_runColdStart` / 品牌遮罩。

## Decisions

### D1：共享 `ensureVipSettled`，而非按页 await

- **选**：`VipStatusController`（或同文件顶层函数）提供 `Future<CashVipStatus?> ensureSettled({bool force = false})`：未登录返回 null；已有 `AsyncData` 且非 force 则返回现值；若 in-flight 则 await 同一 Future；否则触发 load/refresh（single-flight）。
- **不选**：仅 `_onEnterPredictionPage` await —— 新功能仍要各写一套。
- **不选**：Splash await —— 拉长启动。

### D2：规则落在「副作用 ensure / 业务门闸」，UI 只 watch

- Widget `build` / `initState` **不得** 为读 derived 状态而同步 `state=`；UI 继续 `watch(vipStatusProvider)`。
- 读 `isVip` 并决定「是否打 daily / 是否 skip / 是否按 VIP 全开」的 **Notifier ensure / 非点击副作用** MUST 先 `await ensureVipSettled()`。
- 用户点击触发的 refresh（开通中心、购买回流）可继续显式 `refresh()`。

### D3：care-alert 为首个强制接入点

- 在 `PredictionCareAlertNotifier._ensureImpl` 中，于 `isFeatureEffectivelyUnlocked(..., isVip:)` 之前 `await ensureVipSettled()`，再用 settled 结果算 `isVip`。
- 预测槽位闸等同步 UI 路径：本期以 watch 重建为主；若仍存在「点击瞬间 VIP 未 settled」误拦，可在 `_requestForecastToggle` 入口 await（任务可选）。

### D4：删除 build 内 catalog ensure

- 壳层 `_onEnterPredictionPage` 已 `featureCatalog.ensureLoaded()`；删除 `SmartPredictionScreen` 约 L525 的 `unawaited(...ensureLoaded())`。
- **不** 再挪到该 Screen 的 initState（避免重复 kick）。

### D5：Gate 预热（可选但推荐）

- 在 `GatewayBootstrapGate._run` 或 `ColdStartBackgroundSync` 已登录串行链末尾 **kick**（`unawaited`/`ensureSettled` 不阻塞 `_loggedInComplete` 标记，或短 await 串入——优先 kick 以免拖历史 WS）。
- 目的：进预测时 care-alert await 常为 0 等待。

### D6：失败语义保持 fail-closed

- `ensureVipSettled` 失败仍返回 null / 非 VIP（与现 `_load` catch 一致）。
- 不在本期改产品文案为「权益未知」。

## Risks / Trade-offs

- [care-alert 首屏多一次 VIP await] → Gate 预热降低；single-flight 与 catalog 并行时注意 iOS 连接槽（Gate 串行惯例优先 kick）。
- [实现者漏用 ensureVipSettled] → 规格 + tasks 写明「后续 VIP 门闸 MUST」；code review 清单。
- [AsyncNotifier build 仍会在首次 watch 时自动 HTTP] → 与现网一致；settle API 合并 in-flight，不额外打爆。
- [仅改 care-alert、槽位仍瞬时误拦] → 可选任务补 toggle await；UI rebuild 通常可自愈。

## Migration Plan

1. 实现 `ensureVipSettled` + care-alert 接入 + 删 L525。
2. 可选 Gate kick。
3. 手工：冷启 VIP 账号、catalog 未单独开通值得留意 → 应拉 daily / 不永久「去开通」；确认无 build provider 断言；Splash 时长无明显增加。
4. 回滚：git revert。

## Open Questions

- Gate 预热用 kick 还是短 await：默认 **kick**（不挡 `_loggedInComplete`）。
- 预测开关是否本期必 await：默认 **可选**，优先 care-alert。
