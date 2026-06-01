# Proposal - Suppress WS Banner when Unbound

## Why

当用户尚未绑定宝宝信息时，主页正处于初次引导阶段。此时展示“历史连接断开”的 Banner（`HomeHistoryWsStatusBanner`）会显得突兀且分散注意力。由于未绑定宝宝时通常也没有历史记录需要实时同步，因此在该状态下隐藏此 Banner 可以使界面更加整洁且聚焦于引导工作。

## What Changes

- 修改 `HomeScreen` 的逻辑，使得在 `needsDeviceBind` 为 true（即尚未绑定宝宝）时，强制隐藏 WebSocket 断开连接的提示 Banner。

## Capabilities

### New Capabilities

- `home-ws-status-display`: 定义主页 WebSocket 连接状态（如连接中、断开、重连等）的展示策略。

### Modified Capabilities

- 无

## Impact

- **app/lib/ui/home_screen.dart**: 修改 `showWsDisconnectBanner` 的计算逻辑。
