## 1. 数据层扩展

- [x] 1.1 在 `AuthRepository` 抽象类中新增 `Future<void> deactivateAccount();` 接口定义。
- [x] 1.2 在 `RemoteAuthRepository` 中实现该接口，获取 `authorizedApiClientProvider` 实例。
- [x] 1.3 编写 POST 请求逻辑，指向 `/device/app/api/user/deactivate`，不携带 Body。

## 2. UI 强验证对话框实现

- [x] 2.1 扩展通用的对话框工具或在 `SettingsScreen` 本地创建一个支持 `TextField` 验证的 `showGlassTextConfirmDialog`。
- [x] 2.2 实现输入监听，对比输入文本是否为“确定注销”。
- [x] 2.3 在验证未通过时，禁用确认按钮。

## 3. 业务流程集成

- [x] 3.1 重构 `SettingsScreen` 内的 `_confirmDeregister` 流程。
- [x] 3.2 串联逻辑：第一步风险提示 -> 第二步文本确认 -> 第三步调用 `deactivateAccount()`。
- [x] 3.3 异常处理机制：若 API 捕获到异常，使用 Toast 提示用户，并停止后续清理逻辑（必须确保不进入 `session.signOut()`）。
- [x] 3.4 成功逻辑：API 成功后，按顺序调用本地所有的清除逻辑（Session/Device/Channel），并执行导航跳转。
