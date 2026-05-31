## Why

目前在「绑定宝宝」流程中，`DeviceNoNotifier` 的异步写入与 `HomeScreen` 的主动刷新逻辑之间存在竞争关系，导致 `RemoteFeedRepository` 在建立 WebSocket 连接时读取到过时的 `null` 状态，从而由于安全校验失败而无法连接，即使手动重连也会因状态锁死而持续报“未绑定设备号”错误。

## What Changes

- **原子化状态更新**：`DeviceNoNotifier.setLocal` 必须等待磁盘持久化成功后再触内存状态变更，确保所有监听者拿到的都是「已落地」的数据。
- **移除冗余刷新逻辑**：清理 `HomeScreen` 中针对 `deviceNo` 变化的积极但非必要的 `refresh` 调用，消除人为构造的「状态回滚」窗口。
- **仓库层获取优化**：优化 `RemoteFeedRepository` 中 `deviceNoGetter` 的读取逻辑，确保其能可靠地追踪异步 Provider 的数据流，而非依赖可能失效的即时快照。

## Capabilities

### New Capabilities
- `device-identity-sync`: 规范设备标识（deviceNo）在内存、持久化存储以及下游服务消费（如 WebSocket、API 请求）之间的同步一致性协议。

### Modified Capabilities
- 无

## Impact

- **Provider**: `DeviceNoNotifier` 将调整 `setLocal` 为强顺序执行。
- **Repository**: `RemoteFeedRepository` 的 WS 建链校验逻辑将更加健壮。
- **UI**: `HomeScreen` 将简化状态监听的回调逻辑，降低复杂度。
