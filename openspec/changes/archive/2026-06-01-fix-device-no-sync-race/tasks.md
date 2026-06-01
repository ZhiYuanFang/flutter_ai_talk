## 1. Provider 层逻辑加固

- [x] 1.1 修改 `app/lib/providers/device_no_notifier.dart` 中的 `setLocal` 方法，将 `state` 更新移至磁盘写入之后。
- [x] 1.2 确认 `DeviceNoNotifier` 中的 `refresh` 方法不会在读取期间通过 `Loading` 状态非必要地中断当前有效 `deviceNo` 的暴露。

## 2. UI 逻辑精简

- [x] 2.1 修改 `app/lib/ui/home_screen.dart`，移除 `build` 方法中 `sessionProvider` 监听器内对 `deviceNoNotifierProvider.notifier.refresh()` 的冗余调用。
- [x] 2.2 确保 `ref.listen<AsyncValue<String?>>(deviceNoNotifierProvider, ...)` 中的 `unawaited(_refreshEventCatalogIfReady())` 等后续业务逻辑依然正常触发。

## 3. 验证与测试

- [ ] 3.1 手动运行模拟环境，执行宝宝信息绑定流程，确保成功后下方 WS 横幅自动消失且不报“未绑定”错误。
- [ ] 3.2 验证切换账号后，WS 连接依然能够根据新账号的磁盘缓存正确建立。
