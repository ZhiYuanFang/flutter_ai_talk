## 1. 机型解析与上报

- [x] 1.1 新增 device model 解析 helper（`device_info_plus`；Android brand/manufacturer + model；iOS 仅 machine→营销名 map，未命中不报；截断 128；`|`→`/`）
- [x] 1.2 新增 repository：`PUT /device/app/api/user/device-model`，失败静默（对标 client-usage）
- [x] 1.3 本地节流按 JWT `wxId`：prefs 记 wx/value/at；24h 内同账号同值跳过；single-flight + 失败短熔断
- [x] 1.4 Debug tag `[DeviceModel]` 三联：`app_debug_log.dart`、`logcat_api_http.ps1`、`app/README.md`

## 2. 触发接入

- [x] 2.1 `UcgHomeShell`：`isLoggedIn` false→true 后帧回调异步触发（不阻塞 UI）
- [x] 2.2 `PangbaoApp` resume 且已登录时异步触发；`ColdStartBackgroundSync` 冷启动已登录补一次；Web / 空型号 / 未登录跳过；provider 创建不自动打

## 3. 验收

- [x] 3.1 与 Go 仓 `add-wx-device-model-usage-column` 契约字段 `deviceModel`、路径一致
- [x] 3.2 核对隐私说明：客户端仅打开托管 `PRIVACY_POLICY_URL`，无内嵌设备条款；型号上报属运维展示，**无需改 App 内文案**（托管页若需补充由运营侧更新）
- [x] 3.3 不改 `client-usage/report` body；不新增 `**/test/**` 测试文件
