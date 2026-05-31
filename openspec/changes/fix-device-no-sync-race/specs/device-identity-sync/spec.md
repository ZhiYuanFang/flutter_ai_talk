## ADDED Requirements

### Requirement: Device-Identity Atomic Persistence
系统在修改 `deviceNo` 时，其内存状态的变更与持久化存储（SharedPreferences）的写入 **MUST** 保持原子性（即内存状态更新必须发生在成功持久化之后）。

#### Scenario: User binds a new baby ID
- **WHEN** 用户触发 `setLocal(deviceNo)` 操作
- **THEN** 系统先完成磁盘写入，待 Future 返回后再更新 `state` 广播给监听者

### Requirement: Device-Identity Consistent Broadcast
系统针对 `deviceNo` 的变化广播 **SHALL** 确保下游监听者（如 WebSocket 模块）获取到的永远是持久化后的有效标识。

#### Scenario: Listening to deviceNo change in HomeScreen
- **WHEN** `deviceNoNotifierProvider` 的 `state` 发生变更
- **THEN** 下游服务直接读取到的 `AsyncData` 值应当与磁盘内的最新数据严格对应

### Requirement: Reliable Identity Validation for Services
核心服务（如 WebSocket）在自动重连或建立链路时，**MUST** 确保读取到的设备号是最终一致的，不得因 Provider 的临时 Loading 状态导致回滚为 `null`。

#### Scenario: WebSocket reconnect after binding
- **WHEN** 收到 `deviceNo` 变更通知并触发 `_openSocket`
- **THEN** 内部 `_deviceNoGetter` 获取到的必须是刚刚成功绑定的 ID 值，而非由于过度刷新的 `null`
