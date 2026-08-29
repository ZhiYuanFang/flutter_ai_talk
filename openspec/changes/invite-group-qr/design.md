## Context

对照 Go `invite-group-qr`：catalog 顶层 `inviteGroupQrUrl`；图为网关 apk 路径下的 `er_code.png`。开通中心需页级展示。

## Goals / Non-Goals

**Goals:** 有 URL 则展示文案 + 二维码；无则整块不渲染。

**Non-Goals:** 不实现上传；不算有效期（信服务端）；不改兑码逻辑。

## Decisions

### D1：页级区块

- 放在功能列表上方或列表与月卡之间的固定区域；文案在图正上方横向居中。

### D2：相对 URL

- 若服务端返回相对 path，客户端按现有网关基址拼接（与 APK/静态资源一致）。

## Risks / Trade-offs

- [图加载失败] → 整块隐藏（含文案），避免「有标题无图」。

## Migration Plan

- 随 Go 发版。

## Open Questions

- 无。
