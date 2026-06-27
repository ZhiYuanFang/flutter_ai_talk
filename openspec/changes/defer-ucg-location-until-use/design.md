## Context

`/home` 由 `UcgHomeShell` 承载：`PageView` page 0 为喂养 `HomeScreen`，page 1 为 `UcgShell`。当前实现使用 `PageView(children: [HomeScreen, UcgShell])`，冷启动时两个子树同时 build；`UcgShell` 内 `IndexedStack` 首 Tab 为 `UcgSquareTab`，其在 `initState` 通过 `postFrameCallback` 调用 `_load(refresh: true)`，进而 `tryGetCurrentCoords()` → `Geolocator.requestPermission()`。

产品已支持服务端 `distanceMeters` 与客户端 lat/lng 查询参数（`fetchRecommendedFeed` / `createPost` 等），iOS `Info.plist` 已有 `NSLocationWhenInUseUsageDescription`。v2.0.2 基线 `ucg-square-feed` 仍写「Client MUST NOT use device GPS」，与实现及 App Store 隐私矩阵「不收集 GPS」冲突。

约束：不改变 UCG API 契约；Web 平台继续跳过定位（返回 null）；`UcgEnterSquareTab` 仍可 watch `ucgRepositoryProvider` 做未读同步，但不得触发定位。

## Goals / Non-Goals

**Goals:**

- 冷启动默认喂养页时 **不得** 构建 `UcgShell`、不得拉广场 Feed、不得申请定位。
- 用户 **首次进入 UCG 广场**（横滑或「进入广场」）后再挂载 UCG 并加载 Feed；此时走定位同意流程。
- **统一入口**：拉 Feed、compose 发帖/更新、喂养历史「同步广场」保存前的 `createPost`/`updatePost` 均经同一 `ensureUcgLocationForDistance`（命名待定）模块。
- Session 内用户拒绝系统定位后 **不得** 再次 `requestPermission`；再次进入广场展示 **「去设置」** 入口，Feed 无坐标降级。
- OpenSpec / 隐私政策 / ASC 问卷与「使用时可选 GPS、用于距离」一致。

**Non-Goals:**

- 后台定位、`NSLocationAlways`、Geofencing。
- 修改 ucg-service 距离算法或新增 API 字段。
- Web 端定位（保持 null）。
- 改变 `UcgEnterSquareTab` 未读 WS/HTTP 同步语义。

## Decisions

### 1. 懒挂载 UCG：`PageView.builder` + `_ucgEverMounted`

**选择**：在 `UcgHomeShell` 维护 `_ucgEverMounted`，仅当 `_pageIndex == 1` 或用户首次 `animateToPage(1)` 后置 true；`itemBuilder` 在 index 1 且未 mounted 时返回占位（如 `SizedBox.expand()`），mounted 后返回 `UcgShell`。

**理由**：比 `Offstage` 更明确避免 `UcgShell`/`UcgSquareTab` initState；比全局路由拆页改动小。

**备选**：`AutomaticKeepAlive` + `Visibility` 仍可能 build 子树——不采用。

### 2. 定位同意：`ensureUcgLocationForDistance(BuildContext context)`

**流程**：

1. Web → 直接 `null`。
2. `checkPermission` → granted → `getCurrentPosition`（现有 timeout/accuracy）。
3. `deniedForever` → 标记 session 状态，返回 `null`（不 request）。
4. `denied` 且 session 已记「本进程拒绝」→ 返回 `null`（不 request）。
5. 否则 → 展示 **App 内 AlertDialog**（用途：「用于展示动态与你的距离；拒绝后仍可使用，只是不显示距离」）→ 用户确认 → `requestPermission` → 拒绝则写 session 标记。

**理由**：Android 系统框无自定义文案；与 iOS plist 语义一致；喂养页同步广场也有 `context`（edit sheet）。

**实现位置**：扩展 `ucg_location.dart` 或新建 `ucg_location_consent.dart`；`tryGetCurrentCoords` 改为内部无 UI 的纯获取，或废弃并由新 API 替代。

**Session 状态**：`StateProvider<UcgLocationSessionState>` 或顶层 `UcgLocationConsentController`（`deniedThisSession`、`showSettingsHint`）。

### 3. 「去设置」入口

**选择**：`UcgSquareTab` 顶栏下方 `MaterialBanner` 或轻量 `UcgLocationSettingsHint`：当 session 拒绝或 `deniedForever` 且当前无坐标时展示；点击 `Geolocator.openAppSettings()` / `permission_handler` `openAppSettings`。

**理由**：用户决策为「下次进广场给去设置」，不阻塞 Feed。

### 4. 调用点改造

| 调用点 | 改动 |
|--------|------|
| `UcgSquareTab._load` | refresh 时 `ensure...` 再请求 Feed |
| `UcgComposeScreen._publish` | 发表前 `ensure...` |
| `home_history_edit_sheet` 保存 | sync 开启时 `ensure...`，将 lat/lng 传入 `runHistoryEventMediaSideEffects` |
| `runHistoryEventMediaSideEffects` | 新增可选 `lat`/`lng` 参数，传给 `createPost`/`updatePost` |
| `ucgPostDetailProvider` | 有 context 时难办——用无 UI 路径：仅 `checkPermission`，已授权才取坐标；未授权不弹（详情非首次入口） |

**详情页**：不在 provider 内弹 Dialog（无 BuildContext）；已授权则带坐标，否则不带——与「仅主动 UCG 行为弹窗」一致。

### 5. 合规文案

- iOS plist：统一为「用于展示动态与你的距离」（与 Dialog 一致，微调现有文案）。
- `privacy-policy.html`：「我们不收集」中移除 GPS；新增「使用时可选收集精确位置用于 UCG 距离展示，拒绝不影响核心功能」。
- ASC：新增 Location → Precise Location，Purpose App Functionality，Not used for tracking，Optional。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 用户横滑到 page 1 瞬间仍触发 Feed+定位 | 懒挂载与 `_load` 同在首次 page 1 可见后执行，符合预期 |
| 喂养页同步广场在 page 0 弹定位 | 产品已明确要求；Dialog 文案说明用途 |
| Session 拒绝后距离永远为空直至去设置 | 符合产品；Banner 引导 |
| 规格与旧基线冲突 | 本 change delta MODIFIED + 归档时合并 |
| `IndexedStack` 仍 eager build 其他 Tab | 仅 page 1 mount 后发生；可后续再 lazy Tab，非本 change 必须 |

## Migration Plan

1. 实现懒挂载 + consent 模块 + 调用点改造。
2. 更新 `privacy-policy.html` 生效日期与矩阵。
3. 提审前人工更新 App Store Connect App Privacy 问卷。
4. 回滚：还原 `ucg_home_shell` 与 `ucg_location`，移除 Banner；plist/政策可保留（无害）。

## Open Questions

- 无。产品侧已确认：同步广场要定位、session 拒绝策略、规格改 GPS 用途、iOS 无需 Developer Portal 单独开通定位能力（仅 ASC 问卷 + plist）。
