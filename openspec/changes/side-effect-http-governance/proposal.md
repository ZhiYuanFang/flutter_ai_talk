## Why

`ios-post-login-connection-stagger` 探针二分已确认：挂载 REAL `ucgRepositoryProvider` 后，iOS 对 `pangbao.cuplay.top` 的 HTTP 被持续占用，污染检测失败；根因之一是 `POST /push/register` 在失败时**无 in-flight 去重、无失败熔断、无自触发防护**，与 iOS `onTokenRefresh` 形成重试环，占满同 host 连接槽。同类风险（Riverpod `listen` / 原生回调 / lifecycle 触发的副作用 HTTP）在仓库内缺乏统一工程约束，易在后续功能中复现。

## What Changes

- **P0**：为 UCG push register 补齐 **single-flight**、**会话级失败熔断**、**register 进行中忽略 token refresh**、**成功 token 缓存跳过重复 POST**（对齐已有 `_syncUcgUnreadInFlight` 模式）。
- **P1**：`HomeScreen._onAppLifecycleResumed` 将 WS 重连与 UCG unread 同步改为**串行或受 gate 约束**，避免 resume 突发并行 HTTP。
- **P1**：移除 `UcgEnterSquareTab` 对 `ucgRepositoryProvider` 的 premature `watch`，UCG 会话仅由 `activateUcgHomeSession` / 进入广场路径激活。
- **全局规范**：在 `openspec/project.md` 新增「副作用 HTTP 治理」强制约定；`AGENTS.md` 增加摘要；PR 评审检查项纳入该条。
- **仓库审计**：扫描 `ref.listen` / `Stream.listen` / lifecycle 中触发的 pangbao/notify HTTP，列出需对齐或已合规项（文档化于 design / tasks）。

## Capabilities

### New Capabilities

- `side-effect-http-governance`：客户端在 listener / 回调 / lifecycle 路径触发 HTTP 时的 in-flight 去重、失败熔断、自触发防护与成功缓存等全局治理要求。

### Modified Capabilities

- `ucg-push-token-registration`：在既有 register/unregister 语义上，补充失败不得无限重试、token refresh 与 register 并发/自触发约束、成功 upsert 后幂等跳过等行为要求。

## Impact

- **代码**：`app/lib/ucg/providers/ucg_providers.dart`、`app/lib/ucg/push/ucg_push_registration_service.dart`、`app/lib/ui/home_screen.dart`、`app/lib/ucg/ui/ucg_enter_square_tab.dart`；可能涉及 `app/lib/ucg/push/ucg_push_native_mobile.dart`（token 事件过滤）。
- **文档**：`openspec/project.md`、`AGENTS.md`。
- **关联变更**：与 `ios-post-login-connection-stagger` §16–17 衔接；本 change 聚焦 push register 重试环与全局防复发规范，不重复 WS stagger 工作。
- **API**：无后端契约变更；客户端对 `/push/register` 调用频率与并发行为变化。
- **平台**：iOS 为首要验证目标；Android 行为不得回归。
