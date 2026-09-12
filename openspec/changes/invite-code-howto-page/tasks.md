## 1. feature_unlock 小模块与路由

- [x] 1.1 新建 `app/lib/ui/feature_unlock/`：共享邀请码弹窗（可注入 title / body / confirmLabel；左键「获取邀请码」；controller 归弹层 State；确认 pop 修剪后字符串）
- [x] 1.2 新建「如何获取邀请码」页：来源说明、进广场 CTA、条件微信群 QR（复用 URL 解析 + lightbox；失败整块隐藏）
- [x] 1.3 注册路由（如 `/features/invite-howto`，登录要求对齐 `/features/unlock`）；进广场：`go('/home')` + `requestPage(HomePagerPage.ucg)`

## 2. 开通中心

- [x] 2.1 删除页级 `_InviteGroupQrBlock` 及其在 Hub 的渲染
- [x] 2.2 `_openInviteDialog` 改用共享弹窗；「获取邀请码」push howto；非空码 redeem；空码静默关闭；移除私有 `_InviteCodeDialogBody`

## 3. 预测槽位满

- [x] 3.1 `_trySetForecastEnabled` 满槽改为共享弹窗（标题「预测槽位已满」、正文「输入邀请码，永久激活一个槽位」、确认「激活」）
- [x] 3.2 分支：howTo → howto 页；非空码 → redeem `prediction_unlock` → toast 开通成功 → refresh catalog → `setEnabled` 当前事件；空码激活 → `push('/features/unlock')`

## 4. 验收

- [x] 4.1 手工路径：Hub 邀请弹窗 → 获取邀请码 → 进广场清栈；有/无 `inviteGroupQrUrl` 时 howto 页微信群区块；预测满槽空码进 Hub、有码兑成功自动开开关
- [x] 4.2 `openspec validate invite-code-howto-page --strict`
