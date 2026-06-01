## 1. 登录渠道持久化

- [x] 1.1 与后端确认 `POST /device/app/api/user/save` 的请求体字段、成功响应是否含 `deviceNo`（对齐 design 中 Open Questions）
- [x] 1.2 在 `SharedPreferences` 增加登录渠道键（如 `pangbao_sign_in_channel`），定义 `device` / `wechat` / 未设置时的读取语义
- [x] 1.3 `RemoteAuthRepository.signInWithDeviceNo` 成功持久化 token 后写入 `device`；`signInWithWeChat` 成功写入 `wechat`
- [x] 1.4 在登出流程中清除该键（若当前 `signOut` 未接仓库，则在实际执行登出的路径上清除）

## 2. 保存宝宝资料调用 user/save

- [x] 2.1 提供读取当前登录渠道的 Riverpod/Repository 注入方式，供 `RemoteSettingsRepository` 使用（避免循环依赖）
- [x] 2.2 在 `RemoteSettingsRepository.saveBaby` 中：渠道为 `device` 时调用 `POST /device/app/api/user/save`（body 含 `deviceNo`、`birthday`、`sex` 及契约要求的 `nickname` 等）；否则保持 `auto_save`
- [x] 2.3 解析 `user/save` 响应：若有 `deviceNo`/`device_no` 则与现逻辑一致回写本地与 prefs；失败时 Toast + rethrow
- [x] 2.4 手测：胖宝号登录 → 设置页编辑宝宝信息 → 保存，确认网关收到 `user/save`；微信/无渠道路径仍为 `auto_save`（若可测）

## 3. 文档与校验

- [x] 3.1 更新 `app/README.md` 网关接口说明，补充 `user/save` 与保存分支说明（简要）
- [x] 3.2 运行 `openspec validate device-login-baby-save-user-save --strict` 并修复校验问题（若有）
