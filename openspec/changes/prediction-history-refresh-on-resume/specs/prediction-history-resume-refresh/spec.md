## ADDED Requirements

### Requirement: Logged-in app resume SHALL refresh feeding surfaces from the home shell
When the App returns to the foreground and the user is logged in, the client MUST orchestrate resume HTTP refresh from the home pager shell (`UcgHomeShell` or equivalent), and MUST NOT depend on the feeding `HomeScreen` being mounted. The resume bundle MUST include: feeding history remote refresh (`homeHistory` bootstrap or documented equivalent), prediction range force reload (`predictionRangeHistory.ensureLoaded(force: true)` or equivalent), care-alert full ensure (`predictionCareAlert` `ensureLoaded(force: true)`, which MUST refresh eligibility and then daily list when qualified), and UCG unread sync (`ucgUnreadSync` or equivalent). Logged-out resume MUST NOT fire that bundle. The bundle MUST obey side-effect HTTP governance (single-flight, failure circuit-break, short-window de-dupe). History WebSocket silent heal MUST remain independent: a ready WS MUST NOT skip the HTTP bundle via early return. The feeding page MUST NOT also run the same history/unread resume refresh (no double fire). 已登录 resume MUST 在主壳刷新喂养历史、预测 range、值得留意 full ensure、UCG unread；MUST NOT 依赖喂养页 mount；WS heal MUST NOT 跳过 HTTP；喂养页 MUST NOT 双打。

#### Scenario: Resume on prediction without feeding mounted
- **WHEN** 用户已登录，冷启后仅停留预测页（喂养页未必曾 mount），将 App 切后台再回前台，且服务端历史在离开期间有更新
- **THEN** 客户端 MUST 仍拉取最新喂养历史与预测 range，使预测卡无需先进入喂养页即可反映更新

#### Scenario: Resume refreshes care-alert full ensure
- **WHEN** 用户已登录且 App resume
- **THEN** 客户端 MUST force ensure 值得留意（含资格；合格时含日列表路径），使未合格进度或合格后内容可反映后台期间变化

#### Scenario: Resume syncs UCG unread from shell
- **WHEN** 用户已登录且 App resume
- **THEN** 客户端 MUST 从主壳触发 UCG unread sync，MUST NOT 仅依赖喂养页 mount 才校准未读计数

#### Scenario: WS ready does not skip HTTP bundle
- **WHEN** 用户已登录、历史 WS 已 ready，且 App resume
- **THEN** 客户端 MUST 仍执行 HTTP resume bundle（历史/range/care/unread），MUST NOT 因 WS ready 早退而跳过

#### Scenario: Logged-out resume skips bundle
- **WHEN** 用户未登录且 App resume
- **THEN** 客户端 MUST NOT 因本要求发起上述 resume HTTP bundle

#### Scenario: Rapid resume is de-duplicated
- **WHEN** 已登录用户在短时间窗内连续触发多次 App resume
- **THEN** resume HTTP bundle MUST 受 short-window 去重或 single-flight 约束，MUST NOT 对每一次 resumed 无合并打满
