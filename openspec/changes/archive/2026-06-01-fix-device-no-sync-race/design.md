## Context

当前代码中，`DeviceNoNotifier.setLocal` 在更新磁盘的同时异步修改内存状态，但在 `HomeScreen` 中存在监听状态变化并反向调用 `refresh()` 的逻辑。这构成了一个时序陷阱：`setLocal` 发起异步写入 -> 内存状态更新 -> 触发 `HomeScreen` 监听器 -> 触发 `refresh()` 读取磁盘 -> 磁盘写入尚未完成，读到 `null` -> 内存状态被回滚为 `null` -> 下游服务（如 WebSocket）检测到 `null` 而断开。

## Goals / Non-Goals

**Goals:**
- 实现设备号持久化与内存变更的严格顺序化（先写盘，后更新状态）。
- 消除 `HomeScreen` 中的冗余刷新调用，防止人为引发的状态反转。
- 确保 `RemoteFeedRepository` 的重连触发总是能获取到由 `setLocal` 刚确立的数据。

**Non-Goals:**
- 不涉及 `SharedPreferences` 本身的错误处理机制重构。
- 不修改现存的登录/注销基本 API 逻辑。

## Decisions

### 1. 原子化 Notifier 写入 (Wait-Before-Emit)
修改 `DeviceNoNotifier.setLocal` 的实现顺序。
- **理由**：Riverpod 的状态监听是同步触发的。如果内存先变，磁盘后变，那么监听者发起的任何磁盘读取都会产生脏读。
- **细节**：
  ```dart
  Future<void> setLocal(String deviceNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeviceNoCache, deviceNo); // 先确保落盘
    state = AsyncValue.data(deviceNo); // 后通知全局
  }
  ```

### 2. 精简 HomeScreen 自动刷新逻辑
移除 `HomeScreen` 中 `build` 方法内对 `sessionProvider` 的 `listen` 回调中调度的 `ref.read(deviceNoNotifierProvider.notifier).refresh()`。
- **理由**：
  1. `initState` 已包含了初始加载逻辑。
  2. 登录成功的 Repository 逻辑（如 `signInWithWeChat`）内部会主动调用 `setLocal`，状态已经是最新的。
  3. 这里的 `refresh` 常在登录返回瞬间触发，与 `setLocal` 的写入过程极易形成竞争。

### 3. RemoteFeedRepository 读取闭包优化
保持 `_deviceNoGetter` 闭包形式，但在重连逻辑 `reconnectHistoryWebSocket` 中增加对状态稳定性的微量容错（或确认读取时不处于 Loading 态）。

## Risks / Trade-offs

- **[Risk] 磁盘写入延迟感**：虽然 `await` 增加了毫秒级延迟，但相比于解决「连接死锁」问题，该开销完全可接受。
- **[Risk] 逻辑流变动**：移除 `HomeScreen` 刷新的潜在风险是某些未预见的路径可能不再自动刷新。
  - **Mitigation**：经排查，目前主要路径（登录、绑定、启动）都有明确的 `setLocal` 或 `initState` 覆盖，移除是安全的。
