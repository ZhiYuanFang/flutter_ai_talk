## ADDED Requirements

### Requirement: 趋势数据强依赖 deviceNo

All remote trend chart data requests SHALL include the canonical **`deviceNo`** (string) as required by the server; the client MUST NOT call trend APIs without a valid `deviceNo` when the user is expected to be bound. 具体 path 与 Query 名由实现与服务端对齐；本能力强调 **业务强依赖**。

#### Scenario: 已绑定拉取趋势

- **WHEN** 用户已绑定且进入趋势中心
- **THEN** 每个图表数据请求必须携带同一 `deviceNo`

### Requirement: 未登录趋势遮罩与登录跳转

When the user is **not logged in**, each trend chart area SHALL be covered by a mask with copy **「请登录」** (or product-approved equivalent); a **「请登录」** button on the mask SHALL navigate to the login route when tapped. 未登录 **仅** 遮罩图表区域，不要求整页替换为登录页。

#### Scenario: 点击请登录

- **WHEN** 未登录用户在趋势图遮罩上点击「请登录」按钮
- **THEN** 应用必须导航至登录页

### Requirement: 远程版本检查接口契约

The client and server SHALL support an independent version check using the same **`code` / `message` / `data`** envelope and **HTTP 200** rule. The proposed endpoint is **GET** `/device/app/api/version/check` with query **`currentVersion`** (string, aligned with app build/version naming). The `data` object SHOULD contain: **`needUpdate`** (bool), **`latestVersion`** (string), **`minSupportedVersion`** (string, optional), **`releaseNotes`** (string, optional), **`downloadUrl`** (string, optional), **`forceUpdate`** (bool, optional default false). 服务端若调整 path，必须同步更新客户端配置与本文档。

#### Scenario: 无需更新

- **WHEN** `code` 为 0 且 `data.needUpdate` 为 false
- **THEN** 客户端不得向用户展示强制更新阻塞流程

#### Scenario: 建议更新

- **WHEN** `data.needUpdate` 为 true 且 `forceUpdate` 为 false
- **THEN** 客户端可展示非阻塞更新提示并允许使用 `downloadUrl`（若存在）

#### Scenario: 版本检查失败

- **WHEN** `code` 非 0 或网络异常
- **THEN** 客户端必须 Toast `message`（或网络错误文案）且不得崩溃
