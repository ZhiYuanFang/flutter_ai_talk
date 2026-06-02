## Why

新安装后冷启动时，启动遮罩会长时间停留，主要因为在 `go(/home)` 之前同步等待事件目录网络刷新、历史远端同步以及全部事件 logo 的 ImageCache 预热。这与基线 `cold-start-splash`「仅本地门禁后进主页、网络补全移至主页之后」的意图不一致，也拖慢了已有磁盘缓存的老用户二次打开速度。需要将事件目录与 logo 文件缓存改为后台异步，同时保证有本地缓存时首帧体验不退化。

## What Changes

- Splash（`app.dart` `_runColdStart`）**不得**再 `await` `eventCatalog.bootstrap()`、`homeHistory.bootstrap()` 的网络部分，以及 `EventLogoStartupWarmup.precacheCatalog()`。
- Splash 在已登录路径下 **必须** 仍 `await` 本地 hydrate：`eventCatalog.loadFromDisk()`、`homeHistory.loadFromDisk()`（或等价 warm），并在 history 磁盘有数据时将 `initialLoadDone` 置为 true，避免有缓存时仍显示 loading 转圈。
- 进入主页后通过**单一后台入口**异步执行：`event/options` 对比刷新、logo 文件下载、历史远端 refresh；notifier 内加 in-flight  guard，避免与 `HomeScreen._bootstrapHomeData` 重复触发。
- Logo 下载改为有限并发，并在每个事件 logo 落盘后**增量更新** `eventCatalogProvider` state（而非整批完成后一次替换）。
- `EventLogo`（非 Web）：有 `logoUrl` 但无可用 `localLogoPath` 时 **必须** 显示占位图，**不得** 走 `Image.network`；本地文件就绪后自动切换。
- 删除或停用阻塞式 `EventLogoStartupWarmup.precacheCatalog`；可选保留进主页后低优先级、仅本地文件的 unawaited precache（不纳入 MUST）。
- 当 catalog 从空变为非空时，主页刷新按钮排序（`_buttonGridOrder`）。

## Capabilities

### New Capabilities

（无新增独立能力；行为变更归入既有能力 delta。）

### Modified Capabilities

- `cold-start-splash`：明确 Splash 允许阻塞项不含 catalog/history 网络同步与 logo 预热；主页壳展示后补全。
- `startup-splash-gradient-visual`：移除「logo 预热必须在 `go(/home)` 之前」要求。
- `startup-splash-static-300ms`：收窄「bootstrap 完成」定义，不含 logged-in 的 history/catalog 网络 bootstrap。
- `event-catalog-cache`：远端 `event/options` 与 logo 下载不得阻塞路由；补充增量 logo state 与 Splash 本地 hydrate 非回归要求。
- `event-branded-ui`：非 Web 有 logo URL 但本地文件未就绪时必须占位，不得网络 fallback。

## Impact

- **代码**：`app/lib/app.dart`、`providers/event_catalog_notifier.dart`、`data/event_catalog_store.dart`、`ui/event_logo.dart`、`ui/home_screen.dart`；可能移除或降级 `ui/event_logo_startup_warmup.dart`。
- **规格**：上述 5 个基线能力的 MODIFIED delta。
- **用户体验**：首次安装 Splash 明显缩短；老用户二次打开 Splash 亦缩短，首帧仍依赖磁盘 catalog/history/logo；首屏数据可能短暂为磁盘快照直至后台 refresh 完成；logo URL 变更时短暂占位后换图。
- **Web**：无本地 logo 文件能力，继续 `Image.network`，不受「禁止网络 fallback」约束。
