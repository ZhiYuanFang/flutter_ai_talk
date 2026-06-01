## Why

当前「保存宝宝信息」仅调用 `POST /device/app/api/user/auto_save`，与网关侧用于完整保存画像的 `POST /device/app/api/user/save` 未对齐。胖宝号（设备号）登录用户编辑昵称、生日、性别后保存时，需要走 `user/save`，以便服务端持久化与设备号会话一致的宝宝资料。

## What Changes

- 在用户通过**胖宝号（设备号）登录**建立的会话下，于「保存宝宝信息」流程中**调用** `POST /device/app/api/user/save`（路径 `/device/app/api/user/save`），请求体与响应解析与现有网关 JSON 约定（camelCase 优先、`readGatewayStr` 兼容 snake）保持一致。
- 需能区分「设备号登录」与「其他登录方式」（如后续开放微信）：在登录成功时持久化**登录渠道**，保存时按渠道选择调用 `user/save` 或保留现有 `auto_save` 行为（具体以 design 为准，避免误伤未对接 `user/save` 的链路）。
- 本地 `SharedPreferences` 中宝宝资料缓存逻辑在保存成功后仍须更新，保证设置页与离线展示一致。

## Capabilities

### New Capabilities

- `baby-profile-save`：定义设备号登录场景下保存宝宝资料时调用 `user/save` 的接口契约、登录渠道标记与错误处理预期。

### Modified Capabilities

- （无）仓库根目录 `openspec/specs/` 下暂无已发布能力；本次仅在变更内新增 delta 规格。

## Impact

- `app/lib/data/remote_settings_repository.dart`：`saveBaby` 分支或新增调用序列。
- `app/lib/data/remote_auth_repository.dart`（及可选 `session`）：登录成功后写入登录渠道，供保存时判断。
- `app/README.md`（若已有网关接口列表）：补充 `user/save` 说明（实现任务中可勾选）。
