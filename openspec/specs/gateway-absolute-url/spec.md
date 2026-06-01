## ADDED Requirements

### Requirement: 网关相对路径解析为绝对 URL

The client SHALL resolve gateway resource paths that lack a scheme by prefixing the same base URL used for HTTP API calls (`AppEnv.apiBaseUrl`). 当服务端返回的资源路径**不含** `http://` 或 `https://`  scheme（例如以 `/` 开头的 `/ai_talk_images/...`、`/device/app/apk/...`）时，客户端必须使用与 HTTP API **相同**的基址 `AppEnv.apiBaseUrl`（去掉末尾 `/`）与路径（去掉开头 `/`）拼接为绝对 URL；若输入已是绝对 URL，必须原样返回（trim 后）。

#### Scenario: 相对路径 logo

- **WHEN** `event/options` 列表项 `logo` 为 `"/ai_talk_images/event_1.png"`
- **THEN** 用于下载与展示的最终 URL 必须为 `{apiBaseUrl}/ai_talk_images/event_1.png`（与当前 `API_BASE_URL` 一致）

#### Scenario: 相对路径 APK 下载地址

- **WHEN** 版本检查 `data.downloadUrl` 为 `"/device/app/apk/foo.apk"`
- **THEN** `VersionInfo` 中供 Android 下载的 URL 必须为 `{apiBaseUrl}/device/app/apk/foo.apk`，且不得因缺少 scheme 被判定为「下载地址无效」

#### Scenario: 已是绝对 URL

- **WHEN** 字段值为 `https://cdn.example.com/app.apk`
- **THEN** 客户端不得修改该字符串（除 trim）

#### Scenario: 空值

- **WHEN** 字段为空、null 或仅空白
- **THEN** 解析结果必须为 null 或空，且不得发起下载

### Requirement: 统一解析入口

The system MUST implement a single shared resolver function for gateway-relative asset URLs and MUST use it for event logo resolution and version APK download URL resolution. 系统必须提供**单一**共享解析函数（如 `resolveGatewayAbsoluteUrl`），事件 logo 与版本 `downloadUrl` **必须**经该函数处理，不得在多处复制拼接逻辑。

#### Scenario: 事件目录与版本检查

- **WHEN** 实现或修改事件目录缓存或版本检查仓库
- **THEN** 必须调用共享解析函数，不得单独维护第二套 base+path 规则
