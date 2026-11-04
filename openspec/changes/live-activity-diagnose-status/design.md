## Context

`settings-live-activity-status` 已提供锁屏通知入口、显态与手动重试。真机联调中超时文案「等待系统 Push-to-Start token 超时，未能完成上报」会掩盖：系统未吐 token、HTTP register 失败、仅一类 attributes 成功等情况。账户/描述文件已排除为当前主因后，需要客户端把阶段结果拆开，便于无 logcat 排障。

## Goals / Non-Goals

**Goals:**

- 重试结束时失败原因可分类、可复制，且不互相覆盖。
- 分 `imminent` / `timing` 展示：是否收到过 PTS 事件、是否 register 成功。
- 页面提供简短诊断摘要（版本、listening、原生 deliver 计数若可得）。
- 保留既有自动 register 时机与 Go 契约。

**Non-Goals:**

- 服务端查询「token 是否已入库」接口。
- 改变 Push-to-Start 自动触发策略；大幅重构 Bridge 观察生命周期（可做小改：计数 / 不覆盖错误）。
- Android / 新账户 Capability。

## Decisions

1. **失败类别枚举（对用户短文案 + 内部 code）。**  
   至少：`no_system_token`、`register_http_failed`、`partial_attributes`、`timeout_kept_prior_success`、`system_disallowed`、`os_unsupported`。  
   Timeout 路径：若本轮已记录 HTTP 错误 → **保留 HTTP 文案**，不得改写成「等系统 token」；若原生 deliver 计数为 0 且无 HTTP → `no_system_token`；若有 deliver 无成功 → 优先展示 register 错或 `partial_attributes`。

2. **每类 attributes 双计数。**  
   Dart：`ptsEventSeen`（收到 `push_to_start` 事件，不论 HTTP）与 `ptsRegisterOk`（持久化成功）。UI 分行展示。

3. **原生 deliver 计数。**  
   Bridge 在 `deliver` push_to_start 时累加；`getSystemStatus`（或 `getDiagnostics`）返回 `pushToStartDeliverCount`（本进程）。用于区分「系统未吐」vs「吐了但 Dart 未处理」。

4. **可复制诊断块。**  
   设置页下方除 lastError 外，提供一行/多行 `SelectableText` 摘要，例如：`ios=18.x listening=1 ptsDeliver=0 immSeen=0 immOk=0 timSeen=0 timOk=0 err=no_system_token`。仍禁止 token 明文。

5. **不拉长默认超时为主修复。**  
   诊断优先；超时秒数可略增（如 15s）但非本变更核心。

## Risks / Trade-offs

- [文案变长] → 主标题仍短；细节放下方可复制区。  
- [原生计数只反映本进程] → 杀进程清零；与持久化 Ok 时间戳互补。  
- [仍无法证明服务端已存] → 接受；HTTP 200 即客户端侧成功。

## Migration Plan

1. 随 App 发版；无数据迁移。  
2. 回滚：恢复笼统超时文案即可。

## Open Questions

- 无（失败分类以上表为准；实现时可微调中文措辞）。
