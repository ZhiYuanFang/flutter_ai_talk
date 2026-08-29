## Why

服务端将在有效期内通过 feature catalog 下发微信群二维码 URL。开通中心须在页级展示该二维码及引导文案，方便用户加群获取邀请码。

## What Changes

- 解析 catalog 顶层 `inviteGroupQrUrl`（有则展示，无则整块不渲染）。
- 开通中心页级区块：正上方横向居中「加入微信群获取邀请码」，下方展示二维码图。
- 不因 VIP / 已激活状态隐藏该区块（只要 URL 存在即展示）。
- 对照 Go `invite-group-qr`。

## Capabilities

### New Capabilities

- `invite-group-qr-hub`：开通中心页级群二维码展示与文案。

### Modified Capabilities

- `feature-unlock-hub`（未归档商业化增量）：增加页级 QR 区块；以本 change 为准。

## Impact

- `feature_unlock_models` / hub screen / 可选 repository 解析。
- 依赖 Go catalog 字段；图片走网关 `/device/app/apk/er_code.png`（可带 `?v=`）。
- 不新建测试。
