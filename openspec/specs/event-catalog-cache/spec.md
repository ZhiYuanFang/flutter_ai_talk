## ADDED Requirements

### Requirement: 事件目录 API 字段消费

The client SHALL parse each item of `GET /device/history/api/event/options` `data.list[]` with at least `id`, `name`, `logo`, and `color` (lowerCamelCase). 客户端必须从事件目录接口的 `data.list[]` 解析 **`id`**、**`name`**、**`logo`**（图片 URL 字符串）、**`color`**（品牌色字符串）；缺省或空字符串视为该字段未提供。

#### Scenario: 完整列表项

- **WHEN** 接口返回 `code` 为 0 且列表项包含 `id`、`name`、`logo`、`color`
- **THEN** 客户端必须将四项均纳入内存中的事件定义，且 `id` 字符串化后作为全局查找主键

#### Scenario: 缺省 logo 或 color

- **WHEN** 某列表项的 `logo` 或 `color` 为空、缺失或无法解析
- **THEN** 客户端必须仍保留该事件条目，且不得因缺字段丢弃整项

### Requirement: 主页启动加载本地缓存

The system MUST load the persisted event catalog from local storage into global app state before or during home screen initialization, without waiting for network. 系统必须在主页初始化阶段**优先**从本地存储加载事件目录到全局可读状态（Riverpod 等），**不得**阻塞 UI 直到网络返回。

#### Scenario: 存在本地缓存

- **WHEN** 用户进入主页且磁盘存在有效 `catalog` JSON
- **THEN** 全局事件目录必须立即反映缓存内容，供历史区与今日汇总读取

#### Scenario: 无本地缓存

- **WHEN** 首次安装或缓存被清空
- **THEN** 全局目录可为空列表，应用不得崩溃

### Requirement: 远端对比与缓存更新

The system SHALL request `event/options` on home startup when the user is logged in with a valid `deviceNo`, compare the result with the local catalog snapshot, and persist updates when any tracked field differs per event id. 当用户已登录且具备有效 `deviceNo` 时，系统必须在主页启动流程中请求 `event/options`，按 **`id`** 与本地快照对比（至少 **`name`**、**`color`**、**`logo`** URL）；任一事件上述字段变化则必须更新本地 JSON 元数据。

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

The system MUST download each event `logo` URL to a local file under application documents (or platform-equivalent) and record the path in catalog metadata. 系统必须将每个非空 `logo` URL 下载为本地文件（路径记录在 catalog 元数据中，按 `eventId` 命名）；UI 必须优先使用本地文件展示，而非每次从网络加载。

#### Scenario: 首次下载成功

- **WHEN** 某事件 `logo` URL 非空且下载成功
- **THEN** 元数据必须包含可用的 `localLogoPath`，且文件必须位于约定目录 `logos/` 下

#### Scenario: logo URL 变更

- **WHEN** 同一 `id` 的 `logo` URL 与本地记录不同
- **THEN** 系统必须重新下载并覆盖或替换对应本地文件

#### Scenario: 下载失败

- **WHEN** logo 下载失败或 URL 为空
- **THEN** 系统不得清除既有本地文件（若存在）；UI 必须使用占位图

### Requirement: 全局目录查找

The system SHALL expose a single global catalog lookup by `eventId` (string or int normalized to string) for all features. 系统必须通过单一全局 Provider/仓库，按 **`eventId`** 提供 `EventDefinition` 查找；历史记录、今日汇总、趋势、详情必须共用该查找，不得维护互不一致的第二份目录。

#### Scenario: 按 eventId 命中

- **WHEN** 历史记录 `rawPayload.eventId` 在目录中存在
- **THEN** 必须返回对应 `logo` 路径与解析后的 `color`

#### Scenario: 未命中目录

- **WHEN** `eventId` 不在目录中
- **THEN** 查找必须返回空定义，UI 层使用占位 logo；色调按 `event-branded-ui` 主色规则处理
