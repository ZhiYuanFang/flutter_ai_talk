## Context

- 版本检查基础设施已存在：`readPackageVersion()`、`RemoteVersionRepository.checkForUpdate`（`GET /device/app/api/version/check`，`withAuthorization: false`）、`maybeShowVersionPrompt`（iOS / Android / Web 分流）。
- 主页 `_runPostLoginBootstrap` 仅在**已登录**用户进入 `/home` 后被动调用 `maybeShowVersionPrompt`；无更新时静默返回，用户无感知。
- 设置中心 `/settings` 对游客开放；现有 tile 通过 `_buildGlassTile` + `SettingsGlassPanel` 呈现，风格与「隐私政策」等一致。
- 约束：Debug 日志走 `AppDebugLog`；短时反馈走 `AppToast` / `ref.showApiToast`；不新增 HTTP 接口。

## Goals / Non-Goals

**Goals:**

- 在设置中心提供「检查更新」入口，subtitle 展示当前 `package_info.version`。
- 点击后调用既有版本检查 API；有更新时复用 `maybeShowVersionPrompt`。
- 无更新、进行中、失败三种状态均有明确用户反馈。
- 游客与已登录用户均可使用该入口。

**Non-Goals:**

- 不改变主页被动版本检查的时机与登录门禁（仍仅登录用户在 home postFrame 后检查）。
- 不修改 `version/check` 网关契约或 Android/iOS/Web 更新流程本身。
- 不在 subtitle 展示 build number（`+5`）；除非后续产品单独要求。
- 不重构 `RemoteVersionRepository` 为 Result 类型（除非实现中发现无法区分失败与无更新）。

## Decisions

### 1. UI 位置与组件形态

**决策**：在「隐私政策」tile 下方新增 `_buildGlassTile`，标题「检查更新」，subtitle「当前版本 {version}」。

**理由**：与「关于类」信息相邻；复用现有 glass 样式，改动最小。

**备选**：独立 `CheckUpdateTile` 文件 — 逻辑约 40 行，内联于 `SettingsScreen` 即可，避免过度抽象。

### 2. 版本号加载

**决策**：`SettingsScreen` 在 `initState` 调用 `readPackageVersion()` 写入 `_currentVersion`；未就绪前 subtitle 显示「加载中…」或留空。

**理由**：与主页一致使用 `package_info_plus`；无需 Provider。

### 3. 点击检查流程

**决策**：在 settings 内实现 `_checking` 布尔 guard + trailing `CircularProgressIndicator`（或禁用 `onTap`），流程：

1. `readPackageVersion()`（或复用已缓存版本）
2. `ref.read(versionRepositoryProvider).checkForUpdate(version)`
3. `info != null` → `await maybeShowVersionPrompt(...)`
4. `info == null` 且未抛错 → `ref.showApiToast('已是最新版本', tone: success)`
5. `catch` → `ref.showApiToast('检查失败，请稍后重试', tone: error)`

**理由**：`maybeShowVersionPrompt` 已封装有更新 UI；手动检查必须补「已最新」反馈。

### 4. 区分「无更新」与「API 失败」

**决策**：在 `RemoteVersionRepository.checkForUpdate` 中，**不再**将任意 `ApiBusinessException` 吞掉为 `null`；改为 rethrow 或返回可区分结果。Settings 层 catch 展示失败 Toast；`needUpdate == false` 仍返回 `null`。

**理由**：现状 `catch (ApiBusinessException) { return null; }` 会导致用户误以为已是最新。变更范围小（单文件 + 主页 bootstrap 的 try/catch 已存在）。

**备选**：新增 `checkForUpdateResult` sealed class — 过度设计，暂不采用。

**主页兼容**：`_runPostLoginBootstrap` 已有外层 `try/catch (_) {}`；repository 抛错时行为与现在等价（不弹窗），可接受。

### 5. 可见性与鉴权

**决策**：tile 放在 `loggedIn` 条件块**之外**，与「隐私政策」同级，全员可见。

**理由**：版本 API 无鉴权；补全游客手动检查能力。

## Risks / Trade-offs

- **[Risk] repository 抛错行为变化** → 仅 settings 展示失败 Toast；home 静默，与现网一致。
- **[Risk] 重复检查** → 用户可能在 home 已见弹窗后再手动检查；可接受，第二次仍走相同弹窗逻辑。
- **[Risk] 检查中离开页面** → 使用 `mounted` guard，取消 UI 更新。

## Migration Plan

- 纯客户端 UI + 小范围 repository 错误处理调整；无数据迁移。
- 发版后即可在设置中心使用；无需后端配合。

## Open Questions

（无 — 探索阶段产品点已默认：无更新 Toast、失败单独提示、全员可见、不改 home 自动检查。）
