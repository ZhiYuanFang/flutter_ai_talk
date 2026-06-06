## 1. ApiClient 与 UcgApiClient 基础能力

- [x] 1.1 在 `ApiClient` 新增 `putJsonEnvelope`（`http.put`）与 `deleteEnvelope`（`http.delete`），复用 `_send` 401 刷新与信封解析（`ucg-api-contract`）
- [x] 1.2 修改 `UcgApiClient.put` / `delete` 委托真实 HTTP 方法，移除 POST 冒充（`ucg-api-contract`）
- [x] 1.3 对照 `go_ai_talk` ucg-service 路由表，整理 Flutter 与后端路径/方法对照清单（供联调验收）

## 2. Phase 1 — 推荐流与个人资料

- [x] 2.1 `fetchRecommendedFeed` 路径改为 `GET /feed/recommend`（`ucg-square-feed`）
- [x] 2.2 更新 `UcgPost.fromJson` / `UcgProfile.fromJson`：`wxId`/`userId`、`authorWxId`/`authorId`、`content`/`text` 双字段兼容（`ucg-api-contract`）
- [x] 2.3 `UcgPostStatus.fromApi` 支持整型 status 映射（对照 ucg-service 常量）（`ucg-square-feed`）
- [x] 2.4 `fetchProfile(wxId)` 支持 `withAuthorization: false` 用于他人主页匿名访问（`ucg-wxid-identity`）
- [ ] 2.5 手工验证：未登录推荐流可加载；已登录 `GET/PUT /profile/me` 正常

## 3. Phase 2 — 发帖与媒体 presign

- [x] 3.1 对照 ucg-service 校正 `UcgPresignRequest` / `UcgPresignResult` 字段名（`ucg-compose-post`）
- [x] 3.2 `createPost` 请求体发送 `content` 字段（保留解析层 `text` 属性）（`ucg-compose-post`）
- [x] 3.3 我的动态列表展示整型 pending/rejected 状态文案（`ucg-compose-post`）
- [x] 3.4 手工验证：选图 → presign/网关上传 → 发帖端到端成功（展示 URL 使用 CDN `https://resorce.cuplay.top/...`；客户端优先 API `cdnUrl`，缺失时 `objectKeyToCdn` 回退；Web 预览/广场图用 `UcgNetworkImage` + `WebHtmlElementStrategy.prefer` 规避 CDN 无 CORS 时的 statusCode 0）

## 4. Phase 3 — 互动、关注与会话 HTTP

- [x] 4.1 点赞 `POST`、取消赞 `DELETE`；关注 `POST`、取关 `DELETE`（`ucg-interactions`）
- [x] 4.2 评论请求体使用 `content`；删评路径改为 `DELETE /comments/{id}`（`ucg-interactions`）
- [x] 4.3 会话置顶改为 `PUT /conversations/{id}/pin`；删会话 `DELETE`（`ucg-chat-ui`）
- [x] 4.4 实现 `createConversation(peerWxId)` → `POST /conversations`（`ucg-chat-ui`）
- [ ] 4.5 手工验证：点赞/评论/关注/会话列表 CRUD

## 5. Phase 4 — WebSocket 帧与 gateway 代理

- [x] 5.1 对照 `go_ai_talk` gateway WS 代理与 ucg-service handler，确定 auth 首帧与 `send_message` canonical 字段
- [x] 5.2 更新 `UcgRepository.connectChatWs` / `sendChatWs` / `_onWsMessage` 使用 canonical 格式，保留入站别名宽容（`ucg-api-contract`）
- [ ] 5.3 联调 task 8.5：dev 环境验证 `wss://{apiBaseUrl host}/ucg/app/ws/chat` 端到端（auth → 收消息）
- [ ] 5.4 手工验证：两用户私信文本往返

## 6. Phase 5 — JWT sub→wxId 与 wxId=0 门控

- [x] 6.1 在 `token_expiry.dart` 新增 `readJwtWxId`，解析 JWT `sub`
- [x] 6.2 `ucg_providers.dart`：监听 `sessionProvider`，同步 `ucgCurrentUserIdProvider`；登出清空
- [x] 6.3 新增 `requireUcgWxAccount`（或扩展 `requireUcgLogin`）：`sub=0` 时展示「请先绑定微信账号后再使用社区功能」
- [x] 6.4 在发帖、互动、消息、关注入口应用 wxId 非零门控（`ucg-wxid-identity`）
- [ ] 6.5 手工验证：设备态 `sub=0` 可看推荐但不可发帖；绑微信后可发帖

## 7. 后端联调与部署（go_ai_talk，非 Flutter 必改项）

- [x] 7.1 确认 `UCG_SERVICE_BASE_URL` 与 gateway UCG 代理配置正确
- [x] 7.2 确认 JWT secret 跨 gateway / ucg-service 一致
- [x] 7.3 gateway 将 `GET /ucg/app/api/profile/{wxId}` 加入匿名白名单（若尚未配置）
- [x] 7.4 回归确认：喂养 `/device/app/api/*` 与 history WS 无影响
- [x] 7.5 gateway UCG 反代不得转发 OPTIONS：`/ucg/app/api/*` 预检由 `gateway_app_cors` 204 短路（修复 Web multipart 上传 CORS 预检 405）

## 8. 喂养安全区回归

- [x] 8.1 确认未修改 `RemoteFeedRepository`、`gateway_app_history_ws.go`、`device_no_notifier` 业务逻辑
- [ ] 8.2 手工回归：喂养首页历史同步、事件记录、WS 重连、登录刷新流程正常
