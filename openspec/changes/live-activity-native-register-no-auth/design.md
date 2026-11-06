## Context

`live-activity-token-early-observe` 已把 ActivityKit 观察提前到 `didFinishLaunching`，并用内存 inbox 缓解 channel/Dart 未就绪。HTTP 仍只走 Dart + Bearer；设计明确接受「Dart 赶不上则靠打开 App 补扫」。真机与产品反馈表明：App killed → Push-to-Start 出锁屏后，activity token 常仍不上报；打开 App 也不自动补报；要等下次推送轮转 token 才上传。对端无 activity token 则 update/end 失败，清场/pending 易堆积。

Apple 在 Push-to-Start 起 LA 时会短暂唤醒主 App；该窗口内原生可读 Keychain、发 URLSession，但 Flutter 登录壳不可靠。产品威胁模型认定：对该 register 接口免鉴权，最坏为无法自动关 LA，利大于弊；拒绝在原生维护 accessToken/refresh。

对端权威实现在 `go_ai_talk` change `live-activity-register-no-auth-go`；本仓改客户端与规格，Go 以 twin 联调对齐。

## Goals / Non-Goals

**Goals:**

- 唤醒窗口内原生直报 `live-activity/register`（含 `tokenKind=activity`），不依赖 Flutter/Bearer。
- Body 必带非零 `wxId`；Go 免 JWT 拦截，按 `wxId` 落库。
- 登录写 / 登出清原生可读 `wxId`；无 `wxId` 则跳过原生 POST。
- 明确取消「打开 App 自动补 activity token」硬兜底。
- 保留 early observe；前台自然 token 事件仍可上报。

**Non-Goals:**

- 原生 accessToken / refresh / 会话迁原生。
- pending 落盘跨进程。
- iOS 18 channel/broadcast 替代 per-activity token。
- 本仓修改 Go 源码（仅契约与联调说明；twin 另仓落地）。
- Android/Web LA。
- 恢复本地 `Activity.request`。

## Decisions

1. **主路径：原生 URLSession POST，免 Bearer。**  
   在 `PredictLiveActivityBridge`（或并列小模块）于 `deliver`/token 到手后，若有缓存 `wxId` 则直接打 register；不经 MethodChannel 等待 Dart。  
   备选：Dart 后台 isolate —— 仍依赖引擎，放弃。  
   备选：原生带 Bearer —— 需刷新，短窗口不可靠，产品明确否决。

2. **信任根：body.`wxId`，服务端不做 token 鉴权。**  
   登录成功后把 JWT 中的非零 `wxId` 写入与原生共享的 Keychain（accessibility 兼顾后台唤醒，如 AfterFirstUnlock）；登出删除。  
   备选：仅 `deviceKey` 反查 —— 更安全但多查表；产品选择自报 `wxId` 换简单与成功率。  
   威胁：公开写面可污染 token；产品接受「残留至超时」。

3. **请求体字段。**  
   `wxId`（必填非零）+ 既有 `deviceKey`、`tokenKind`、`attributesKind`、`token`；`activity` 时 `activityId` 非空。原生与 Dart（若仍 POST）共用该契约。Base URL 与现网环境一致（原生可读配置或编译期/App Group）。

4. **取消打开 App 自动补 activity 硬兜底。**  
   不新增 resume/`startIfEligible` 触发的 `restartListening` 专为补 activity；不作「打开 MUST 补报」验收。  
   保留：进程内观察已挂时的自然 `pushTokenUpdates`；设置页手动重试 MAY 保留排障。  
   early-observe 中「打开后 B 补扫作 Dart HTTP 兜底」叙事在本 change 作废为 Non-Goal。

5. **Dart 路径降级为可选补传，不再是 activity 唯一通道。**  
   可改为同样带 `wxId`、不依赖 Bearer 成功；或仅保留 PTS/诊断。须避免与原生重复刷屏：成功身份缓存（`wxId|deviceKey|kind|attr|activityId|token`）两边或至少原生侧做跳过。

6. **无缓存 wxId 时原生不 POST。**  
   未登录过或已登出：跳过并打诊断日志（勿打 token）。不伪造 wxId。

7. **对端 twin。**  
   Gateway 对该 path 放行；handler 读 body.`wxId` upsert；不再要求 JWT。本仓 tasks 含联调检查清单，不改 Go 文件。

## Risks / Trade-offs

- [系统未唤醒主 App] → 原生无机会 POST；接受偶发残留至超时；不恢复打开硬兜底。  
- [Keychain 锁屏未解锁读不到 wxId] → 选 AfterFirstUnlock 等；失败则跳过并 log。  
- [公开接口被刷/污染] → 产品接受；可选后续限流（非本 change 必做）。  
- [原生与 Dart 双 POST] → 身份幂等；对端 upsert。  
- [登出后旧 wxId 未清] → 登录/登出路径必须对称写清。  
- [Go twin 未同步上线] → 客户端先发会 401/失败；须约定同发或特性开关。

## Migration Plan

1. 对端先或同发：放行 + 接受 `wxId` 落库。  
2. 客户端：缓存 wxId → 原生 register → 调整 Dart 门闸文案/逻辑 → 更新 `LIVE_ACTIVITY.md`。  
3. 真机：killed → Push-to-Start → **不打开 App** → 服务端应出现对应 `wxId` 的 `tokenKind=activity`。  
4. 回滚：关原生 POST，恢复仅 Dart Bearer（对端可再启鉴权）；推送堆积风险回到变更前。

## Open Questions

- （已定）免鉴权 + body.`wxId`；不做原生 Bearer。  
- （已定）不做打开 App 自动补 activity 硬兜底。  
- Dart 是否完全停止 LA register、仅原生：实现时可保留 Dart 同契约补传，tasks 以「原生为主路径」为准。  
- 限流：本 change 不强制；对端后续可加。
