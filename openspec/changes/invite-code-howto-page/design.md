## Context

开通中心当前在列表上方渲染 `_InviteGroupQrBlock`（catalog `inviteGroupQrUrl`）；邀请码弹窗为私有 `_InviteCodeDialogBody`（取消 / 兑换）。预测满槽走 `showGlassConfirmDialog`，确认后 `push('/features/unlock')`。广场入口已有 `homePagerRequestProvider` + `HomePagerPage.ucg`；UCG 未合格由 `ucgEligibilityStateProvider` 资格壳展示。

弹框 `TextEditingController` 必须由弹层 State 持有并 dispose（见 `openspec/project.md`）。

## Goals / Non-Goals

**Goals:**

- 独立「如何获取邀请码」页承载来源说明、进广场 CTA、条件微信群 QR。
- Hub 去掉页级 QR；邀请弹窗左键「获取邀请码」进入该页。
- Hub 与预测满槽共用 feature_unlock UI 小模块内邀请码弹窗（标题/正文/确认文案可注入）。
- 预测满槽：有码兑 `prediction_unlock` 成功后 toast 并自动开当前开关；无码「激活」进开通中心。
- 「进广场」清掉获取页与 Hub 栈，落到 `/home` UCG 页。

**Non-Goals:**

- 不新增「群有效期」API 字段。
- 不改 redeem HTTP 契约与 `featureId` 规则。
- 不改 UCG 资格判定本身。
- 不新建 `**/test/**` 测试文件。

## Decisions

### D1：共享模块落点 `app/lib/ui/feature_unlock/`

- 放置共享弹窗（如 `invite_code_dialog.dart`）与「如何获取邀请码」页（如 `invite_code_howto_screen.dart`）。
- Hub / 预测仅调用公开 API，删除 Hub 内私有 `_InviteCodeDialogBody` / `_InviteGroupQrBlock`（QR 逻辑迁到 howto 页）。
- **备选**：塞进 `app_glass_overlay` — 拒绝，以免通用 overlay 耦合商业开通文案。

### D2：弹窗结果语义

- 三态：`howTo` | `code(String)` | 关闭（空兑换 / 屏障外点）。
- Hub：`howTo` → push howto；非空 `code` → redeem；空码兑换静默结束。
- 预测：`howTo` → push howto；非空 `code` → redeem `prediction_unlock` → refresh → `setEnabled(eventId, true)`；空码点「激活」→ `push('/features/unlock')`。
- 空码策略由调用方解释，组件本身可对「确认」一律 `pop(trimmed)`（含空串），由调用方分支。

### D3：进广场清栈

- howto 页「进入广场」：`context.go('/home')` + `homePagerRequestProvider.requestPage(HomePagerPage.ucg)`，使 Hub / howto 均不留在栈上。
- UCG 未合格：沿用壳层资格页，howto 不做资格预检。

### D4：微信群区块

- 展示条件：解析后的 `inviteGroupQrUrl` 非空；加载失败整块隐藏（行为对齐旧 Hub QR）。
- 相对 URL 仍按 apiBase 拼接；点击图复用 `showUcgPhotoLightbox`。

### D5：路由

- 新增如 `/features/invite-howto`（需登录，与 `/features/unlock` 同档），从弹窗 `push` 进入。

### D6：预测满槽文案

- 标题固定「预测槽位已满」；正文固定「输入邀请码，永久激活一个槽位」（不再分支 defaultCount 句式于该弹窗）。
- `allowedCount == 0` 等仍可先走同一弹窗；空码激活仍进开通中心。

## Risks / Trade-offs

- [共享弹窗空码语义分叉] → 调用方显式分支；规格分别写 Hub / 预测场景。
- [兑码成功但 refresh 竞态导致开关仍被闸] → redeem 成功后 await catalog refresh，再 `setEnabled`；若仍失败 toast 提示用户重试开开关。
- [go('/home') 打断用户从设置进入的深层栈] → 产品要求清 Hub；可接受。

## Migration Plan

- 纯客户端 UI 迁移；发版后 Hub 不再出现页级 QR，旧用户从弹窗「获取邀请码」进入。
- 回滚：恢复 Hub QR 区块与旧 confirm 满槽弹窗。

## Open Questions

- 无（探索阶段已拍板）。
