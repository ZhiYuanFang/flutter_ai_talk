## Context

- 客户端在 `RemoteSettingsRepository.saveBaby` 中调用 `POST /device/app/api/user/auto_save`，仅传 `birthday`（Unix 秒）与 `sex`；昵称仅存本地 prefs。
- 胖宝号登录与微信登录共用 `SessionController` 的 token 持久化，当前**未**区分登录渠道。
- 网关提供 `POST /device/app/api/user/save`，需在「设备号登录」场景下于保存宝宝资料时使用。

## Goals / Non-Goals

**Goals:**

- 设备号登录成功后，客户端能识别当前会话为「设备号渠道」。
- 在该渠道下，用户于设置页保存宝宝信息时调用 `POST /device/app/api/user/save`，请求体包含网关所需字段（至少包含与现有 `auto_save` 对齐的画像字段，并包含**昵称**若接口支持；字段名遵循 camelCase，与 `readGatewayStr` 入站兼容策略一致）。
- 保存成功后继续更新本地 `pangbao_baby_profile_*` 缓存及 `deviceNo` 回写逻辑（若响应带 `deviceNo`/`device_no`）。

**Non-Goals:**

- 不修改「创建新宝宝」绑定页中 `auto_save` 的创建语义（除非后续规格明确要求合并）。
- 不在本变更中定义 `user/save` 的完整服务端 DTO（实现前与网关文档对齐；本设计仅约束路径、鉴权与渠道分支）。

## Decisions

1. **登录渠道持久化**  
   - **决策**：在 `SharedPreferences` 增加键（例如 `pangbao_sign_in_channel`），取值 `device` | `wechat`（或 `unknown`）。`signInWithDeviceNo` 成功写 `device`；`signInWithWeChat` 成功写 `wechat`；`signOut` 清除。冷启动 `restore` 后读取，无需放进 access token。  
   - **理由**：与会话 token 正交，避免解析 JWT；实现成本低。  
   - **备选**：扩展 `SessionController` 字段并随 token 写入 prefs——可行但改动面更大。

2. **`saveBaby` 调用分支**  
   - **决策**：当 `sign_in_channel == device` 时，`saveBaby` 调用 `POST /device/app/api/user/save`；当为 `wechat` 或 `unknown` 时，**继续**调用现有 `auto_save`（保持向后兼容，直至微信链路确认迁移）。  
   - **理由**：与需求「当设备号登陆时」字面一致，降低对未联调路径的破坏。  
   - **备选**：一律改 `user/save`——若后端已统一，可在后续小变更中删除分支。

3. **请求体字段**  
   - **决策**：实现前与后端确认 `user/save` 的 JSON 字段；客户端至少发送 `deviceNo`（若 body 要求）、`birthday`（Unix 秒，与 `auto_save` 一致）、`sex`（与 `_sexToApi` 一致）、`nickname`（trim 后非空校验已由 UI 保证）。若后端仅需子集，按文档裁剪。  
   - **理由**：用户未提供 Go struct，避免臆造字段导致联调失败。

4. **错误处理**  
   - **决策**：`ApiBusinessException` 仍走现有 `onToast` 与 `rethrow`；网络失败不静默改写本地已成功缓存的旧数据（保持当前语义）。

## Risks / Trade-offs

- **[Risk] 后端 `user/save` 与 `auto_save` 语义重叠或顺序敏感** → 与后端确认是否仅设备渠道走 `save`，避免双写冲突。  
- **[Risk] 旧安装无渠道键，值为 `unknown`** → 仅走 `auto_save`，与变更前行为一致；用户重新设备号登录后即走 `save`。  
- **[Risk] 字段名 snake/camel 不一致** → 出站统一 camelCase；入站响应继续 `readGatewayStr`。

## Migration Plan

1. 合并后发布；无需数据迁移。  
2. 用户下次「胖宝号登录」后保存资料即走新接口。  
3. 若需全量切 `user/save`，在确认微信链路后删除分支并更新规格。

## Open Questions

- `POST /device/app/api/user/save` 的**正式请求体**与**成功响应 `data` 是否返回 `deviceNo`**（是否与 `auto_save` 一致）——实现前与网关文档对齐。  
- 是否需要在 `unknown` 渠道且已存在本地 `deviceNo` 时也走 `user/save`（产品决策）。
