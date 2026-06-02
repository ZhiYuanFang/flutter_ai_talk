## MODIFIED Requirements

### Requirement: 主页启动加载本地缓存

The system MUST load the persisted event catalog from local storage into global app state before or during home screen initialization, without waiting for network; Splash MUST await this disk load for logged-in users before navigating to home. 系统必须在主页初始化阶段**优先**从本地存储加载事件目录到全局可读状态（Riverpod 等），**不得**阻塞 UI 直到网络返回；已登录用户 Splash 在 `go(/home)` 前 **MUST** `await` 等价的磁盘加载，使老用户首帧可读到含 `localLogoPath` 的缓存。

#### Scenario: 存在本地缓存

- **WHEN** 用户进入主页且磁盘存在有效 `catalog` JSON
- **THEN** 全局事件目录必须立即反映缓存内容，供历史区与今日汇总读取；且该内容 MUST 在 Splash 结束前已注入内存（非仅依赖进主页后的异步 warm）

#### Scenario: 无本地缓存

- **WHEN** 首次安装或缓存被清空
- **THEN** 全局目录可为空列表，应用不得崩溃；主页壳 MUST 仍可展示，后台 sync 填充目录

### Requirement: 远端对比与缓存更新

The system SHALL request `event/options` after the home shell is shown (when logged in with valid `deviceNo`), compare with local snapshot, and persist updates when tracked fields differ; this remote work MUST NOT block Splash navigation. 当用户已登录且具备有效 `deviceNo` 时，系统**必须在主页展示之后**请求 `event/options`，按 **`id`** 与本地快照对比（至少 **`name`**、**`color`**、**`logo`** URL）；任一事件上述字段变化则必须更新本地 JSON 元数据；该远端流程 **MUST NOT** 阻塞 Splash 到 `/home` 的跳转。

#### Scenario: 目录无变化

- **WHEN** 远端列表与本地快照在 tracked 字段上完全一致
- **THEN** 系统不得重写 JSON 或重复下载未变化的 logo 文件

#### Scenario: 目录有变化

- **WHEN** 某 `id` 的 `name`、`color` 或 `logo` URL 与本地不同，或出现新增/删除事件
- **THEN** 系统必须写入更新后的 catalog JSON，并删除已移除事件对应的本地 logo 文件

#### Scenario: 网络失败

- **WHEN** `event/options` 请求失败或 `code` 非 0
- **THEN** 系统必须保留当前内存与磁盘中的旧目录，且主页仍可展示

### Requirement: Logo 本地文件存储

The system MUST download each event `logo` URL to a local file under application documents asynchronously after home is shown, update catalog metadata incrementally, and MUST NOT block Splash on downloads. 系统必须将每个非空 `logo` URL **异步**下载为本地文件（路径记录在 catalog 元数据中）；UI 必须优先使用本地文件展示；下载 **MUST NOT** 阻塞 Splash；每个 logo 成功落盘后 **MUST** 增量更新内存 catalog state 以便 UI 自动换图。

#### Scenario: 首次下载成功

- **WHEN** 某事件 `logo` URL 非空且下载成功
- **THEN** 元数据必须包含可用的 `localLogoPath`，且文件必须位于约定目录 `logos/` 下；对应 `EventLogo` MUST 在不重启应用的情况下从占位切换为本地图

#### Scenario: logo URL 变更

- **WHEN** 同一 `id` 的 `logo` URL 与本地记录不同
- **THEN** 系统必须重新下载并覆盖或替换对应本地文件

#### Scenario: 下载失败

- **WHEN** logo 下载失败或 URL 为空
- **THEN** 系统不得清除既有本地文件（若存在）；UI 必须使用占位图

## ADDED Requirements

### Requirement: 后台 sync 不得重复阻塞

The system SHALL use a single background sync entry with in-flight deduplication for catalog and history remote refresh after cold start. 系统 MUST 通过单一后台入口（如 `ColdStartBackgroundSync`）在进主页后触发 catalog/history 远端 sync，且 MUST 用 in-flight guard 避免 Splash 与 `HomeScreen` 重复并发相同 sync。

#### Scenario: 冷启动与 Home 双路径

- **WHEN** Splash 已 `unawaited` 后台 sync 且 `HomeScreen` 初始化再次请求 sync
- **THEN** 系统 MUST 复用进行中的 Future 或跳过重复请求，不得对 `event/options` 或 history 列表发起无必要的并行重复拉取
