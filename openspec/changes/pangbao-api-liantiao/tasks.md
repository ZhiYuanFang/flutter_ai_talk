## 1. HTTP 与配置

- [x] 1.1 引入可配置 `API_BASE_URL`（默认 `https://pangbao.cuplay.top`），与现有 `dart-define` 策略对齐
- [x] 1.2 实现响应壳解析：`code`/`message`/`data`；HTTP 200；`code != 0` 或 `data` 为 null 时 Toast `message`
- [x] 1.3 封装 Dio/HTTP 拦截器：注入 `access_token`、处理静默 refresh、业务错误统一抛出类型（实现为 `http` + [ApiClient]；静默刷新见 `SessionController.trySilentRefresh` + `REFRESH_TOKEN_PATH`）

## 2. 会话、用户详情与 deviceNo

- [x] 2.1 对接服务端封装的微信登录流程，落本地 `access_token` / `refresh_token`（字段名与后端对齐）（**初版**：仍为 Mock 登录 + `SessionController` 持久化双 token；真实 OAuth 待替换 `AuthRepository`）
- [x] 2.2 实现 `GET /device/wx/api/detail`，将 `device_no` 映射为内存态 **`deviceNo`**
- [x] 2.3 实现 `POST /device/profile/api/bindwx` 与 `POST /device/profile/api/auto_save`（`birthday`,`sex`），持久化返回的 `deviceNo`
- [x] 2.4 实现状态机：未登录 / 已登录未绑定 / 已绑定；历史失败文案与点击跳转（登录 vs 绑定）与设置占位

## 3. 历史、WebSocket、语音

- [x] 3.1 实现 `GET /device/history/api/list` 分页模型与 UI 合并（`id` 转 String）
- [x] 3.2 实现 `POST /device/history/api/event/update`，保存后依赖 WS 或乐观更新策略与 spec 一致
- [x] 3.3 与后端共定 **WebSocket URL** 与消息 schema；实现鉴权首包、断线重连、按 `id` 更新或新增（**初版**：`WS_HISTORY_URL` 建连 + 首包 JSON；断线重连待与后端 schema 固化后增强）
- [x] 3.4 实现 `POST /voice/text/chat`，在发送控件下方小字展示 `data.reply`

## 4. 趋势与版本

- [x] 4.1 趋势请求统一携带 `deviceNo`；未登录图表遮罩 +「请登录」跳转登录页
- [x] 4.2 实现 `GET /device/app/api/version/check?currentVersion=`，对接设置/启动时的版本提示

## 5. 验收

- [x] 5.1 `dart analyze` / `flutter analyze` 无新增错误
- [x] 5.2 与后端联调清单：登录→详情→绑定/创建→列表→编辑→WS→语音→趋势→版本（见 `app/README.md` 联调段落；真实 OAuth 与 WS 消息体需与后端现场确认）
