## Context

Go twin `live-activity-clear-activity-on-app-open`：删除 ack 超时链路；新增鉴权 `POST /app/api/push/live-activity/activity/clear`（Bearer，`deviceKey`，仅删该机 `token_kind=activity`，不同拍 start）。产品确认空窗可接受。

本仓 `live-activity-update-ack` 已在 Runner 挂 `contentUpdates`、ContentState.`ack`、原生免鉴权 ack POST。该方向与 Go 回滚冲突，须拆除。现有 `app.dart` / 各 shell 已有 `WidgetsBindingObserver` resumed 钩子；副作用 HTTP 须 single-flight（见 `project.md`）。

Clear **必须 Bearer**，故 HTTP 走 Dart 鉴权栈；原生只负责「本机是否还有统一 LA」查询（ActivityKit），不得用 register 免鉴权上下文冒充 clear。

## Goals / Non-Goals

**Goals:**

- 拆除 ack 解码、观察回执、原生 ack POST 与文档。
- 登录态 + resumed/冷启动：无 `BabyLiveActivityAttributes` 活动 → 鉴权 clear。
- MethodChannel（或既有 Bridge 通道）查询「是否有活动中 LA」。
- clear 副作用 HTTP：single-flight、短窗合并、失败可观测且不崩。

**Non-Goals:**

- 划掉瞬间后台探测；Extension 内 HTTP；Android LA；改 register / UI 列表样式；clear 后本地立刻 start。

## Decisions

1. **谁发 clear：Dart + Bearer，不是原生免鉴权**  
   与 Go「clear 必须鉴权、不得豁免」对齐。原生仅答「有没有 LA」。  
   *备选：原生带缓存 wxId 打 clear — 否决（Go 要求 Bearer / 内部头身份）。*

2. **有无 LA 的判定**  
   `Activity<BabyLiveActivityAttributes>.activities` 过滤仍处于 active/可展示态的条目（与 Bridge 观察同一 Attributes）。空集合 → 视为不存在 → 允许 clear。  
   *备选：仅看 ended — 否决；用户划掉后 activities 通常为空，以「无活动」为准。*

3. **触发点**  
   - 主 App 进入 `resumed` 且已登录（有可用 Bearer）。  
   - 登录成功后补跑一次（覆盖「先打开后登录」）。  
   未登录跳过。约数秒短窗合并连续 resumed（对齐 UCG shell resume bundle 思路）。

4. **拆除 ack**  
   删除 `handleContentAck`、`contentUpdates` 仅为 ack 的观察（若 token 观察仍需可保留 pushToken 路径）、ContentState.`ack` 字段、`postAck`、进程内 ack 去重、文档 ack 节。ContentState 继续容忍未知键亦可，但代码侧不再声明/解码 `ack`。

5. **副作用 HTTP 治理**  
   clear 调用 MUST：进程内 in-flight Future 复用；成功后短窗内同 deviceKey 不重复打；失败打 `AppDebugLog`（新 tag 须三联改若新增）；catch 不得静默；不得在 provider 创建时无条件自动连打。

6. **与进行中的 `live-activity-update-ack`**  
   若该 change 未合入：以本变更为准，勿再实现 ack。若已部分合入：本变更任务负责回滚那些 diff。

## Risks / Trade-offs

- [空窗空气 update] → 产品已接受；invalidToken 仍可能提前自愈。  
- [误判无 LA 而 clear] → 下次推送变 start，可能闪一下；判定须与 Attributes 一致。  
- [未登录长时间] → 无法 clear，空窗延长；登录后补跑。  
- [Go 未上 clear 先发 Flutter] → 404；须同发或 Go 先行。

## Migration Plan

1. 与 Go 同发：Flutter 去 ack + 接 clear；Go 下线 ack + 上线 clear。  
2. 更新 `LIVE_ACTIVITY.md`。  
3. 回滚：停调 clear 仅回到「脏 activity 直至其它路径清理」；勿恢复 ack（Go 已删）。

## Open Questions

- （无）空窗可接受、clear 须鉴权、Dart 发 HTTP 已确认。
