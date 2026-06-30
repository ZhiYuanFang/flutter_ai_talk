## Context

- **已确认根因（探针 v3）**：Fake WS/HTTP 探针在从未进 Home 时全部通过；REAL `ucgRepositoryProvider` 挂载后污染检测失败；释放 REAL mounts 后恢复。§16–17 已将 UCG 副作用移出 provider 创建路径并 await chat WS ready，但 **`_syncUcgPushRegistration` 仍无 `_syncUcgUnreadInFlight` 同级防护**。
- **重试环机制**：
  1. `activateUcgHomeSession` 或 `sessionProvider` / `ucgCurrentUserIdProvider` listen 调用 `_syncUcgPushRegistration`；
  2. `registerIfEligible` → `POST /push/register` 失败（槽位满 / 网络）；
  3. iOS `registerForRemoteNotifications` 后原生 `onTokenRefresh` → `bindTokenRefreshListener` → 再次 `_syncUcgPushRegistration`；
  4. 多路 `unawaited` 并行，无 single-flight → 同 host 连接槽持续占用。
- **已有良好范例**：`syncUcgUnreadFromServer`（`_syncUcgUnreadInFlight`）、`SessionController.ensureFreshSession`（`_refreshInFlight`）、`GatewayBootstrapGate.ensureLoggedInComplete`（gate 单飞）。
- **约束**：Debug 日志走 `AppDebugLog`/`ApiHttpLog`；不新增 `*_test.dart`；push register 仍经 `UcgApiClient` / 既有 API 路径。

## Goals / Non-Goals

**Goals:**

- push register 路径具备与 unread sync 同级的 **single-flight + 失败熔断 + 自触发 ignore + 成功缓存**。
- iOS 探针：REAL ucg 激活后污染检测 ✓，且**无需** release REAL mounts。
- 将「副作用 HTTP 治理」写入 `openspec/project.md` 与 `AGENTS.md`，作为后续 PR 强制检查项。
- 完成仓库内 listener 触发 HTTP 的**风险审计清单**（至少覆盖 UCG push、Home resume、provider listen）。

**Non-Goals:**

- 不修改 `/push/register` 服务端契约或 gateway 路由。
- 不重做全局 HTTP Client 单例或连接池（属独立 change）。
- 不合并 `ios-post-login-connection-stagger` 全部 stagger 任务；仅处理 push 重试环及直接相关的 premature mount / resume burst。
- 不为所有 HTTP 调用统一抽象框架类（仅规范 + 首个修复范例 + 审计）。

## Decisions

### 1. Single-flight：`Future<void>? _syncUcgPushRegistrationInFlight`

**决策**：在 `ucg_providers.dart` 为 `_syncUcgPushRegistration` 增加与 `_syncUcgUnreadInFlight` 相同模式的 module 级 in-flight Future；并发调用 `await` 同一 run。

**理由**：最小 diff、与现有 unread 模式一致、探针已验证 unread 路径无重试环。

**备选**：在 `UcgPushRegistrationService` 内封装 — 可行，但 session listen 与 activate 路径分散在 providers，统一在 providers 层更易与 `_ucgHomeSessionActive` gate 协作。

### 2. 失败熔断：会话级 `_ucgPushRegisterGaveUp`

**决策**：连续 N 次（建议 2–3）register 失败后，本会话内不再自动重试，直至：登出、`deactivateUcgHomeSession`、或 token **实质变更**（与缓存不同）。

**理由**：避免 iOS 槽位满时无限占连接；与 WS `gaveUp` 语义对齐。

**备选**：指数退避 — 仍可能与其他 HTTP 争抢槽位；熔断 + 显式 reset 更简单。

### 3. 自触发防护：register in-flight 时忽略 `onTokenRefresh`

**决策**：`_syncUcgPushRegistrationInFlight != null` 时，`bindTokenRefreshListener` 回调直接 return；register 完成后再处理**队列中最多一次** pending refresh（若 token 与缓存不同）。

**理由**：打断「register 失败 → APNs 再回调 → 再 register」环；iOS AppDelegate 在 permission 后必发一次 refresh。

### 4. 成功缓存：`(channel, token, deviceKey)` 元组

**决策**：`UcgPushRegistrationService` 内存缓存上次成功 POST 的三元组；`registerIfEligible` 在 token 未变时 skip POST，仍返回 true。

**理由**：满足 spec「token 刷新后重新注册」— 仅 token **变更**时 POST；减少重复 upsert。

### 5. Lifecycle resume 串行化（P1）

**决策**：`HomeScreen._onAppLifecycleResumed` 在 `ensureFreshSession` 之后：**先** history/ucg WS resume（无新增 HTTP），**再** `ucgUnreadSyncProvider`（已有 single-flight），**不得**并行触发 push register（push 仅 activate / token refresh 路径）。

**理由**：resume 当前并行 WS + unread HTTP；push 已 gate 到 activate，resume 不应再 unawaited push。

### 6. 移除 `UcgEnterSquareTab` premature repo watch（P1）

**决策**：删除 `ref.watch(ucgRepositoryProvider)`；未读角标改读 `ucgUnreadCountProvider`（已在 provider 树，不 mount repo）。UCG 会话由 `mountUcgHomeTransportsIfEligible` / 用户进入广场激活。

**理由**：注释「确保登录后未进广场也会初始化 UCG repo」与 §16「provider 创建不自动 push/WS」冲突；premature mount 仍创建 repo 并绑定 token listener。

### 7. 全局规范位置

**决策**：完整条文写入 `openspec/project.md` 新节「副作用 HTTP 治理（强制）」；`AGENTS.md` 增加 4–5 行摘要 + 指向 project.md。

**理由**：与 WebSocket / Debug 日志约定同级；AI 与 PR 评审均须可见。

## Risks / Trade-offs

- **[Risk] 熔断过早导致 push 长期未注册** → 登出/重登、进入广场 re-activate、token 实质变更时 reset gaveUp；Debug 日志记录 gaveUp 原因。
- **[Risk] 成功缓存导致服务端 token 被清但客户端 skip** → 缓存仅进程内；登出 clear；unregister 清 cache；token refresh 必比对。
- **[Risk] 审计遗漏其他 listener HTTP** → tasks 含 grep 清单与「已合规 / 待跟进」表；新功能须对照 project.md。
- **[Trade-off] 不引入通用 `SideEffectHttpGuard` 类** → 重复模式靠规范 + code review；首个范例在 push register。

## Migration Plan

1. 实现 P0 push guard → iOS 探针 REAL ucg → 污染检测。
2. P1 resume + UcgEnterSquareTab → 回归 Home 进出、resume。
3. 更新 project.md / AGENTS.md → 后续 PR 按新检查项评审。
4. 与 `ios-post-login-connection-stagger` 任务 16.4 / 17.4 联合验收后可分别 archive。

## Open Questions

- 熔断次数 N=2 还是 3：实现时以 log 可观测为准，默认 2（与 WS strike 量级接近）。
- 是否需 `[UcgPush]` debug tag：若新增失败/gaveUp 日志，须三联改（见 project.md）。
