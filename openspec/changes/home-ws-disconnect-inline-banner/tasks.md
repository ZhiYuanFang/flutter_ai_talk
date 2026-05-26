## 1. 横幅组件

- [x] 1.1 新增 `HomeHistoryWsStatusBanner`：文案「连接中断，请点击重连」、`cloud_off` 图标、`onReconnect` 回调、错误色底条
- [x] 1.2 可选 `AnimatedSize` / 紧凑高度（约 40–44dp），避免显隐时布局跳动过大

## 2. 主页集成

- [x] 2.1 `HomeScreen`：在 `Expanded` 历史列与 `_buildInputModuleTopShadow` 之间插入横幅
- [x] 2.2 展示条件：`!_wsReady` 且已登录且已绑定 deviceNo（与 design 一致）
- [x] 2.3 点击横幅调用 `_reconnectHistoryWs()`；重连中可选本地 loading 防连点

## 3. 文案与次要入口

- [x] 3.1 移除 AppBar 历史 WS 云图标；重连入口仅保留底部横幅
- [x] 3.2 更新 `_ensureHistoryWsForSend` toast（若仍提「右上角」则改为「点击下方重连」或等价表述）

## 4. 验证

- [x] 4.1 手工：断网或杀 WS 后横幅出现；点击重连后恢复隐藏
- [x] 4.2 手工：未登录/未绑定不显示横幅；历史列表仍可滚动
- [x] 4.3 `dart analyze`  touched 文件无新增告警；不新增 `test/` 文件
