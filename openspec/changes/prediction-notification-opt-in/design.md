## Context

全局推送已登录即可 `requestNotificationPermission` + `POST /app/api/push/register`（见 `android-china-push-predict-imminent`）；预测临近 pending 独立同步。用户若在系统设置关闭通知，或首次拒绝，预测页无 UI 召回。设置中心亦无「通知含什么 / 可关」入口。本变更补齐：竖屏引导横条 + 应用层偏好 + 设置说明子页，并让 bootstrap register 尊重偏好 Off。

## Goals / Non-Goals

**Goals:**

- 竖屏预测正文顶横条：未授权且偏好 On 且本会话未关 → 引导开启。
- 横条关闭仅本次会话；横屏永不展示。
- 设置「消息通知」子页：说明范围 + 总开关；Off → unregister 且不再自动 register。
- App resume 后重查系统权限；授权成功则收横条并可 register（偏好 On 时）。

**Non-Goals:**

- 不按品类拆开关（预测 vs 广场）。
- 不改 Go push / imminent API。
- 不做通知点击深链。
- 不强制游客展示横条或设置入口。
- 不新建 `**/test/**`。

## Decisions

1. **双状态模型**  
   - `appNotificationPreferenceEnabled`：持久化（SharedPreferences），默认 **true**（与现网「登录即尝试注册」一致）。  
   - `osNotificationGranted`：只读探测（Android `Permission.notification.status`；iOS 补 status 只读或与现有 channel 对齐）。  
   - 会话 `bannerDismissedThisSession`：内存，进程级。  
   **备选（否决）**：仅依赖 OS 权限、无应用偏好——无法满足「设置里可关」。

2. **横条展示条件**  
   `loggedIn && !kIsWeb && portrait && preferenceOn && !osGranted && !sessionDismissed`。  
   位置：竖屏「接下来3小时」之上（游客引导卡之下，若并存）。  
   CTA：可弹系统授权则 `request`；`permanentlyDenied` 则 `openAppSettings`。关闭按钮仅置会话 flag。

3. **偏好 Off**  
   写偏好 false → `unregister` → bootstrap/`syncAppPushRegistration` 入口处若 Off 则直接 return。横条不展示。  
   偏好 On 且 OS granted → 允许既有 register。

4. **设置子页**  
   路由 `/settings/notifications`（登录门闸，对齐反馈）。说明文案固定列举：预测临近提醒；以及经同一 token 送达的其它服务端可见通知（如实写，避免暗示可分开关）。开关绑定偏好；副操作「打开系统设置」处理 OS 关闭。

5. **日志**  
   新 debug 行为若需独立 tag：按 `openspec/project.md` 三联改（`AppDebugLog` / `logcat_api_http.ps1` / README）；可先复用 `ucgPush` / `AppDebugLog.ucgPush` 以免扩 tag，实现时择一。

## Risks / Trade-offs

- **[Risk] iOS 仅有 request 无 status** → Mitigation：实现时补 MethodChannel 查询；短期可用「未知则当未授权且未会话关闭时出条」需避免误伤，优先补 status。  
- **[Risk] 偏好 Off 后用户仍从系统开通知** → Mitigation：不自动改偏好；子页开关仍为 Off 则不 register，直到用户打开开关。  
- **[Risk] OEM 无 token 但权限已开** → Mitigation：横条只解决权限；通道失败不混进同一催开文案。  
- **[Trade-off] 总开关一并关掉广场类推送** → 产品已接受一期不分品类。

## Migration Plan

- 默认偏好 true：老用户行为与现网一致，仅多横条召回。  
- 回滚：隐藏横条与设置入口；去掉偏好门闸即可恢复「登录即 register」。

## Open Questions

- （已定）关闭横条 = 仅本次会话；横屏不出；设置可关。  
- （已定）仅登录：横条与设置入口。
