## MODIFIED Requirements

### Requirement: Logged-in app resume SHALL refresh feeding surfaces from the home shell

When the App returns to the foreground and the user is logged in, the client MUST orchestrate resume HTTP refresh from the home pager shell (`UcgHomeShell` or equivalent), and MUST NOT depend on the feeding `HomeScreen` being mounted. The resume history path MUST fetch a **rolling 24-hour** window (`now − 24h` through `now`) via history `filter` (or equivalent), **merge** by record id into the shared history pool, and **preserve** local records whose `startTime` is strictly before that window start. The client MUST NOT force a full near-seven-day seed solely because of resume. The resume bundle MUST also sync UCG unread (or equivalent) and MUST **silently refresh appointment next and appointment last** for appointment roots (same silent paths as prediction enter/pull; MUST NOT skip solely because memory already has values; MUST NOT depend on the prediction page being mounted). Appointment-only failure MUST NOT toast and MUST keep last good appointment cache. Logged-out resume MUST NOT fire that bundle. The bundle MUST obey side-effect HTTP governance (single-flight, failure circuit-break, short-window de-dupe). History WebSocket silent heal MUST remain independent: a ready WS MUST NOT skip the HTTP resume refresh via early return. The feeding page MUST NOT also run the same resume HTTP bundle (no double fire). Cold start / explicit seven-day seed paths MUST remain a separate near-seven-day filter and are out of scope for this resume window. Disk/memory history and appointment caches MUST be showable before the resume HTTP completes.

The client MUST NOT require `predictionRangeHistory.ensureLoaded(force: true)` or care-alert full ensure as part of this resume bundle after the unified history pool is the sole near-window source (range/care resume doubles from the pre-pool era are retired).

已登录 resume MUST 在主壳：滚动 24h 历史合并 + UCG unread + 预约 next/last 静默刷新；MUST NOT 因 resume force 近 7 日；MUST NOT 依赖喂养页或预测页 mount；WS heal MUST NOT 跳过 HTTP；预约失败 MUST NOT toast。冷启 7 日种子保持独立。

#### Scenario: Resume merges rolling 24h

- **WHEN** 用户已登录且 App resume，统一池已有更旧于 24h 的记录
- **AND** 滚动 24h filter 成功
- **THEN** 客户端 MUST 将 24h 内远端记录按 id 合并进池
- **AND** MUST 保留合并前已存在、且 startTime 早于窗起点的更旧记录
- **AND** MUST NOT 仅因该 resume 将池替换为仅近 7 日全窗重拉结果

#### Scenario: Resume on prediction without feeding mounted

- **WHEN** 用户已登录，停留预测页（喂养页未必 mount），切后台再回前台且服务端近 24h 有更新
- **THEN** 客户端 MUST 仍执行滚动 24h 历史刷新，使预测无需先进入喂养页即可反映近窗更新

#### Scenario: WS ready does not skip HTTP resume history

- **WHEN** 用户已登录、历史 WS 已 ready，且 App resume
- **THEN** 客户端 MUST 仍执行滚动 24h 历史 HTTP 刷新（及 unread），MUST NOT 因 WS ready 早退跳过

#### Scenario: Logged-out resume skips bundle

- **WHEN** 用户未登录且 App resume
- **THEN** 客户端 MUST NOT 因本要求发起 resume 历史/unread bundle

#### Scenario: Rapid resume is de-duplicated

- **WHEN** 已登录用户在短时间窗内连续触发多次 App resume
- **THEN** resume HTTP MUST 受 short-window 去重或 single-flight 约束

#### Scenario: Cache visible before resume HTTP

- **WHEN** 用户已登录、磁盘或内存已有历史快照，且 App resume
- **THEN** UI MUST 可在滚动 24h HTTP 完成前展示已有历史（含更旧于 24h 的缓存行）

#### Scenario: Resume does not force seven-day range or care-alert

- **WHEN** 用户已登录且 App resume
- **THEN** 客户端 MUST NOT 仅因该 resume 再 force 独立近 7 日预测 range 拉取
- **AND** MUST NOT 仅因该 resume 再跑 care-alert full ensure（若该能力已从产品路径移除则自然不适用）

#### Scenario: Resume silently refreshes appointment next and last

- **WHEN** 用户已登录且 App resume（预测页未必可见）
- **AND** 目录中存在预约根且 deviceNo 可用
- **THEN** 客户端 MUST 发起预约 next 与 last 的静默网络刷新
- **AND** 刷新完成前 MUST 继续展示已有预约缓存（若有）
- **AND** 预约单路失败 MUST NOT 单独 toast

## ADDED Requirements

### Requirement: Cold start SHALL not double-hit seven-day seed in a short window

After a successful near-seven-day history seed for the current session/device, the client MUST NOT immediately run a second full seven-day seed solely because both gateway cold-start sync and the feeding home bootstrap invoke the same cold-start entry. Prefer: after gateway completes ColdStart history seed, HomeScreen MUST NOT call the full ColdStart history path again and MAY only retry empty catalog. 当前会话/设备一次成功近 7 日种子后，MUST NOT 仅因 Gateway 与喂养页冷启入口各调一次而立刻再打满第二次 7 日。

#### Scenario: Gateway then home does not seed twice immediately

- **WHEN** Gateway cold-start 已成功完成近 7 日种子
- **AND** 喂养页随即再次触发同一 ColdStart / bootstrap 历史路径
- **THEN** 客户端 MUST NOT 在无新 force 语义需求时立刻再发第二次近 7 日 filter
