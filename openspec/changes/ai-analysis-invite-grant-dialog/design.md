## Context

- AI 分析页合格未开通 CTA 现为直跳 `/features/unlock`。
- 邀请/广告实际授予天数已在服务端 `feature_def.duration_days`（`ActivateFeature` 邀请/广告通道同源读取），但 **catalog 响应不包含该项**；客户端只能看到付费 `products[].durationDays`。
- 运营需要能**分别**调整邀请与广告授予天数；用户选择方案 A：catalog 项级 `inviteDurationDays` / `adDurationDays`。
- 服务端仓库：`d:\work\go_ai_talk`；客户端：本仓库 `app/lib`。弹框复用 `showInviteCodeDialog`；`TextEditingController` 已在弹层 State 内 dispose。

## Goals / Non-Goals

**Goals:**

- DB + Admin + Activate 支持独立邀请/广告授予天数。
- App catalog 下发 `inviteDurationDays` / `adDurationDays`（0=永久）。
- AI 分析页：共享邀请码弹框 → 空码开通中心 / 有码 redeem care-alert → 刷新留页。
- 天数文案禁止用付费 SKU 冒充。

**Non-Goals:**

- 不改预测槽位满额邀请弹框语义。
- 不强制本 change 内改开通中心广告文案（可选跟进）。
- 不改 redeem / ad/complete 请求体契约。
- 不在本仓库内嵌 go 代码树；实现时改 `go_ai_talk`。

## Decisions

1. **拆列而非仅暴露旧列**  
   - 新增 `feature_def.invite_duration_days`、`feature_def.ad_duration_days`。  
   - 迁移：两列初始值 = 现有 `duration_days`。  
   - `ActivateFeature`：`invite_code` 读 `invite_duration_days`，`ad` 读 `ad_duration_days`。  
   - 保留 `duration_days` 一版兼容（Admin 旧字段可同步写两列或标记废弃）；推荐 Admin API 改为读写两新列，旧 `durationDays` 写入时双写。  
   - 备选（未采纳）：只在 catalog 暴露同一 `durationDays`——无法分别改邀请/广告。

2. **JSON 字段名**  
   - App：`inviteDurationDays`、`adDurationDays`（lowerCamelCase，与现有 catalog 一致）。  
   - 缺省/省略：客户端按「未告知」弱化文案，不得回落 products。

3. **AI 分析弹框**  
   - 复用 `showInviteCodeDialog`：`title: 智能分析`，`confirmLabel: 开通`。  
   - body：`恭喜获得试用资格：输入邀请码即可兑换 ${featureDurationCopy(inviteDurationDays)} 智能分析使用额度。`（0→「永久」）。  
   - HowTo → `/features/invite-howto`；空码 Submitted → `/features/unlock`；非空 → `redeemInviteCode(featureId: care_alert_smart_remind)` → Toast + `featureCatalog` refresh。  
   - 对齐预测满额分支，而非开通中心「空码静默关」。

4. **跨仓落地**  
   - OpenSpec 住 flutter 仓；tasks 明确 go_ai_talk 路径。先合服务端再发客户端，或客户端对缺字段降级。

## Risks / Trade-offs

- [旧 Admin / 脚本仍只写 duration_days] → 迁移后 Activate 改读新列；双写或一次性 SQL 校准；文档注明废弃路径。  
- [客户端先于服务端发版] → 弱化「x 天」文案，功能仍可用。  
- [care-alert 未配 invite_code] → 弹框仍可展示；redeem 失败 Toast 服务端 message。

## Migration Plan

1. go_ai_talk：DDL 加列 + backfill；改 Activate / Admin / catalog DTO；清 feature_def Redis 缓存。  
2. 部署服务端。  
3. Flutter：解析字段 + AI 分析弹框。  
4. 回滚：客户端忽略字段即可；服务端回滚 Activate 需同步回读旧列（尽量避免已发新客户端依赖新列后回滚）。

## Open Questions

- 无阻塞项。Admin 旧 `durationDays` 是否长期双写可由实现时取最小改动（建议双写一版）。
