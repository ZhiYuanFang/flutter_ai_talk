# Tasks - Suppress WS Banner when Unbound

## 1. UI 逻辑调整

- [x] 1.1 修改 `app/lib/ui/home_screen.dart` 中的 `showWsDisconnectBanner` 计算逻辑，引入 `needsDeviceBind` 进行过滤。

## 2. 验证

- [ ] 2.1 在模拟器或真机上验证：在尚未绑定宝宝信息时，即使网络断开，主页上方不再显示 WebSocket 断连 Banner。
- [ ] 2.2 验证：在已绑定宝宝信息后，网络断开时仍然可以正常显示 WebSocket 断连 Banner。
