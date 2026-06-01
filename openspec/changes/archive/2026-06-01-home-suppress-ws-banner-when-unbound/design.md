# Design - Suppress WS Banner when Unbound

## Context

在 `HomeScreen` 的 `build` 方法中，`showWsDisconnectBanner` 变量控制着 `HomeHistoryWsStatusBanner` 的显示。目前的逻辑虽然考虑了 `showBindBanner`，但在“未绑定宝宝且无历史记录”的情况下，Banner 仍然可能显示。

## Goals / Non-Goals

**Goals:**
- 在用户未绑定宝宝信息时，强制隐藏 WebSocket 断开连接提示 Banner。

**Non-Goals:**
- 不改变 WebSocket 的连接或重连触发逻辑。
- 不影响正常绑定状态下的断连提示。

## Decisions

### 1. 修改 `showWsDisconnectBanner` 逻辑

我们将修改 `app/lib/ui/home_screen.dart` 中的 `showWsDisconnectBanner` 计算公式。

**原逻辑**:
```dart
final showWsDisconnectBanner = loggedIn && !showBindBanner && !_wsReady;
```

**新逻辑**:
```dart
final showWsDisconnectBanner = loggedIn && !needsDeviceBind && !_wsReady;
```

**理由**: `needsDeviceBind` 是判断“是否已绑定宝宝”的最直接依据。即使 `showBindBanner` 为 false（例如在显示全屏引导时），只要 `needsDeviceBind` 为 true，我们就应该隐藏断连提示。

## Risks / Trade-offs

- **[Risk] 逻辑冗余** -> **Mitigation**: 检查 `showBindBanner` 的计算方式。目前 `showBindBanner` 是 `needsDeviceBind && historyItems.isNotEmpty`。直接使用 `needsDeviceBind` 更加健壮。
