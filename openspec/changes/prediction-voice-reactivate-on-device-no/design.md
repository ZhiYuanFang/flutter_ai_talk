## Context

`LandscapeVoiceController.activate` 在 `deviceNo` 空时写「绑定宝宝…」并 return，且不置 `_active`。`DeviceNoNotifier` 初始为 `AsyncValue.data(null)`，与「已登录未绑」同形；prefs `refresh` 晚于竖屏 binder 首帧 sync 时即误判。`LandscapeVoiceLifecycleBinder` 仅在 orientation / surfaceVisible / 路由覆盖变化时 sync，**不**响应 `deviceNo`。主壳虽 watch dn（小组件），rebuild 也不触发 binder 重 sync。

`defer-mic-until-voice-ball` 已将 lifecycle 改为 soft-check；本变更在其之上补 dn 晚到重试，不回退进表面弹麦权。

## Goals / Non-Goals

**Goals:**

- surface want 期间，`deviceNo` 空→非空时自动补 `activate`（soft-check）。
- 真未绑定仍可展示绑定文案；已绑定冷启不得永久卡在该文案。
- 保持 activate 单飞（`_active` / `_activateInFlight`）。
- 轻量兜底：未激活时点球可再试 activate（dn 已有则进入麦权/唤醒路径）。

**Non-Goals:**

- 不改 `DeviceNoNotifier` 为 loading 三态（面更宽，可另开）。
- 不改麦权 soft-check / 用途框时机。
- 不改 chat WS / KWS 协议。

## Decisions

### D1：在 `LandscapeVoiceController` 内 `ref.listen(deviceNoNotifierProvider)`

- **做法**：controller `build` 时 listen；当 next dn 非空、prev 空/缺失，且「表面仍 want」（用内部 `_surfaceWant` 标志，由 `syncLandscapeVoiceLifecycle` 写入）且 `!_active` 时，`unawaited(activate(ensureMic: softCheck…))`。
- **备选：binder watch dn 再 sync** — binder 是 Widget，可行，但 want/soft 闭包仍散落；listen 放 controller 更靠近 `_active` 门闩。
- **备选：改 DeviceNo 初始 loading** — 治本语义，但全仓 `asData?.value` 假设需审计；本变更不做。

### D2：`syncLandscapeVoiceLifecycle` 记录 `_surfaceWant`

- want=true 时置位并 activate；want=false 时清位并 deactivate。
- listen 回调只在 `_surfaceWant && !_active && dn 非空` 时补激活，避免离表面后误开。

### D3：点球兜底（轻量 B）

- `onListenChipTap`：若 `!_active` 且 dn 已非空，先 `activate(softCheck)`（或 full ensure 若已 micDenied）；若 dn 仍空，保留绑定文案。
- 不替代 D1，只防 listen 漏网。

### D4：空 dn 文案

- 仍可用「绑定宝宝…」；可选短时「准备中…」若可知「尚未首刷」——本变更不引入首刷标志，保持原文案 + 补激活即可。

## Risks / Trade-offs

- **[Risk] listen + lifecycle 双触发** → Mitigation：`activate` 开头 `if (_active) return` + in-flight await。
- **[Risk] 切号 dn A→B** → Mitigation：仅「空→有」补激活；有→有换号由既有 deactivate/wipe/session 路径处理；若需 A→B 重绑可后续加。
- **[Risk] 真未绑定反复 listen** → Mitigation：仅空→非空边沿触发；持续 null 不重试风暴。

## Migration Plan

- 纯客户端；回滚删除 listen / `_surfaceWant` 即可。

## Open Questions

- （无阻塞）
