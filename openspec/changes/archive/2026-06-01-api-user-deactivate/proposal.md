## Why

为了满足合规性要求（如 App Store 隐私条款）并保障用户对个人数据的控制权，需要提供功能让用户能主动从 App 端发起账号销毁申请。目前的注销仅清理了本地缓存，并未触达后端销毁数据的逻辑。

## What Changes

- **新增注销接口集成**：集成后端接口 `/device/app/api/user/deactivate`。
- **强化注销确认流程**：在设置界面“注销账户”流程中，新增强制性的文本输入确认环节，要求用户手动输入“确定注销”方可点击确认。
- **状态同步处理**：调整注销逻辑。若服务端销毁接口失败，则不执行本地会话清除，保持当前登录状态并提示用户，避免因接口失败导致的数据僵尸状态。
- **代码重构**：在 `AuthRepository` 抽象类和 `RemoteAuthRepository` 实现中增加 `deactivateAccount()` 方法。

## Capabilities

### New Capabilities
- `user-deactivation`: 处理用户账号的永久销毁流程，包括强确认 UI 交互、服务端状态解约以及本地清理逻辑。

### Modified Capabilities
- 无

## Impact

- **API**: 新增对 `/device/app/api/user/deactivate` 的 POST 调用。
- **Repository**: `AuthRepository` 接口及其实现类将增加方法。
- **UI**: `SettingsScreen` 中的 `_confirmDeregister` 逻辑将变得更复杂，引入输入对话框。
- **Session Manager**: 该操作最终会触发 `SessionController` 的状态清理（前提是接口成功）。
