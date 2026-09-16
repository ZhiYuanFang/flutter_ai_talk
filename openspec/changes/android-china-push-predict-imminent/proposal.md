## Why

Android 离线推送需用 `china_push` 统一取 token；预测临近与 UCG 角标等均依赖同一套 token。Go 已将推送拆为全局 `push-service`（`POST /app/api/push/register`），旧 `/ucg/app/api/push/*` 已删除；JWT 中的 `wxId` 仅表示**已登录用户**，不要求微信绑定。客户端仍走 UCG 路径并卡在「绑微信 + UCG 会话/WS」，导致全局推送与预测离线提醒无法对齐服务端。本变更一并完成：china_push、全局注册路径与门闸、预测 pending 同步。

## What Changes

- **BREAKING（Android 推送实现）**：拆除自研 HMS / MiPush 源码与 MethodChannel Android 路径；Android **仅**经 **`china_push`** 取 `regId` / manufacturer。
- **BREAKING（注册 API）**：推送注册/注销改为 **`POST /app/api/push/register`** 与 **`POST /app/api/push/unregister`**（经 `ApiClient` + Bearer）；**禁止**再调用 `/ucg/app/api/push/*`。
- **BREAKING（门闸与归属）**：推送为 **App 全局能力**，与 UCG 会话 / chat WS /「绑定微信」解耦；门闸仅为 **已登录**；`activateUcgHomeSession` **不得**再负责 push register。
- **iOS**：继续原生 APNs；注册仍走全局 `/app/api/push/register`，`channel=apns`。
- **Go 通道一期**：仅 `apns` | `hms` | `mipush`；manufacturer 映射不到或未配 key → 自然失败，本版接受；后续开通其它厂商再改。
- **新增**预测临近 pending：`PUT /device/api/predict/imminent/pending`；与 register 解耦，复用全局 token。
- Android 原生变更须 `flutter build apk --release` + proguard（见 project.md）。

## Capabilities

### New Capabilities

- `android-china-push`：Android 仅经 `china_push` 取 token；拆除自研 HMS/Mi；映射 `hms|mipush`；失败可接受。
- `app-global-push-registration`：全局注册/注销 `/app/api/push/*`；登录即可；与 UCG 会话解绑；single-flight / deviceKey / 熔断保留。
- `predict-imminent-client-sync`：预测刷新后全量同步 pending；复用全局 push token。

### Modified Capabilities

- `ucg-push-token-registration`：客户端不再经 UCG 路径注册；门闸改为全局登录态（见 `app-global-push-registration`）。
- `ucg-launcher-badge-push`：杀进程可见通知仍依赖服务端 payload；Android 仅 china_push；token 来自全局注册。

## Impact

- **Flutter**：`china_push`；推送模块迁出/摆脱 `UcgApiClient`；`activateUcgHomeSession` 去掉 push；登录后触发全局 register；预测 pending；README。
- **Go**：`extract-push-service` / `predict-imminent-offline-push` 已就绪；客户端对齐即可。一期不扩 OEM Sender。
- 对照基线 `openspec/specs/v2.1.0.md` 中 UCG push 相关条目，以本 delta 为准覆盖路径与门闸。
- 不自动新建 `**/test/**`。
