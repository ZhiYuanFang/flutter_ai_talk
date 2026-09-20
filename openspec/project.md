# 项目上下文

## 项目目标

胖宝（`pangbao_app`）Flutter 客户端，覆盖 iOS / Android / Web。业务含喂养历史、UCG 社交、胖宝诊疗、设备登录等。后端联调见兄弟仓 `go_ai_talk`。

## 技术栈

- Flutter / Dart（Riverpod、go_router）
- Android：Kotlin、`china_push`（厂商通道）、R8 / ProGuard
- iOS：APNs、Xcode 签名与 TestFlight
- OpenSpec（变更提案、设计、任务与规格管理）

## 项目约定

### 文档语言约定（强制）

- 所有 OpenSpec 变更下的 Markdown 制品（`proposal.md`、`design.md`、`tasks.md`、`specs/**/*.md`）的正文、章节标题、需求描述、场景、任务说明 **必须** 使用简体中文撰写。
- 可保留必要的技术专有名词（如 Flutter、SSE、WebView、OAuth、App Store、DTO、API 等）及代码标识符（类名、包名、路由名等）原文。
- 规范文档中的需求表述以中文为主，使用「必须 / 不得」等明确语态；场景建议使用「当……则……」结构。
- OpenSpec 校验器要求每条 `### Requirement` 正文中仍须出现英文 **SHALL** 或 **MUST**（建议首行用一句英文规范性摘要，后附中文细则）。

### OpenSpec 基线参考约定（强制）

- 后续 AI 发起任何新变更前，**必须**先读取并对照 **`openspec/specs/v2.1.2.md`**（v2.1.2 合并基线规格），再生成 proposal / design / tasks。
- 若本次需求涉及已有 capability，必须在 proposal 中明确标注复用/变更了哪些已有 spec 边界；禁止脱离历史 spec 直接重写同类能力。
- AI 在实现阶段（apply）必须以 v2.1.2 基线中的 Requirement / Scenario 作为验收约束；若实现与基线冲突，需先更新变更规格再改代码。
- 若变更涉及**用户可见行为、对外 API/契约、兼容性或安全语义**的调整，须在 OpenSpec 制品中落到明确的 **`### Requirement`** 与 **`#### Scenario`**（含 `changes/<name>/specs/**` 内 ADDED/MODIFIED delta）；PR 说明、任务勾选理由或评审记录中应能一句话指回对应能力名与需求标题，禁止「只改代码、规格悬空」。

### 测试文件约定（强制）

- 在实现产品需求、OpenSpec 任务或日常功能开发时，**不要**新建、拆分或补充 `**/test/**` 下的 `*_test.dart` 等测试文件，也**不要**为通过校验而临时加测试桩。
- **例外**：用户在本轮对话中**明确**要求编写、修改或恢复测试时，再动测试代码。
- 验证以说明为主（如本地 `flutter run`、手工路径、`flutter build apk --release`）；若任务文案写「写测试」，应先请用户确认是否仍要测试，再执行。

### Debug 日志白名单（强制）

- `app/lib/**` 内 **禁止** 为 Debug 诊断使用裸 `debugPrint` / `print`。
- **唯一出口**：`ApiHttpLog`（`[ApiHttp]`）、`AppDebugLog.*`（`[UcgFeed]`、`[UcgLocation]`、`[UcgVideo]`、`[UcgCompose]`、`[UcgPlay]` 等）。
- 新增 tag 时 **同一 PR 三联改**：
  1. `app/lib/api/app_debug_log.dart` 增加方法，格式 `[Tag] ISO8601 message`
  2. `app/scripts/logcat_api_http.ps1` 的 `$Tags` 数组
  3. `app/README.md` Debug 表格
- 失败路径 **不得** `catch (_)` 静默吞错；须 `AppDebugLog` / `ApiHttpLog` 记录 `err=`（可截断，勿打 token/完整本地路径）。
- Release 包行为不变；日志仅 `kDebugMode`。

### WebSocket 韧性传输（强制）

- 所有**需鉴权**的业务 WebSocket（喂养历史、UCG 聊天、胖宝诊疗等）**必须**经 `ResilientWebSocketClient` + `WsConnectionConfig` 建连，禁止在 feature 内手写 `WebSocketChannel.connect`、固定间隔重连、自管 ping/pong。
- 设备维度通道（history、clinic）的 `prepareToken` **必须**调用 `prepareDeviceWsConnectContext`；鉴权 error 帧 **必须**经 `handleWsAuthOrQuotaError`（refresh in-flight 不弹 UI → silent refresh → hard 失效才登录引导）。
- **`shouldConnect` / `prepareToken` 失败时**传输层 **必须**自动前置条件重试（`ResilientWebSocketClient._schedulePreconditionRetry`）；业务层 **不得**依赖仅 token 轮换才 reconnect。新通道 **应**使用 `bindAuthenticatedWsSession` 在 refresh 结束后 reconnect。
- 新增业务 WS 通道前 **须** OpenSpec change（含 `ws-transport-governance` 或等价 spec delta），PR 说明指回能力名与 Requirement。
- **例外（须文档化）**：**语音 ASR**（`/voice/asr/ws`）无 access token 鉴权，可独立 `VoiceAsrWsClient`；不得复制为其它业务通道模板。
- **参考**：`app/lib/network/resilient_websocket_client.dart`、`app/lib/network/ws_connect_context.dart`、`app/lib/network/ws_auth_error_handler.dart`；架构说明见 `app/README.md`「WebSocket 架构」。
- **禁止**：未经 OpenSpec 授权，在 `app/lib/**` 新增并行 WS 传输实现（含「临时」3s 重连、裸 token getter 首帧 auth）。

### Android Release / R8（强制）

- 改动 `app/android/**` 原生代码、Gradle 依赖、本地 AAR/JAR、`AndroidManifest.xml` 注册组件，或新增继承厂商 SDK 的 Kotlin/Java 类时，合并前 **必须**本地验证 `flutter build apk --release`（或 `flutter build appbundle --release`）通过。
- 新增或升级第三方 Android SDK（如 HMS、MiPush AAR）时，**必须**同步更新 `app/android/app/proguard-rules.pro`：
  - 厂商文档要求的 `-keep`
  - R8 报 Missing class 时，从 `app/build/app/outputs/mapping/release/missing_rules.txt` 复制 `-dontwarn`（附注释说明来源 SDK）
  - 新增 `Service` / `Receiver` 等组件须 `-keep` 对应类
- `-dontwarn` **仅**用于可选/反射/厂商 ROM 专有类（如 HMS 的 EMUI `BuildEx`、HiAnalytics）；不得用 `-dontwarn` 掩盖本仓库实际依赖的缺失类（应 `-keep` 或补依赖）。
- **禁止**：仅 `flutter run` debug 验证就合并 Android 原生改动。
- **参考**：`app/android/app/proguard-rules.pro`、`app/android/build.gradle.kts`（子模块 `compileSdkVersion` 兜底）、`app/README.md`「打包与发布 → Android」。

### 主题色约定（强制）

- 业务 UI（`app/lib/ui/**`、`app/lib/ucg/**`）随主题变化的颜色 **必须** 经语义原子入口 **`AppColor.*`**（或 `AppVisualTokens` 成对字段）取色；组件 **不得** 为拼色读取 `isDarkShell` / 自算 alpha 白叠。
- 角色分离：**modal**（Dialog/软引导）≠ **contentCard**（历史浅卡等）≠ **panelGlass**（页内 tip/留意/预测卡 chrome、**UCG 广场/辩论卡外壳**）；暗壳 modal/panelGlass **必须** 为暗/主题色浮层 + 配对浅字，**禁止** 近白 contentCard 起笔或浅底配 `onShell` 白字。
- 辩论左右侧类别色、VS chip/描边等 **必须** 经 `AppColor.debate*` 原子；业务 **不得** 内联马卡龙 `Color(0x…)`。
- **禁止** 用 `Colors.black54`、固定灰阶 hex、或不当的 `Colors.white` 作为常规正文/次要按钮前景。
- 实心主色按钮字色 **必须** 用 `AppColor.onPrimary` / `colorScheme.onPrimary`。
- **例外**（须注释标明）：事件品牌 `colorHex`、媒体沉浸遮罩（`AppColor.mediaScrim` / `onMediaScrim`）、第三方 SDK 不可控色。
- **参考**：`app/lib/theme/app_color.dart`、`app/lib/theme/app_visual_tokens.dart`；变更见 `theme-semantic-atoms` / `ucg-panel-glass-atoms`。

### 弹框 TextEditingController / FocusNode（强制）

凡经 `showDialog`、`showGlassDialog`、`showModalBottomSheet` 或等价路由展示、且内含由弹层拥有的文本输入时：

- **MUST**：`TextEditingController`（以及由该弹层创建的 `FocusNode`，若有）由弹层子树的 `State` 创建，并在该 `State.dispose` 中释放；或仅在路由**完全卸载**后再释放。
- **MUST NOT**：在 `await showDialog` / `showGlassDialog` / `showModalBottomSheet` 返回后、退场动画仍可能 rebuild 输入控件时，立即 `dispose` 外层持有的 controller（典型断言：`TextEditingController was used after being disposed`）。
- **推荐**：需要回传文本时，在 `Navigator.pop` 前读出并 `pop(result)`，勿依赖 await 后再读已 dispose 的 controller。
- **参考**：`app/lib/ui/widgets/app_glass_overlay.dart` 的 `_GlassTextConfirmDialogBody`；开通邀请码见 `feature_unlock_hub_screen.dart` 的 `_InviteCodeDialogBody`。
- **OpenSpec**：capability `dialog-text-controller-lifecycle`（change `fix-dialog-text-controller-lifecycle`）。

### 副作用 HTTP 治理（强制）

当 HTTP 请求由 **Riverpod `ref.listen`、原生/SDK 回调、`Stream.listen`、App lifecycle** 等**非用户直接点击**路径触发（下称「副作用 HTTP」）时，**必须**满足下列防护，避免 iOS 等同 host 连接槽被重试环占满（典型：`POST /push/register` 失败 → APNs `onTokenRefresh` → 再 register）。

1. **Single-flight（in-flight 去重）**  
   同一逻辑操作的并发触发 **必须** 合并为单次 in-flight `Future`；后续调用 **必须** `await` 该 Future，**不得** `unawaited` 并行重复建连。  
   **范例**：`syncUcgUnreadFromServer`（`_syncUcgUnreadInFlight`）、`SessionController.ensureFreshSession`（`_refreshInFlight`）、`GatewayBootstrapGate.ensureLoggedInComplete`。

2. **失败熔断（circuit-breaker）**  
   同一会话内连续失败达到阈值后，**必须**停止该操作的自动重试，直至 reset 条件：登出、显式 session/transport deactivate、或输入**实质变更**（如新 push token）。  
   **禁止** 无 reset 条件下的无限重试环。

3. **自触发防护**  
   若原生/SDK 回调可能由当前 HTTP 操作本身触发（如 register 过程中 `registerForRemoteNotifications` → `onTokenRefresh`），在该操作 **in-flight 期间必须 ignore** 回调；完成后 **最多** 处理一次 deferred 事件（且仅当输入实质变更）。

4. **成功缓存（幂等跳过）**  
   成功 POST 后 **应** 缓存稳定请求身份（如 push 的 `channel + token + deviceKey`）；身份未变时 **必须** 跳过重复 POST；登出/unregister **必须** 清缓存。

5. **Provider 创建 vs 会话激活**  
   全局 Riverpod provider 的 `create` / `build` **不得** 自动发起副作用 HTTP（push register、未读校准、WS 建连等）；**必须** 由显式 session 激活（如 `activateUcgHomeSession`、`GatewayBootstrapGate`）或用户动作触发。Widget 为读 derived state **不得** `watch` 会挂载副作用 transport 的 provider（例：`UcgEnterSquareTab` 不得 premature `watch(ucgRepositoryProvider)`）。

6. **OpenSpec**  
   新增或修改 listener 触发的 pangbao/notify HTTP **须** 在 change spec 中落到 Requirement/Scenario，或引用 capability `side-effect-http-governance`。

- **参考**：`openspec/changes/side-effect-http-governance/`、`app/lib/ucg/providers/ucg_providers.dart`（unread single-flight 范例）。
- **禁止**：在 `ref.listen` / token 回调中 `unawaited` 重复 POST 且无 in-flight 去重与失败熔断。

### dynamic Ref / WidgetRef 读 AsyncValue（强制）

接受 **`dynamic ref`**（为兼容 `Ref` 与 `WidgetRef`）的顶层函数中，`ref.read(...)` 的静态类型为 `dynamic`，**不得**对结果直接链式调用依赖静态类型解析的 API。

- **MUST NOT**：对 `ref.read(someAsyncProvider)` 的结果直接写 `.asData` / 其它仅挂在 `AsyncValue` 静态类型上的成员（运行时对象常为 `AsyncData`，dynamic 派发会 `NoSuchMethodError: ... has no instance getter 'asData'`，且若抛在 `try` 外会变成 Unhandled Exception、副作用 HTTP 静默丢失）。
- **MUST** 先收成静态类型，任选其一：
  1. **显式转型**：`final v = ref.read(...) as AsyncValue<T>;` 再用 `v.asData` / `v.value` / `v.valueOrNull`。
  2. **先取 `ProviderContainer`**：再 `container.read(...)`（恢复静态类型；范例 `home_widget_sync.dart` 的 `_widgetSyncContainer`）。
- **Typed `Ref` / `WidgetRef`**（非 `dynamic`）上可直接 `.asData`，编译器已绑定 `AsyncValue`。
- **同理**：`dynamic` 上读非 `AsyncValue` 的强类型结果时，若后续调用也依赖静态类型，**应** `as ConcreteType`（如 `as bool`、`as ClinicWsClient`）。
- **参考**：`clinic_ws_provider.dart`（`companionClinicWsEligible`）、`app_notification_preference_provider.dart`（`onAppResumeNotificationSync` 注释）、`predict_imminent_sync_provider.dart`、`home_widget_sync.dart`。
- **禁止**：在 `dynamic ref` 辅助函数里复制「Typed Ref 上可直接 `.asData`」的写法而不转型。

### AI 思考展示组件（强制）

凡以**可纵向滚动区域**展示 agent **流式**或**展开后完整**思考正文的 UI：

- **MUST** 使用共享组件 `AiThinkingPane`（`app/lib/ui/widgets/ai_thinking_pane.dart`，或该路径下唯一公开等价物）。
- **MUST**：`text` 增长时默认跟滚到底；用户上翻超过离底阈值后暂停跟滚，并在底部悬停回底控件；**仅**点击该控件恢复跟滚（用户自行滑回近底 **不得** 自动恢复）。
- **MUST**：回底控件主色优先为调用方功能/强调色；未传则用 `ColorScheme.primary`；图标/文案须可读对比。
- **MUST NOT** 在 feature 内再实现平行的思考跟滚 / 回底按钮逻辑。
- **不适用**：非滚动表面（如单行语音字幕、纯占位「正在思考…」）；胖宝诊疗**折叠尾部窗口**仍按 `pangbao-clinic-thinking-fold` 用固定高度尾部对齐，折叠态不得用 `jumpTo` 跟流。
- **参考**：capability `ai-thinking-pane`；接入面含喂养记录分析、成长轨迹、诊疗流式/展开态。

### OpenSpec 归档约定（强制）

- 执行 **`/opsx-archive`** 或 **`openspec-archive-change` skill** 时，合并成功后 **必须**带 **`--remove-changes`** 调用 `scripts/sync_specs_to_version.py`。
- **默认删除** `openspec/changes/*` 下各 change 目录（跳过 `archive/` 若存在）；**不**创建 `openspec/changes/archive/` dated 目录。
- 用户**显式**要求保留 change 目录时（如 `--keep-changes`、口头「不要删 change」），才省略 `--remove-changes`。
- 合并前仍可用 `openspec list --json` 警告 in-progress change，**不阻塞**合并（除非用户要求仅合并 complete）。
- 收版后 **必须**更新本文件「OpenSpec 基线参考约定」中的版本号（如 `v2.1.2` → 新版本）。
- 合并完成后摘要须说明：**Changes removed: yes**（删除数量）或 **no**（用户要求保留）。
- 所有新增需求涉及代码，必须补全每行代码的中文注释，解释此代码的业务场景。

## 重要约束（评审检查项）

- 是否引用并遵循 **`openspec/specs/v2.1.2.md`** 基线；行为变更是否可追溯到 Requirement / Scenario。
- 是否存在「只改代码、规格悬空」。
- **WebSocket**：新鉴权通道是否走 `ResilientWebSocketClient`；是否未经 OpenSpec 新增手写 WS 传输。
- **Debug 日志**：是否引入裸 `debugPrint`/`print`；新 tag 是否三联改。
- **Android 原生**：是否已 release 构建通过；`proguard-rules.pro` 是否按需更新。
- **测试文件**：是否未经用户明确要求而新增 `*_test.dart`。
- **副作用 HTTP**：listener/回调/lifecycle 触发的 HTTP 是否有 single-flight、失败熔断、自触发 ignore、成功缓存；provider 创建是否误发副作用 HTTP。
- **dynamic ref**：接受 `dynamic ref` 的函数是否对 `ref.read(AsyncValue…)` 直接 `.asData`（须先 `as AsyncValue<T>` 或经 `ProviderContainer`）。
- **弹框输入**：带 TextField 的 dialog/sheet 是否在 await 返回后过早 dispose `TextEditingController`（须 State 持有，见「弹框 TextEditingController / FocusNode」）。
- **AI 思考展示**：可滚动思考正文是否绕过 `AiThinkingPane` 自建跟滚；近底是否误自动恢复 follow（须仅按钮恢复）。
- **主题色**：业务 UI 是否绕过 `colorScheme`/`AppVisualTokens` 硬编码浅色玻璃白或灰阶字；暗壳是否出现突兀白底卡片。
- **归档**：收版是否默认 `--remove-changes`；`project.md` 基线版本是否已更新。
