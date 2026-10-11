## Why

兄弟仓 go 已提供 `POST /device/app/api/xiaozhi-mcp/bindings/{id}/reconnect`（ForceRestart），Hub 在 `connected=false` 时可点「重连」。Flutter 小智音箱页仅展示未连接红点，无法主动触发重拨，只能等待服务端退避。

## What Changes

- 绑定列表在 `!connected` 时展示「重连」入口；已连接不展示。
- 点击后调用上述 reconnect API（Bearer）；成功 toast「已触发重连」并刷新绑定列表。
- 接口成功 **不** 保证立刻 `connected=true`；失败走既有错误 toast，不改本地绑定行。
- **不** 因体验/永久开通过期而禁用重连（与 go：active 归属即可对齐）。
- 防连点（按钮 loading / single-flight）。

## Capabilities

### New Capabilities

- （无）

### Modified Capabilities

- `xiaozhi-speaker-binding`: 未连接态 MUST 提供手动重连，并对接 go reconnect App API（能力定义见未归档 `xiaozhi-speaker-app-binding`）。

## Impact

- **代码**：`xiaozhi_mcp_binding_repository.dart`、`xiaozhi_speaker_screen.dart`（`_BindingCard`）。
- **依赖**：gateway 已反代的 device reconnect；无 Android 原生改动。
- **关联**：依赖绑定列表与 `connected` 字段已存在。
