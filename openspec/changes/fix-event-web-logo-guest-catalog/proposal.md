# Proposal: fix-event-web-logo-guest-catalog

## Why

Web 上事件 logo 使用默认 `Image.network` 拉取 CDN 字节流，在 `resorce.cuplay.top` 无 CORS 头时失败；游客首次进 Home 时事件目录仅 Splash 单次 refresh，失败或无 Home 重试导致底部长期显示「暂无可用事件按钮」。

## What

- Web `EventLogo` 使用 `WebHtmlElementStrategy.prefer` 展示 CDN 图
- 事件目录 provider 暴露 loading / remoteLoadAttempted 状态
- 游客与已登录用户进 Home 后均 `bootstrap` 拉取 catalog（最多 3 次），加载中显示 progress 而非空态文案

## Scope

- 客户端；不阻塞 Splash；不改网关/CDN
