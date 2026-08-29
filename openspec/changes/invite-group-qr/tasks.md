## 1. 数据

- [x] 1.1 catalog 模型解析顶层 `inviteGroupQrUrl`（相对 path 拼网关基址若需要）

## 2. UI

- [x] 2.1 开通中心页级：居中文案「加入微信群获取邀请码」+ 下方二维码；无 URL 不展示
- [x] 2.2 二维码加载失败时整块隐藏（含文案）

## 3. 验收

- [x] 3.1 与 Go 联调自检；`openspec validate invite-group-qr --strict`
