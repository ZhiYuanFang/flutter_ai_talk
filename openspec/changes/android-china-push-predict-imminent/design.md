## Context

Flutter 曾用自研 HMS/Mi MethodChannel，经 `UcgPushRegistrationService` → `POST /ucg/app/api/push/register`，并卡在「登录 + 绑微信 + `activateUcgHomeSession`（含等 UCG chat WS）」。

Go 已完成 `extract-push-service`：独立 `push-service`，App 路径 **`POST /app/api/push/register|unregister`**；JWT `wxId` = 登录用户 ID，**不**要求微信 unionid。旧 UCG 推送路由已删。预测临近复用全局 token 扇出。

本变更在客户端：`china_push` 取 Android token + 对齐全局 API/门闸 + 预测 pending 同步。

## Goals / Non-Goals

**Goals:**

- Android：`china_push` → 映射 `hms|mipush`（可映射时）→ `POST /app/api/push/register`。
- iOS：原生 APNs → 同一全局 register。
- 推送注册与 UCG 会话 / chat WS /「绑定微信」检查解耦；**仅需已登录**。
- 预测 pending 全量同步；不依赖 register 成功。
- 拆除自研 Android HMS/Mi 栈。

**Non-Goals:**

- 一期不新增 Go oppo/vivo/honor Sender。
- 不做未匹配厂商专用策略（无 key / 映射失败自然失败）。
- 不强制通知点击深链 UI。
- 不把 push-service 实现迁回客户端。

## Decisions

### D1. 包名 `china_push`

Android 唯一 OEM 取 token 实现；密钥经 `push.properties` / `agconnect-services.json` / `libs/*.aar`（gitignore）。

### D2. manufacturer → channel（一期）

| china_push manufacturer（如 HMS / MI） | register `channel` |
|----------------------------------------|--------------------|
| HMS / huawei                             | `hms`              |
| MI / xiaomi / redmi                      | `mipush`           |
| HONOR / OPPO / VIVO 等                   | **不调用 register**（打日志） |

未配 key 导致 init 失败：跳过，不崩溃。

### D3. 全局注册 API 与门闸（取代旧 D3）

- 路径：`POST /app/api/push/register`、`POST /app/api/push/unregister`（`ApiClient` + Bearer，**非** `UcgApiClient`）。
- Body：`channel`、`token`、`deviceKey`（与 Go `AppPushRegisterPostReq` 一致）。
- 门闸：**`session.isLoggedIn` 即可**；**不得**再要求 `isUcgWxAccountBound`；**不得**等待 UCG WS。
- 触发：登录成功 / 冷启已登录后尽早 `ensureRegistered`（主壳或 gateway bootstrap 完成后均可）；token 刷新回调补注册；登出 `unregister`。
- `activateUcgHomeSession`：**移除** push 步骤，仅 unread + chat WS。
- 保留：stable `deviceKey`、single-flight、失败短熔断、同 fingerprint 跳过重复 POST。

### D4. iOS / Android 分流

```
iOS     → 原生 APNs MethodChannel → 全局 register (apns)
Android → china_push only       → 全局 register (hms|mipush)
```

### D5. 预测 pending

- `PUT /device/api/predict/imminent/pending`；空 `events` 清空。
- 与 push register 解耦；无 token 时服务端扇出自然跳过。

### D6. 模块归属

推送注册实现应从「仅 UCG 专属」改为全局（可保留文件路径渐进改名，或以 `lib/push/` / 去 Ucg 前缀为准）；调用方不得再经 `/ucg/app/api/push`。

### D7. 拆除范围（Android）

自研 `UcgHms*` / `UcgMi*` / mipush sourceSets 等已拆除或须保持拆除；README 对齐全局路径与 china_push。

## Risks / Trade-offs

- **[Risk] 旧 path 仍被调用** → Mitigation：全文去掉 `/ucg/.../push`；联调抓包确认 `/app/api/push/register`。
- **[Risk] china_push / Gradle** → Mitigation：release 构建验证。
- **[Risk] 映射表与 manufacturer 字符串** → Mitigation：对照插件实际返回值（HMS/MI 等）。
- **[Trade-off] 一期不全厂商** → 接受。

## Migration Plan

1. china_push + 拆除自研栈（可已完成）。
2. 注册改 `/app/api/push/*` + 登录门闸 + 从 UCG 会话拆出。
3. 预测 pending（可已完成）。
4. release 构建；真机：仅登录即可 register；预测 pending + 可选到点推送。

## Open Questions

- （已关闭）Go 三通道；无 key 自然失败；iOS APNs；`china_push`；全局 `/app/api/push/register`；wxId=登录用户非绑微信；与 UCG 解绑。
