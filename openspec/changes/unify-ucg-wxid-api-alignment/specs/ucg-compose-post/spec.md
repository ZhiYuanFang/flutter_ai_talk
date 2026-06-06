## ADDED Requirements

### Requirement: createPost and presign SHALL use ucg-service canonical request fields

Posting flow MUST call `POST /ucg/app/api/media/presign` with field names expected by ucg-service, then `POST /ucg/app/api/posts` with body field `content` for text (plus `imageKeys` / `videoKey` as applicable). Response post `status` MUST be parsed as integer or string per `ucg-api-contract`.

#### Scenario: presign 后发帖
- **WHEN** 用户选择图片并完成 presign 上传
- **THEN** `POST /posts` body SHALL 含 `content` 与 `imageKeys`，且 SHALL NOT 仅发送非 canonical 字段名导致 4xx

#### Scenario: 审核中状态展示
- **WHEN** 发帖成功且 API 返回 `status: 1`（pending）
- **THEN** 我的动态 SHALL 展示审核中状态文案

## MODIFIED Requirements

### Requirement: Posting SHALL require login

Submitting a post MUST require logged-in session with non-zero wxId per `ucg-wxid-identity`; device-only `sub=0` SHALL show bind-wechat message. Unauthenticated users SHALL be redirected to login.

#### Scenario: 未登录发帖
- **WHEN** 未登录用户尝试发布
- **THEN** App SHALL 跳转登录页

#### Scenario: 设备态 wxId 为零发帖
- **WHEN** 已设备登录但 `sub=0` 用户尝试发布
- **THEN** App SHALL 展示绑定微信提示，且 SHALL NOT 调用发帖 API
