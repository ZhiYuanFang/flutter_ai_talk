## Why

服务端 usage / 客户端使用统计的用户列表将增加「设备型号」列（见 Go 仓变更 `add-wx-device-model-usage-column`）。客户端需在登录后把本机可读的机型字符串上报服务端，供运维直接展示；不做服务端枚举，Web/取不到机型时可不报。

## What Changes

- 登录且会话就绪后，使用已有依赖 `device_info_plus` 解析本机展示用型号字符串（Android 品牌+型号；iOS 仅营销名如 `iPhone 12` / `iPad Air 2`，硬件码 map 失败则不报）。
- 调用 Go 仓新契约（建议 `PUT /device/app/api/user/device-model`，body `{ "deviceModel": "<string>" }`）上报；须 Bearer；失败静默（对标 client-usage）。
- 本地节流：按 JWT `wxId` 记上次成功值与时间；同账号 24h 内同值不重复；换号可再报；single-flight + 失败短熔断。
- **不**修改既有 `client-usage/report` 的 `featureId`/`description` 契约（避免改 v1 上报 body）。
- Web / 无法取机型平台：跳过上报，允许服务端字段保持空。
- Debug tag `[DeviceModel]` 三联白名单。

## Capabilities

### New Capabilities

- `device-model-report`：解析设备型号并上报到服务端账号字段。

### Modified Capabilities

（无。不扩展 `client-usage-report` 请求体。）

## Impact

- **代码**：`device_info_plus` 已在 `app/pubspec.yaml`；新增小型 helper + 登录后触发点（如 session/bootstrap）。
- **网络**：依赖 Go 仓先上线可写接口；否则客户端失败静默。
- **隐私**：仅上报机型展示字符串，不含 IMEI/广告 ID；与隐私文案若需补充则在 tasks 中核对。
- **基线**：对照 `openspec/specs/v2.2.2.md`。
- **跨仓**：契约字段名 `deviceModel`；与 Go `add-wx-device-model-usage-column` 同步实现/发版。
