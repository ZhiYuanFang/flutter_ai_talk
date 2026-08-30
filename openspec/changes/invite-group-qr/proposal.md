## Why

服务端将在有效期内通过 feature catalog 下发微信群二维码 URL。开通中心须在页级展示该二维码及引导文案，方便用户加群获取邀请码。列表内缩略图偏小，用户扫码不便，需支持点击放大查看。

## What Changes

- 解析 catalog 顶层 `inviteGroupQrUrl`（有则展示，无则整块不渲染）。
- 开通中心页级区块：正上方横向居中「加入微信群获取邀请码」，下方展示二维码图。
- 二维码图片加载失败时整块（含文案）隐藏。
- 点击二维码图打开全屏可缩放预览（复用既有 `showUcgPhotoLightbox`）；仅图可点，不加「点击放大」副文案。
- 不因 VIP / 已激活状态隐藏该区块（只要 URL 存在即展示）。
- 对照 Go `invite-group-qr`。

## Capabilities

### New Capabilities

- `invite-group-qr-hub`：开通中心页级群二维码展示、失败整块隐藏、点击放大。

### Modified Capabilities

- `feature-unlock-hub`（未归档商业化增量）：增加页级 QR 区块；以本 change 为准。

## Impact

- `feature_unlock_models` / hub screen / 可选 repository 解析。
- 复用 `ucg_media_viewer.showUcgPhotoLightbox`（与历史媒体条等跨模块用法一致）。
- 依赖 Go catalog 字段；图片走网关 `/device/app/apk/er_code.png`（可带 `?v=`）。
- 不新建测试。
