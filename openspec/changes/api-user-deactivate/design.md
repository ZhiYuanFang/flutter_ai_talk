## Context

当前 App 的注销功能仅仅是本地 `signOut`（登出）的同义词。为了符合合规性并真正删除用户在后端的数据，我们需要在原有的“登出”逻辑之上，增加一层对 `/device/app/api/user/deactivate` 接口的同步调用。

## Goals / Non-Goals

**Goals:**
- 实现端到端的账号销毁流程。
- 增加注销操作的门槛，引入文本输入验证。
- 确保服务端成功后再清理本地，保持强一致性。

**Non-Goals:**
- 本次不涉及删除本地离线存储（如有大规模数据库，由后端处理数据一致性）。
- 不涉及注销后的冷却期逻辑（完全由服务端控制）。

## Decisions

### 1. Repository 层 API 扩展
在 `AuthRepository` 中增加 `deactivateAccount()`。
- **理由**：注销（Deactivate）与 登出（SignOut）语义不同，应有独立的方法。
- **细节**：在 `RemoteAuthRepository` 中，通过 `_ref.read(authorizedApiClientProvider)` 获取带 Token 的客户端，发送 POST 请求。

### 2. UI 强验证交互
在 `SettingsScreen` 中，改造 `_confirmDeregister` 方法。
- **理由**：普通确认框容易产生由于“肌肉记忆”导致的误点击。
- **细节**：使用自定义的 `showGlassConfirmDialog`（或其变体），在弹窗中嵌入 `TextField`。
  - 使用 `ValueNotifier<bool>` 或直接在弹窗 State 中控制“确认”按钮的 `onPressed` 是否为 null。
  - 验证字符串：`确定注销`。

### 3. 操作顺序：先远程，后本地
调整调用链逻辑：
```dart
try {
  await authRepo.deactivateAccount(); // 发送 API 请求
  // 仅在上一行成功后执行
  await session.signOut(); 
  await deviceNo.clearLocal();
  context.go('/home');
} catch (e) {
  // 提示错误，页面不跳转，Session 不清除
  showErrorToast(e.toString());
}
```
- **理由**：满足用户“注销失败则不退出”的需求。

## Risks / Trade-offs

- **[Risk] 网络不连通导致死循环**：用户想销毁账号但由于网络问题一直无法退出。
  - **Mitigation**：在 UI 上提供明确的错误提示。如果用户仅仅想退出当前登录而不销毁账号，可以引导其使用“切换账号”功能（该功能不调用销毁接口，仅调用原有 signOut 逻辑）。
- **[Risk] Token 刷新失败**：
  - **Mitigation**：如果 Access Token 过期且刷新失败，`AuthorizedApiClient` 会自动触发 401 流程（即登出）。这种情况虽然没有成功调用销毁接口，但由于本地状态已清空，用户已被迫注销。这是一个可接受的 Trade-off。
