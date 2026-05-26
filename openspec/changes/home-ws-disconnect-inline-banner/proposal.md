## Why

历史记录依赖 WebSocket 实时同步；断开或未连接时，用户目前只能从 AppBar 右上角小图标（`cloud_off`）察觉状态，入口隐蔽、文案缺失，容易误以为「发了但没显示」或不知道要点哪里重连。需要在历史列表与底部输入区之间增加醒目的内联提示，降低认知成本。

## What Changes

- 当历史 WebSocket **未就绪**（未连接或已断开）时，在**历史记录模块与输入模块之间**展示一条可点击横幅：`连接中断，请点击重连`。
- 点击横幅调用与 AppBar「重连历史」相同的 `reconnectHistoryWebSocket` 逻辑。
- WebSocket **已连接**时横幅隐藏；连接恢复后自动收起。
- AppBar 右上角可保留云图标作为次要状态指示，或简化为仅连接态/重连入口（实现阶段在 design 中定夺，不强制移除图标）。

## Capabilities

### New Capabilities

- `home-history-ws-status-banner`：主页历史 WS 断开时的内联提示条、展示条件、文案、点击重连与布局位置。

### Modified Capabilities

- （无根目录 `openspec/specs/` 基线；与已归档 `feed-history-ws-after-chat`、`pangbao-api-liantiao` 等在实现层衔接，本变更以新增 capability 描述可见行为。）

## Impact

- `app/lib/ui/home_screen.dart`：在历史 `Expanded` 列与 `_buildInputModuleTopShadow` / 底部输入 panel 之间插入横幅 widget。
- 可选抽取 `app/lib/ui/home_history_ws_status_banner.dart` 小部件，复用 `_wsReady` 与 `_reconnectHistoryWs`。
- 不影响 WS 协议、鉴权与 `FeedRepository` 接口语义。
