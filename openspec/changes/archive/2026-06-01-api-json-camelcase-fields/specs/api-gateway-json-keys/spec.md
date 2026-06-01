## ADDED Requirements

### Requirement: 网关 JSON 键名采用 lowerCamelCase

The client SHALL serialize outbound gateway JSON object keys in **lowerCamelCase** (e.g. `deviceNo`, `accessToken`, `downloadUrl`) and SHALL NOT introduce new **snake_case** keys for HTTP request bodies, WebSocket auth envelopes, or query parameters that are part of the documented API contract. 客户端向网关发送的 JSON 对象键名、以及作为契约一部分的 query 参数名，必须使用 **lowerCamelCase**；不得以新代码路径再引入 `device_no`、`access_token` 等 snake 作为正式字段名。

#### Scenario: 胖宝号登录请求体

- **WHEN** 客户端调用 `POST /device/app/api/device_login` 提交设备号
- **THEN** 请求 JSON 中标识设备号的键名必须为 **`deviceNo`**，不得再使用 **`device_no`** 作为唯一键名

#### Scenario: WebSocket 鉴权首帧

- **WHEN** 客户端向历史 WebSocket 发送首帧鉴权 JSON
- **THEN** 承载访问令牌的键名必须为 **`accessToken`**（与 camelCase 约定一致），不得仅发送 **`access_token`**

### Requirement: 入站解析以 camelCase 为准

The client SHALL read successful API `data` fields using camelCase keys first; snake_case aliases MAY be supported only during an explicit compatibility window documented in tasks or design. 解析网关返回的 `data` 对象时，必须**优先**读取 camelCase 键；仅在经产品/后端确认的兼容期内，可保留对 snake_case 的第二候选读取，且应集中在可移除的辅助实现中。

#### Scenario: 版本检查响应

- **WHEN** 客户端解析 `version/check` 返回的 `data` 中下载地址
- **THEN** 必须读取 **`downloadUrl`**；若兼容期内存在旧网关仅返回 `download_url`，允许经统一辅助函数回退读取

### Requirement: 用户可见字段说明与代码注释一致

The client SHALL align user-facing copy and developer comments that mention wire-format field names with the camelCase contract (e.g. label text uses `deviceNo`, not `device_no`). 界面标签、README 中若展示「接口字段名」，必须与 camelCase 契约一致，不得误导为 snake_case。

#### Scenario: 登录页胖宝号说明

- **WHEN** 登录页展示输入项说明文案
- **THEN** 不得将 `device_no` 作为推荐或唯一字段名展示；应使用 **`deviceNo`**（或中文「胖宝号」而不写错误键名）
