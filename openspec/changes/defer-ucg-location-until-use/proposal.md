## Why

当前 `/home` 使用 `PageView(children: …)` 在冷启动时即构建 UCG 壳与广场 Tab，`UcgSquareTab` 在 `initState` 拉 Feed 并调用 `tryGetCurrentCoords()`，导致用户仅使用喂养主页时也会弹出定位权限。产品已支持基于 lat/lng 的动态距离展示，但权限申请时机、拒绝后体验及 App Store 隐私申报仍与 v2.0.2 基线（「不收集 GPS」）不一致，需要在用户真正使用 UCG 相关能力时再申请，并统一规格与提审材料。

## What Changes

- **延迟挂载 UCG 模块**：冷启动默认停留在喂养页时，不得构建 `UcgShell` 或触发广场 Feed 首屏加载；用户首次进入 UCG 广场（横滑或「进入广场」）后再挂载并加载。
- **按需申请定位并说明用途**：在拉取 UCG 动态列表、发布/更新 UCG 帖子（含 compose 与喂养历史「同步广场」保存）前，先判断权限；未授权时以 App 内说明告知「用于展示动态与你的距离」，再请求系统定位；拒绝后仍允许无坐标降级调用 API。
- **Session 内拒绝策略**：同一次 App 进程内用户拒绝后不得反复调用系统权限弹窗；再次进入广场时展示「去设置」入口，不阻塞 Feed。
- **规格与合规对齐**：MODIFIED `ucg-square-feed` 等能力，将 GPS 从「不得使用」改为「使用时用于距离」；同步更新 App Store 隐私矩阵与隐私政策 HTML 中 GPS 相关表述。
- iOS `NSLocationWhenInUseUsageDescription` 文案与上述用途保持一致（工程已存在，必要时微调）。

## Capabilities

### New Capabilities

- `ucg-location-consent`：UCG 场景下定位权限检查、用途说明、Session 拒绝记忆、「去设置」入口及坐标获取降级语义。

### Modified Capabilities

- `ucg-home-entry`：PageView 不得于冷启动预构建 UCG page；首次进入广场后再挂载 UCG 壳。
- `ucg-square-feed`：允许客户端在 Feed/详情请求中附带 lat/lng 以展示 `distanceMeters`；撤销「MUST NOT use device GPS」；拒绝定位后的 Feed 降级行为。
- `ucg-compose-post`：发布/更新帖前须走 UCG 定位同意流程（与 compose 路径一致）。
- `history-event-square-sync`：开启「同步广场」保存时 create/update UCG 帖前须尝试获取坐标并传入 API。
- `app-store-connect-privacy-labels`：GPS 精确定位从未收集改为使用时可选收集、用途为展示动态距离。
- `app-legal-docs`：隐私政策 HTML 中 UGC/定位收集说明与矩阵一致。

## Impact

- **Flutter**：`ucg_home_shell.dart`、`ucg_location.dart`（或新 consent 模块）、`ucg_square_tab.dart`、`ucg_compose_screen.dart`、`ucg_providers.dart`（`ucgPostDetailProvider`）、`history_event_square_sync.dart`、`home_history_edit_sheet.dart`。
- **iOS**：`Info.plist` 用途说明（已有，可微调）；提审前 App Store Connect App Privacy 问卷需更新。
- **Android**：`AndroidManifest` 已有定位权限；需 in-app rationale 对话框（系统框无自定义文案）。
- **OpenSpec 基线**：引用 v2.0.2 中 `ucg-home-entry`、`ucg-square-feed` 等；本 change delta 收进版本基线前以 change specs 为准。
