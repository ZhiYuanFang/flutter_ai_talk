## Context

Go 仓 `add-wx-device-model-usage-column` 将在 `wx.device_model` 存可空型号，并提供 `PUT /device/app/api/user/device-model`（字段 `deviceModel`）。本仓负责：用已有 `device_info_plus` 取机型字符串，在登录后上报。

基线：`openspec/specs/v2.2.2.md`。不扩展 `client-usage-report` body。副作用 HTTP 须符合 `openspec/project.md` 治理。

## Goals / Non-Goals

**Goals:**

- 已登录会话下，解析并上报展示用型号；失败静默。  
- 按账号本地节流 + single-flight + 失败短熔断，避免冷启动/resume 狂打。  
- Android / iOS 覆盖；Web 跳过。

**Non-Goals:**

- 不做服务端枚举对齐。  
- 不改 client-usage 事件字典。  
- 不收集 IMEI / OAID / 广告标识。  
- 不阻塞启动主路径（fire-and-forget）。  
- provider 创建 **不得** 自动发起上报。

## Decisions

1. **解析规则（客户端本地）**  
   - **Android**：`brand`（空则 `manufacturer`）与 `model` 空格拼接；若 `model` 已包含 brand（忽略大小写）则只留 model；总长截断 128；`|`→`/`。期望如 `Xiaomi 2201123G` / `HUAWEI xxx`。  
   - **iOS**：仅用 `utsname.machine` 经本地 map 成营销名（如 `iPhone 12` / `iPad Air 2`）。**map 未命中或模拟器 → 视为解析失败，本次不 PUT**（不上传硬件码、不上传裸 `iPhone`）。新机型需客户端补表后才会出现在列。服务端不维护枚举。  
   - **Web / 其他**：不调用上报 API。

2. **触发挂点（显式，非 provider create）**  
   - `UcgHomeShell`：`sessionProvider.isLoggedIn` 由 false→true 后 `addPostFrameCallback` 异步触发。  
   - `PangbaoApp`：`AppLifecycleState.resumed` 且已登录时异步触发（与现有 resume 同步族并列）。  
   - `ColdStartBackgroundSync`：冷启动已登录时 `unawaited` 触发（listen 不会对「已是登录态」补发）。  
   - 未登录不得调用。

3. **契约**  
   - `PUT /device/app/api/user/device-model`，JSON `{ "deviceModel": "..." }`，Bearer（`ApiClient.putJsonEnvelope`）。  
   - 解析为空则**不请求**；一期不主动传空串清空。

4. **节流 / 治理（按账号）**  
   - SharedPreferences 键（建议）：`device_model_report_wx` / `device_model_report_value` / `device_model_report_at_ms`。  
   - 账号键：JWT `sub`（`readJwtWxId`）；无 wxId 时用字面量 `_anon` 仅作本地键，仍须已登录才请求。  
   - 同一 `wxId` 下，成功上报值相同且距上次成功不足 24h → 跳过。  
   - 换号（wxId 变）→ 视为不同节流桶，可立即报。  
   - **single-flight**：进程内同一时刻仅一次 in-flight。  
   - **失败熔断**：连续失败后短冷却（建议 ≥5min）内不再打；成功清零。  
   - 自触发 ignore：上报成功导致的 session/notify **不得** 再次连环触发（本路径不写 session）。

5. **错误处理与日志**  
   - 对标 `ClientUsageRepository`：无 Toast。  
   - Debug tag **`[DeviceModel]`**：三联改 `app_debug_log.dart`、`logcat_api_http.ps1`、`app/README.md` Debug 表。

6. **依赖**  
   - 复用 `device_info_plus`；不新增原生权限。

## Risks / Trade-offs

- [Risk] Go 未部署导致 404 → 静默 + 熔断，可接受。  
- [Risk] iOS 新机型未入 map → 该账号型号列可能暂时为空或停留上次成功值；接受，靠发版补表。  
- [Risk] 品牌大小写不一致 → 接受直接展示。

## Migration Plan

1. Go 接口上线后发 Flutter。  
2. 回滚：去掉 shell/app 两处触发即可。

## Open Questions

（无阻塞。）
