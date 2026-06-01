## Context

- **现状**：`HomeScreen` 通过 `feed.isHistoryWebSocketReady` 与 `historyWsReadyStream` 维护 `_wsReady`；AppBar `IconButton` 在断开时显示 `Icons.cloud_off_outlined`（error 色），tooltip「重连历史连接」；发送前 `_ensureHistoryWsForSend` toast 提示右上角重连。
- **布局**：主页 `Column` 自上而下为绑定横幅（可选）→ 今日摘要 → `Expanded`（历史列表 + 语音消息条）→ 输入区顶阴影 → `AnimatedContainer` 底部输入 panel。
- **约束**：不改动 `RemoteFeedRepository` WS 协议；与语音 ASR 连接状态（语音球旁云图标）独立，本变更仅针对**历史** WebSocket。

## Goals / Non-Goals

**Goals:**

- `_wsReady == false` 时，在历史区与输入区之间展示固定文案横幅并可点击重连。
- 连接恢复后横幅消失；重连逻辑与 AppBar 按钮一致。
- 视觉与现有主页 shell / 错误提示风格一致（可读、不挡历史滚动主体）。

**Non-Goals:**

- 改造 WS 重连退避、鉴权首包或服务端推送语义。
- 在趋势页、设置页等其他路由展示同类横幅。
- 首次冷启动尚未尝试建连时的「连接中」态（若 `isHistoryWebSocketReady` 与 connecting 未区分，可统一按未就绪展示横幅，见 Open Questions）。

## Decisions

### 1. 展示条件

- **条件**：`!_wsReady`（与现有 AppBar 图标数据源一致）。
- **位置**：`Expanded` 历史列**之后**、`_buildInputModuleTopShadow` **之前**，作为 `Column` 子节点，全宽 `crossAxisAlignment: stretch`。
- **理由**：用户视线自然从历史滑到输入区，横幅夹在中间最醒目；不占用 AppBar 空间。

### 2. 交互与文案

- **文案**：`连接中断，请点击重连`（与用户要求一致）。
- **点击**：`onTap` → 现有 `_reconnectHistoryWs()`（`feed.reconnectHistoryWebSocket()`）。
- **可选**：重连进行中显示 `CircularProgressIndicator` 或禁用重复点击（若 repository 无 connecting 流，短时 `unawaited` + 本地 `_reconnecting` 标志即可）。

### 3. 组件拆分

- 新建 `HomeHistoryWsStatusBanner`（`home_history_ws_status_banner.dart`）：
  - 参数：`visible`（或调用方仅 `if (!wsReady)` 包裹）、`onReconnect`。
  - 内部：`Material` + `InkWell`，左侧 `Icons.cloud_off_outlined`，中间 `Expanded` 文案，右侧可选 `Icons.refresh`。
  - 颜色：`colorScheme.errorContainer` / `onErrorContainer` 或 `error` 浅底条，与 AppBar error 图标语义一致。
- `HomeScreen` 仅负责状态与插入位置。

### 4. AppBar 图标

- **移除** AppBar 历史 WebSocket 云图标；断开/重连仅通过底部横幅暴露，避免重复入口。

### 5. 与语音区提示的关系

- 语音模式 `_ensureHistoryWsForSend` toast 可保留或改为「请点击下方重连横幅」；实现时二选一更新文案，避免矛盾。

## Risks / Trade-offs

- **[Risk] 横幅占用输入区上方高度** → 使用紧凑单行（约 40–44dp），`AnimatedSize` 显隐避免布局跳动过大。
- **[Risk] 未登录或未绑定 deviceNo 时也显示** → 仅当 `sessionProvider.isLoggedIn` 且已绑定 deviceNo 时展示（与历史列表可见条件对齐）；否则隐藏横幅。
- **[Risk] 首次进入短暂 false 闪一下** → 若明显，可在 `initialLoadDone` 后再显示断开条（可选，tasks 中标注手工确认）。

## Migration Plan

- 纯客户端 UI；无数据迁移。回滚即移除横幅 widget 与插入点。

## Open Questions

- 是否需要在「正在重连」时显示「连接中…」而非「连接中断」？（建议 v1 保持单文案，重连时按钮 loading。）
