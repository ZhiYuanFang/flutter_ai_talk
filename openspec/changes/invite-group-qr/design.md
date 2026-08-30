## Context

对照 Go `invite-group-qr`：catalog 顶层 `inviteGroupQrUrl`；图为网关 apk 路径下的 `er_code.png`。开通中心需页级展示；缩略图需可点进全屏便于微信扫码。

## Goals / Non-Goals

**Goals:** 有 URL 则展示文案 + 二维码；无则整块不渲染；加载失败整块隐藏；点击图打开全屏可缩放预览。

**Non-Goals:** 不实现上传；不算有效期（信服务端）；不改兑码逻辑；不做「点击放大」提示文案；不做保存到相册；不做 Hero 过渡。

## Decisions

### D1：页级区块

- 放在功能列表上方或列表与月卡之间的固定区域；文案在图正上方横向居中。

### D2：相对 URL

- 若服务端返回相对 path，客户端按现有网关基址拼接（与 APK/静态资源一致）。

### D3：点击放大复用 lightbox

- 仅二维码图可点（文案不可点），调用 `showUcgPhotoLightbox(context, urls: [qrUrl])`。
- 与广场/历史媒体同一套 fade + `InteractiveViewer` 捏合缩放，避免另造 Dialog。

### D4：加载失败整块隐藏

- `Image.network` `errorBuilder` 触发后整块（含文案与 panel）不渲染，避免「有标题无图」。

## Risks / Trade-offs

- [图加载失败] → 整块隐藏（含文案），避免「有标题无图」。
- [跨模块依赖 lightbox] → 可接受；`ui/` 已有同类引用先例。

## Migration Plan

- 随 Go 发版；放大查看为纯客户端增量，无服务端契约变更。

## Open Questions

- 无。
