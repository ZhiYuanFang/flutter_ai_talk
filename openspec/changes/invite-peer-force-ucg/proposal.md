## Why

服务端将邀请码从营销激活码改为用户互推凭证，并把预测开通改为按次累加、原力迁回 UCG、VIP 与永久开通解耦。客户端须同步个人中心（邀请码/等级详情）与开通中心/预测锁展示，否则 App 仍按「激活码全开 + VIP 即已开通」旧语义运作。

## What Changes

- UCG「我的」：展示**我的邀请码**；点击进入邀请详情（用途说明 + 已邀请用户昵称与使用时间）。
- UCG「我的」：等级图标可点；进入积分详情（当前积分、流水、距下一档——**客户端**按阈值计算、获取方式说明）；不再依赖服务端 `forceTier`/`nextTier` 字段做裁决。
- 开通中心预测卡：右上角「已激活 X 个」/「已全部激活」（对比 catalog `allowedCount` 与 `totalActivatableCount`）；未全部激活时**始终**展示支付（现价+删除线原价+/个）与「输入邀请码开通」；**不因 VIP 隐藏**这些入口。
- 开通月卡：写明有效期；卡片**底部悬浮**，与功能列表滚动分离。
- 预测页使用锁：永久 `allowedCount` **或** VIP 有效期内可用（叠加）；VIP 不把永久激活显示为「已全部激活」。
- 文案：激活码→邀请码；支付/广告预期为每次 +1 条，非一次全开。
- 对照兄弟仓 Go `invite-peer-force-ucg` HTTP 契约。

## Capabilities

### New Capabilities

- `ucg-invite-center`：个人中心邀请码展示、详情页、邀请列表。
- `ucg-force-detail`：等级图标入口、积分详情（数字/流水/距升级/获取方式）。
- `feature-unlock-hub-prediction`：预测卡激活数文案、价签、邀请入口、VIP 底栏悬浮与有效期。
- `prediction-vip-overlay-client`：预测锁与 Hub 上 VIP 覆盖 vs 永久激活解耦。

### Modified Capabilities

- `feature-unlock-hub` / `prediction-event-lock` / `feature-entitlement-client`（未归档商业化 change 上的行为增量）：对齐 +1 与 VIP 解耦；以本 change delta 为准。

## Impact

- Flutter：`ucg_profile_*`、`feature_unlock_hub_screen`、`feature_unlock_*`、`smart_prediction_screen`、路由与 repository。
- 依赖 Go `invite-peer-force-ucg` 已暴露：invite mine/invitees、force ledger、catalog `totalActivatableCount`、Redeem/支付/广告 +1。
- 不新建测试文件。
