## ADDED Requirements

### Requirement: iOS cold start SHALL fire a non-blocking network probe once per install

On iOS native builds, the app MUST issue one fire-and-forget unauthenticated HTTP GET during cold start to trigger the system wireless-data permission dialog on China-region devices, without awaiting or handling the response. iOS 冷启动 MUST 并行发起一次无鉴权轻量 GET（复用 `version/check` 或等价接口），不 `await`、不解析响应，用于在国行设备上尽早触发「无线局域网与蜂窝网络」系统弹窗。

#### Scenario: 首次安装触发探测

- **WHEN** iOS 应用冷启动且本地尚无 `ios_network_probe_attempted` 标记
- **THEN** App SHALL `unawaited` 发起 GET 请求，且 MUST NOT 阻塞 `ColdStartBootstrap` 或 Splash 路由跳转

#### Scenario: 已探测过则跳过

- **WHEN** iOS 应用冷启动且 `ios_network_probe_attempted` 已为 true
- **THEN** App SHALL NOT 再次发起 probe 请求

#### Scenario: 探测失败不提示用户

- **WHEN** probe 请求超时、无网络或被用户拒绝无线数据
- **THEN** App SHALL 静默忽略，且 MUST NOT 展示 Toast 或错误页

#### Scenario: 非 iOS 平台不探测

- **WHEN** 应用运行于 Web 或非 iOS 平台
- **THEN** App SHALL NOT 执行 `IosNetworkPermissionProbe`
