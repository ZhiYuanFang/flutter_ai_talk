## ADDED Requirements

### Requirement: Appointment next and last SHALL persist per deviceNo

The client MUST persist appointment **next** (nextAt + remark) and appointment **last** (occurrence at + remark) snapshots to SharedPreferences (or the project’s existing prefs-backed store) keyed by `deviceNo` (e.g. `appointment_next_v1_{deviceNo}` / `appointment_last_v1_{deviceNo}` or a single file with sections). On cold start or process restart, the client MUST hydrate next/last from disk into memory before requiring a successful network ensure, so UI can show the last known values while a silent refresh may still be in flight. Successful network ensure/refresh MUST write back memory and disk. Account wipe / logout / clearLocal for that deviceNo MUST remove these prefs. 预约 next/last MUST 按 deviceNo 落盘；冷启 MUST 先 hydrate；成功网络 MUST 写回；wipe/切号 MUST 清盘。

#### Scenario: Restart shows cached next before network

- **WHEN** 用户上次会话已成功拿到预约 next（及可选 last）并已落盘
- **AND** 进程重启后再次进入预约相关表面
- **THEN** 客户端 MUST 先展示磁盘 hydrate 的 next/last
- **AND** MUST NOT 因内存尚空而表现为「完全无预约」直到网络返回

#### Scenario: Successful network updates disk

- **WHEN** 预约 next 或 last 的网络 ensure/refresh 成功且载荷有效
- **THEN** 客户端 MUST 更新内存状态
- **AND** MUST 将对应快照写入磁盘，供下次冷启 hydrate

#### Scenario: Account wipe clears appointment cache

- **WHEN** 用户触发账号本地擦除或登出清理路径
- **THEN** 客户端 MUST 清除该 deviceNo 下预约 next/last 磁盘缓存（与既有 wipe 约定一致）

### Requirement: Appointment ensure SHALL silently refresh even when memory already has next or last

When appointment next/last ensure runs for a surface that needs freshness (including prediction pull-to-refresh, enter-prediction / cold hydrate follow-up, and **logged-in app resume**), the client MUST still attempt a network refresh rather than permanently skipping HTTP solely because memory already holds a non-null next or last. Cached values MUST remain visible during the refresh. Concurrent ensures MUST be single-flight. Failure MUST keep the last good cache (memory and disk) rather than wiping to empty unless the server explicitly indicates cleared state (`nextAt=0` or empty last). Prefetch / silent-refresh entry points MUST wait until a non-empty `deviceNo` is available (or re-run when it becomes available) and MUST NOT treat an empty-deviceNo early return as a completed network refresh. 内存已有 next/last 时 ensure MUST 仍可静默刷新；失败 MUST 保留上次成功缓存；并发 MUST single-flight；deviceNo 空 MUST NOT 算网刷完成。

#### Scenario: Known next still refreshes on pull

- **WHEN** 内存中已有预约 next
- **AND** 用户触发预测页下拉刷新（或同路径的预约刷新入口）
- **THEN** 客户端 MUST 仍发起预约 next（及约定的 last）网络刷新
- **AND** 刷新完成前 MUST 继续展示已有缓存

#### Scenario: Resume refreshes when prediction not mounted

- **WHEN** 用户已登录、停留喂养页（预测页未必 mount），App resume
- **THEN** 客户端 MUST 仍静默刷新预约 next 与 last

#### Scenario: Empty deviceNo does not complete prefetch

- **WHEN** 预测页预取触发时 deviceNo 仍为空
- **THEN** 客户端 MUST NOT 将本次视为已完成的网络静默刷新
- **AND** 当 deviceNo 随后变为非空时 MUST 再跑静默刷新（或等价重入）

#### Scenario: Refresh failure keeps last good cache

- **WHEN** 静默刷新预约 next/last 网络失败
- **AND** 磁盘或内存已有上次成功快照
- **THEN** 客户端 MUST 保留该快照供 UI 继续展示
- **AND** MUST NOT 因本次失败清空为「无预约」
