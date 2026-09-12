## Why

开通中心页顶的「加入微信群获取邀请码」把获取路径挤在商业开通列表之上，用户难理解邀请码来自广场同伴；预测槽位已满仅「去开通」跳转，无法在原地兑码。需要把「如何拿码」独立成页，并让 Hub 与预测满槽共用同一套邀请码弹窗（可进获取页 / 可兑码）。

## What Changes

- **移除**开通中心页级微信群二维码区块（`_InviteGroupQrBlock`）。
- **新增**「如何获取邀请码」页：说明邀请码来源（广场→我的）；方式 1 进广场拿码（按钮关闭当前页并清掉 Hub 栈，切到 UCG）；方式 2 官方微信群（仅 `inviteGroupQrUrl` 非空时展示二维码）。
- **改造**邀请码输入弹窗：取消改为「获取邀请码」；Hub 与预测满槽 **共用** feature_unlock UI 小模块内组件，标题/正文/确认键文案可注入。
- **改造**预测槽位已满弹窗：标题不变；正文固定「输入邀请码，永久激活一个槽位」+ 输入框；确认键「激活」——有码则兑换 `prediction_unlock`，成功 toast 开通成功并自动打开当前开关；无码则跳转开通中心（原逻辑）。Hub 侧空码点兑换仍静默关闭。
- **进广场**：`go('/home')` + `HomePagerPage.ucg`；UCG 未合格时由现有资格壳拦住，不做额外特判。

## Capabilities

### New Capabilities

- `invite-code-howto`：如何获取邀请码页、共享邀请码弹窗结果语义、从弹窗进入该页。

### Modified Capabilities

- `invite-group-qr-hub`：群二维码从开通中心页级迁到「如何获取邀请码」页；Hub 不再展示页级 QR。
- `prediction-toggle-slot-gate`：满槽由纯 confirm 改为带输入的共享弹窗；空码激活才进开通中心；有码兑码并自动开开关。
- `feature-unlock-hub`：去掉页级 QR；邀请码弹窗左键改为「获取邀请码」并进入获取方式页。

## Impact

- Flutter：`feature_unlock_hub_screen.dart`、`smart_prediction_screen.dart`、新增 `app/lib/ui/feature_unlock/`（共享弹窗 + 如何获取页）、`app_router.dart` 路由、catalog `inviteGroupQrUrl` 消费点迁移。
- 无后端契约变更（有效期间仍以 `inviteGroupQrUrl` 非空为准）。
- 规格：改写 `invite-group-qr-hub` / `prediction-toggle-slot-gate` / `feature-unlock-hub` 相关行为；新增 `invite-code-howto`。
