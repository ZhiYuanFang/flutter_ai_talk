## 1. UCG push register 防护（P0）

- [x] 1.1 `ucg_providers.dart`：`_syncUcgPushRegistrationInFlight` single-flight（对齐 `_syncUcgUnreadInFlight`）
- [x] 1.2 会话级 `_ucgPushRegisterGaveUp` + 连续失败计数；登出 / `deactivateUcgHomeSession` / `resetUcgHomeSessionState` 清零
- [x] 1.3 `bindTokenRefreshListener`：in-flight 时 ignore；结束后至多一次 deferred refresh（token 与缓存不同）
- [x] 1.4 `UcgPushRegistrationService`：成功 `(channel, token, deviceKey)` 缓存；`registerIfEligible` 身份未变 skip POST；`unregister` 清缓存
- [x] 1.5 失败 / gaveUp 路径 `AppDebugLog`（新 tag 则三联改）；不得裸 `print`

## 2. Home / UCG 挂载补强（P1）

- [x] 2.1 `HomeScreen._onAppLifecycleResumed`：resume 不并行触发 push register；WS resume 与 unread sync 顺序明确（unread 已有 single-flight）
- [x] 2.2 `UcgEnterSquareTab`：移除 `ref.watch(ucgRepositoryProvider)`；角标仍读 `ucgUnreadCountProvider`
- [x] 2.3 `sessionProvider` / `ucgCurrentUserIdProvider` listen 内 push 调用经 single-flight + gaveUp gate

## 3. 仓库副作用 HTTP 审计

- [x] 3.1 grep 清单：`ref.listen` / `Stream.listen` / lifecycle 触发 pangbao·notify HTTP；在 design.md 或本文件 §3 注释表记录「已合规 / 本 change 修复 / 待跟进」
- [x] 3.2 确认 `syncUcgUnreadFromServer`、`SessionController.ensureFreshSession`、`GatewayBootstrapGate` 为合规范例并在 project.md 引用

## 4. 全局工程规范

- [x] 4.1 `openspec/project.md` 新增「副作用 HTTP 治理（强制）」全文
- [x] 4.2 `AGENTS.md` 增加摘要条目 + 指向 project.md
- [x] 4.3 `openspec/project.md`「重要约束（评审检查项）」增加副作用 HTTP 检查行

## 5. iOS 验收（与 ios-post-login-connection-stagger 联合）

- [ ] 5.1 探针 REAL ucg 激活 → 污染检测 ✓（无需 release REAL mounts）
- [ ] 5.2 进 Home → 回探针 version/check + notify ✓
- [ ] 5.3 释放 REAL mounts + pangbao 后再探针仍 ✓；Android 登录 + push 路径 smoke

### §3 审计清单（实现时填写）

| 路径 | 触发源 | 状态 |
|------|--------|------|
| `_syncUcgPushRegistration` | session / wxId listen, activate, token refresh | 已修复（single-flight + gaveUp + cache） |
| `syncUcgUnreadFromServer` | WS ready, resume, activate | 已合规（single-flight） |
| `SessionController.ensureFreshSession` | WS auth, resume | 已合规（`_refreshInFlight`） |
| `GatewayBootstrapGate.ensureLoggedInComplete` | Home 登录 bootstrap | 已合规（gate 单飞） |
| `HomeScreen._onAppLifecycleResumed` | lifecycle resumed | 已修复（await unread，不触发 push） |
| `UcgEnterSquareTab` watch repo | Home 渲染 | 已修复（移除 premature watch） |
| `ColdStartBackgroundSync` | 冷启动 | ios-post-login-connection-stagger 已串行 |
| Logo 下载 | catalog refresh | ios-post-login-connection-stagger 已 defer/abort |
