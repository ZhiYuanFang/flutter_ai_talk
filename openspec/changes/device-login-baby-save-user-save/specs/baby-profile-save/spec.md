## ADDED Requirements

### Requirement: 设备号登录渠道持久化

The client SHALL persist the sign-in channel after successful authentication so that subsequent baby-profile saves can select the correct gateway endpoint. 客户端必须在登录成功时写入渠道标识（设备号登录记为 `device`，微信登录记为 `wechat`），并在登出时清除；冷启动恢复会话后仍可读取该标识。

#### Scenario: 胖宝号登录后写入 device 渠道

- **WHEN** 用户通过 `signInWithDeviceNo` 登录成功并完成 token 持久化  
- **THEN** 客户端必须将登录渠道持久化为表示设备号登录的值（例如 `device`）

#### Scenario: 登出后清除渠道

- **WHEN** 用户执行登出  
- **THEN** 客户端必须清除已持久化的登录渠道（或置为与「未登录」一致的状态）

### Requirement: 设备号会话下保存宝宝资料须调用 user/save

The system SHALL call **POST** `/device/app/api/user/save` when saving baby profile from the app while the persisted sign-in channel indicates device-number login. 请求必须使用已授权的 `ApiClient`（Bearer），JSON 字段采用 lowerCamelCase（与现有网关约定一致），并包含后端契约所要求的画像字段（至少包括与当前 `auto_save` 一致的 `birthday` 与 `sex`；若契约有昵称字段则必须包含用户编辑后的昵称）。保存成功后客户端必须按现有逻辑更新本地宝宝资料缓存；若响应 `data` 中含 `deviceNo`/`device_no`，必须继续用于回写本地 `deviceNo` 与 prefs 键。

#### Scenario: 设备号渠道下保存走 user/save

- **WHEN** 当前持久化登录渠道为设备号登录且用户在设置页触发保存宝宝资料  
- **THEN** 客户端必须调用 `POST /device/app/api/user/save` 且不得仅依赖 `auto_save` 完成该次持久化

#### Scenario: 非设备号渠道保持 auto_save

- **WHEN** 当前持久化登录渠道为微信或未知（例如旧版本未写入渠道）  
- **THEN** 客户端保存宝宝资料时必须仍调用现有的 `POST /device/app/api/user/auto_save` 行为（与变更前一致），除非后续规格明确迁移

#### Scenario: 保存失败时提示

- **WHEN** `user/save` 返回业务错误（`code != 0`）  
- **THEN** 客户端必须按现有方式向用户展示错误信息并不得将失败结果当作已成功持久化
